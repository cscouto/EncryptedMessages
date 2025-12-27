//
//  QRCodePayload.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/27/25.
//

import Foundation

struct QRPayload: Codable {
    let chatId: String
    let pubKey: String
}
