//
//  UserDetailView.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/27/25.
//

import SwiftUI

struct ChatDetailView: View {
    var chat: Chat
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Chat ID: \(chat.id)")
                .font(.headline)
            
            Text("Created: \(chat.timestamp.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
            
            //generate qrcode to share public key
            QRCodeView(
                payload: QRPayload(
                    chatId: chat.id,
                    pubKey: chat.writingKey
                )
            )
            .frame(width: 200, height: 200)
        }
        .padding()
    }
}

