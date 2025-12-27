//
//  ContentView.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/27/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var selectedUserId: String?
    
    var body: some View {
        NavigationSplitView {
            List(users, selection: $selectedUserId) { user in
                ForEach(users, id: \.id) { user in
                    Text(user.id)
                }
                .onDelete(perform: deleteUsers)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addUser) {
                        Label("Add User", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selectedId = selectedUserId,
               let user = users.first(where: { $0.id == selectedId }) {
                UserDetailView(user: user)
            } else {
                Text("Select a user")
            }
        }
    }
    
    private func addUser() {
        withAnimation {
            let userId = UUID().uuidString
            do {
                let relKey = try CryptoHelper.generateKey(for: userId)
                let newUser = User(
                    id: userId,
                    userPublicKey: nil,
                    relKey: relKey,
                    timestamp: Date()
                )
                modelContext.insert(newUser)
            } catch {
                //handle error
            }
            
        }
    }
    
    private func deleteUsers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let user = users[index]
                
                //delete key from keychain for deleted user
                CryptoHelper.deleteKey(for: user.id)
                
                modelContext.delete(user)
            }
        }
    }
}
