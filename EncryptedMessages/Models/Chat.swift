//
//  Chat.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/27/25.
//

import Foundation
import SwiftData

@Model
final class Chat: Identifiable {
    @Attribute(.unique) var id: String
    var writingKey: String
    var readingKey: String?
    var timestamp: Date
    
    init(id: String, writingKey: String, readingKey: String? = nil, timestamp: Date) {
        self.id = id
        self.writingKey = writingKey
        self.readingKey = readingKey
        self.timestamp = timestamp
    }
}
