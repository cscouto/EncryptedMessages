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

    @StateObject private var vm = ChatListViewModel()

    var body: some View {
        NavigationSplitView {
            List(selection: $vm.selectedChatId) {
                ForEach(chats, id: \.id) { chat in
                    Text(chat.id)
                        .tag(chat.id)
                }
                .onDelete { offsets in
                    withAnimation {
                        vm.deleteChats(offsets: offsets, chats: chats, modelContext: modelContext)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItemGroup {
                    Button {
                        withAnimation { vm.addChat(modelContext: modelContext) }
                    } label: {
                        Label("Add Chat", systemImage: "plus")
                    }

                    Button {
                        vm.isShowingScanner = true
                    } label: {
                        Label("Scan QR", systemImage: "qrcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $vm.isShowingScanner) {
                QRScannerView { scannedString in
                    withAnimation {
                        vm.handleScannedQRCode(scannedString, chats: chats, modelContext: modelContext)
                    }
                }
            }
        } detail: {
            if let selectedId = vm.selectedChatId,
               let chat = chats.first(where: { $0.id == selectedId }) {
                ChatDetailView(chat: chat)
            } else {
                Text("Select a chat")
            }
        }
    }
}
