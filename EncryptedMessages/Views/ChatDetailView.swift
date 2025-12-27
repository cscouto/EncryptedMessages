//
//  UserDetailView.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/27/25.
//

import SwiftUI

struct ChatDetailView: View {
    var chat: Chat
    
    @State private var messageToEncrypt: String = ""
    @State private var encryptedMessage: String = ""
    
    @State private var messageToDecrypt: String = ""
    @State private var decryptedMessage: String = ""
    
    @State private var isShowingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                
                Text("Created: \(chat.timestamp.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                //generate qrcode to share public key
                QRCodeView(
                    payload: QRPayload(
                        chatId: chat.id,
                        pubKey: chat.writingKey
                    )
                )
                .frame(width: 200, height: 200)
                
                Divider()
                
                Text("Type a message to share:")
                    .font(.subheadline)
                
                TextEditor(text: $messageToEncrypt)
                    .frame(height: 100)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                
                Button(action: {
                    shareEncryptedMessage()
                    isShowingShareSheet = true
                }) {
                    Text("Encrypt & Share")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(messageToEncrypt.isEmpty)
                .sheet(isPresented: $isShowingShareSheet) {
                    ActivityViewController(activityItems: [encryptedMessage])
                }
                
                if !encryptedMessage.isEmpty {
                    Text("Encrypted Message:")
                        .font(.subheadline)
                    Text(encryptedMessage)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .contextMenu {
                            Button("Copy") {
                                UIPasteboard.general.string = encryptedMessage
                            }
                        }
                }
                
                Divider()
                
                Text("Paste encrypted message:")
                    .font(.subheadline)
                
                TextEditor(text: $messageToDecrypt)
                    .frame(height: 100)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                
                Button(action: decryptMessage) {
                    Text("Decrypt Message")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                if !decryptedMessage.isEmpty {
                    Text("Decrypted Message:")
                        .font(.subheadline)
                    Text(decryptedMessage)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(4)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func shareEncryptedMessage() {
        do {
            encryptedMessage = try CryptoHelper.encrypt(message: messageToEncrypt, using: chat.writingKey)
            UIPasteboard.general.string = encryptedMessage
        } catch {
            encryptedMessage = "Error encrypting message: \(error)"
        }
    }
    
    private func decryptMessage() {
        guard let readingKey = chat.readingKey else {
            decryptedMessage = "You don't have permission to decrypt this message."
            return
        }
        
        do {
            decryptedMessage = try CryptoHelper.decrypt(message: messageToDecrypt, using: readingKey)
        } catch {
            decryptedMessage = "Error decrypting message: \(error)"
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
