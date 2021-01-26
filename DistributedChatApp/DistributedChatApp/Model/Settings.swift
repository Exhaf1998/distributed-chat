//
//  Settings.swift
//  DistributedChatApp
//
//  Created by Fredrik on 1/23/21.
//

import Combine

class Settings: ObservableObject {
    @Published(persistingTo: "Settings/presentation.json") var presentation = Presentation()
    @Published(persistingTo: "Settings/bluetooth.json") var bluetooth = Bluetooth()
    
    struct Presentation: Codable {
        var messageHistoryStyle: MessageHistoryStyle = .bubbles
        var showChannelPreviews: Bool = true
    }
    
    struct Bluetooth: Codable {
        var advertisingEnabled: Bool = true
        var scanningEnabled: Bool = true
    }
}
