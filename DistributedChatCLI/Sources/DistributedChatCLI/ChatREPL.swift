import Foundation
import LineNoise
import DistributedChat

fileprivate let globalChannelName = "global"

class ChatREPL {
    private let transport: ChatTransport
    private let controller: ChatController
    private let network: Network = Network()
    
    init(transport: ChatTransport, name: String) {
        self.transport = transport

        controller = ChatController(transport: transport)
        controller.update(name: name)

        controller.onAddChatMessage { [unowned self] msg in
            print("\r[\(displayName(of: msg.channel))] \(msg.author.displayName): \(msg.content)\r")
        }

        controller.onUpdatePresence { [unowned self] presence in
            let hasChanged = network.register(presence: presence)
            if hasChanged {
                print("\r> \(presence.user.displayName) is now \(presence.status.description.lowercased())\r")
            }
        }
    }

    private func displayName(of channel: ChatChannel?) -> String {
        switch channel {
        case .dm(let userId)?:
            return "@\(network.presences[userId]?.user.displayName ?? userId.uuidString)"
        case .room(let name)?:
            return "#\(name)"
        case nil:
            return "#\(globalChannelName)"
        }
    }

    private func parseChannel(from raw: String) -> ChatChannel? {
        let name = String(raw.dropFirst())
        switch raw.first {
        case "@"?:
            return resolveUser(from: name).map { .dm($0) }
        case "#"?:
            return name == globalChannelName ? nil : .room(name)
        default:
            return nil
        }
    }

    private func parseMessage(from raw: String) -> (String, ChatChannel?) {
        let split = raw.split(separator: " ", maxSplits: 1).map(String.init)

        if split.count == 2, let channel = parseChannel(from: raw) {
            return (split[1], channel)
        } else {
            return (raw, nil) // on #global
        }
    }

    private func resolveUser(from raw: String) -> UUID? {
        network.presences.values.map(\.user).first { $0.displayName == raw }?.id
    }

    func run() {
        print("""
            ----------------------------------
            --- DISTRIBUTED CHAT REPL v0.1 ---
            ----------------------------------

            Type anything to send to #global or prefix your message
            with a channel, e.g. #my-channel or @SomeUserName.
            Note that the user has to be online. Enjoy!

            """)

        let ln = LineNoise()

        while let input = try? ln.getLine(prompt: "") {
            ln.addHistory(input)

            let (content, channel) = parseMessage(from: input)
            controller.send(content: content, on: channel)
        }

        print()
    }
}
