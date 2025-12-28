//
//  ChatListViewModel.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/28/25.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class ChatListViewModel: ObservableObject {
    @Published var selectedChatId: String?
    @Published var isShowingScanner = false
    @Published var isProcessingScan = false

    func addChat(modelContext: ModelContext) {
        let chatId = UUID().uuidString
        do {
            let pubKey = try CryptoHelper.generateKey(for: chatId)
            let newChat = Chat(
                id: chatId,
                writingKey: pubKey,
                readingKey: nil,
                timestamp: Date()
            )
            modelContext.insert(newChat)
        } catch {
            // handle error if you want
        }
    }

    func deleteChats(offsets: IndexSet, chats: [Chat], modelContext: ModelContext) {
        for index in offsets {
            let chat = chats[index]
            CryptoHelper.deleteKey(for: chat.id)
            modelContext.delete(chat)
        }
    }

    func handleScannedQRCode(_ scannedString: String, chats: [Chat], modelContext: ModelContext) {
        guard !isProcessingScan else { return }
        isProcessingScan = true
        defer { isProcessingScan = false }

        guard let data = scannedString.data(using: .utf8),
              let payload = try? JSONDecoder().decode(QRPayload.self, from: data) else {
            print("Invalid QR code")
            return
        }

        if let existingChat = chats.first(where: { $0.id == payload.chatId }) {
            existingChat.theirPublicKey = payload.pubKey
        } else {
            do {
                let pubKey = try CryptoHelper.generateKey(for: payload.chatId)
                let newChat = Chat(
                    id: payload.chatId,
                    writingKey: pubKey,
                    readingKey: payload.pubKey,
                    timestamp: Date()
                )
                modelContext.insert(newChat)
            } catch {
                // handle error if you want
            }
        }
    }
}

