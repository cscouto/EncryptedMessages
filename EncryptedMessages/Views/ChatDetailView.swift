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
    @State private var selectedMode: Mode = .encrypt
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("writing: \(chat.myPublicKey)\nreading: \(chat.theirPublicKey ?? "")")
                headerSection
                qrSection
                Picker("Mode", selection: $selectedMode) {
                    ForEach(Mode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical)
                
                if selectedMode == .encrypt {
                    encryptSection
                } else {
                    decryptSection
                }
                
            }
            .padding()
        }
        .navigationTitle("Secure Chat")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingShareSheet) {
            ActivityViewController(activityItems: [encryptedMessage])
        }
    }
}

private extension ChatDetailView {
    var headerSection: some View {
        VStack(spacing: 4) {
            Text("Created")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(chat.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.footnote)
        }
    }
    
    var qrSection: some View {
        VStack(spacing: 12) {
            Text("Invite someone")
                .font(.headline)
            
            Text("Scan this QR code in person to exchange keys securely.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            QRCodeView(
                payload: QRPayload(
                    chatId: chat.id,
                    pubKey: chat.myPublicKey
                )
            )
            .frame(width: 200, height: 200)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    var encryptSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Encrypt & Share",
                subtitle: "Write a message and share it securely."
            )
            
            TextEditor(text: $messageToEncrypt)
                .frame(minHeight: 120)
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                encryptAndShare()
            } label: {
                Label("Encrypt & Share", systemImage: "lock.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(messageToEncrypt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            if !encryptedMessage.isEmpty {
                encryptedOutput
            }
        }
    }
    
    var encryptedOutput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Encrypted message")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(encryptedMessage)
                .font(.system(.footnote, design: .monospaced))
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contextMenu {
                    Button("Copy") {
                        UIPasteboard.general.string = encryptedMessage
                    }
                }
        }
    }
    
    var decryptSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Decrypt a message",
                subtitle: "Paste an encrypted message you received."
            )
            
            TextEditor(text: $messageToDecrypt)
                .frame(minHeight: 120)
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                decryptMessage()
            } label: {
                Label("Decrypt Message", systemImage: "lock.open.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(messageToDecrypt.isEmpty)
            
            if !decryptedMessage.isEmpty {
                decryptedOutput
            }
        }
    }
    
    var decryptedOutput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Decrypted message")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(decryptedMessage)
                .padding(12)
                .background(Color(uiColor: .tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    func encryptAndShare() {
        guard let readingKey = chat.theirPublicKey else {
            encryptedMessage = "You don’t have permission to decrypt this message."
            return
        }
        
        do {
            encryptedMessage = try CryptoHelper.encrypt(
                message: messageToEncrypt,
                using: readingKey,
                myKeyId: chat.id
            )
            UIPasteboard.general.string = encryptedMessage
            isShowingShareSheet = true
        } catch {
            encryptedMessage = "Encryption failed."
        }
    }
    
    func decryptMessage() {
        guard let readingKey = chat.theirPublicKey else {
            decryptedMessage = "You don’t have permission to decrypt this message."
            return
        }
        
        do {
            decryptedMessage = try CryptoHelper.decrypt(
                message: messageToDecrypt,
                using: readingKey,
                myKeyId: chat.id
            )
        } catch {
            decryptedMessage = "Decryption failed."
        }
    }
}

enum Mode: String, CaseIterable {
    case encrypt = "Encrypt"
    case decrypt = "Decrypt"
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
