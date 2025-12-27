//
//  User.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/27/25.
//

import Foundation
import SwiftData

@Model
final class User: Identifiable {
    @Attribute(.unique) var id: String
    var userPublicKey: String?
    var relKey: String
    var timestamp: Date
    
    init(id: String, userPublicKey: String? = nil, relKey: String, timestamp: Date) {
        self.id = id
        self.userPublicKey = userPublicKey
        self.relKey = relKey
        self.timestamp = timestamp
    }
}
