//
//  ChatListView.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/27/25.
//

import SwiftUI
import SwiftData

struct ChatListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var chats: [Chat]
    @State private var selectedChatId: String?
    @State private var isShowingScanner = false
    @State private var isProcessingScan = false
    
    var body: some View {
        NavigationSplitView {
            List(chats, selection: $selectedChatId) { chat in
                ForEach(chats, id: \.id) { chat in
                    Text(chat.id)
                }
                .onDelete(perform: deleteChats)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItemGroup {
                    Button(action: addChat) {
                        Label("Add Chat", systemImage: "plus")
                    }
                    Button(action: {
                        isShowingScanner = true
                    }) {
                        Label("Scan QR", systemImage: "qrcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                QRScannerView { scannedString in
                    handleScannedQRCode(scannedString)
                }
            }
        } detail: {
            if let selectedId = selectedChatId,
               let chat = chats.first(where: { $0.id == selectedId }) {
                ChatDetailView(chat: chat)
            } else {
                Text("Select a chat")
            }
        }
    }
    
    private func addChat() {
        withAnimation {
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
                //handle error
            }
            
        }
    }
    
    private func deleteChats(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let chat = chats[index]
                
                //delete key from keychain for deleted user
                CryptoHelper.deleteKey(for: chat.id)
                
                modelContext.delete(chat)
            }
        }
    }
    
    private func handleScannedQRCode(_ scannedString: String) {
        guard !isProcessingScan else { return }  // ignore duplicates
        isProcessingScan = true

        defer { isProcessingScan = false } // reset after handling

        guard let data = scannedString.data(using: .utf8),
              let payload = try? JSONDecoder().decode(ChatQRPayload.self, from: data) else {
            print("Invalid QR code")
            return
        }

        withAnimation {
            if let existingChat = chats.first(where: { $0.id == payload.chatId }) {
                // Update existing chat
                existingChat.relKey = payload.chatRelKey
                modelContext.insert(existingChat)
            } else {
                // Create new chat
                let newChat = Chat(
                    id: payload.chatId,
                    name: "New Chat",
                    relKey: payload.chatRelKey,
                    timestamp: Date()
                )
                modelContext.insert(newChat)
            }
        }
    }
}

