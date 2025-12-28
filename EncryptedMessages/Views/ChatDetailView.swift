//
//  UserDetailView.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/27/25.
//

import SwiftUI

struct ChatDetailView: View {
    @StateObject private var vm: ChatDetailViewModel
    
    init(chat: Chat) {
        _vm = StateObject(wrappedValue: ChatDetailViewModel(chat: chat))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {                
                headerSection
                qrSection
                
                //only display segmentedcontrol if they have the user key
                if let _ = vm.chat.theirPublicKey {
                    Picker("Mode", selection: $vm.selectedMode) {
                        ForEach(Mode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical)
                    
                    if vm.selectedMode == .encrypt {
                        encryptSection
                    } else {
                        decryptSection
                    }
                }
                
            }
            .padding()
        }
        .navigationTitle("Secure Chat")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $vm.isShowingShareSheet) {
            ActivityViewController(activityItems: [vm.encryptedMessage])
        }
    }
}

private extension ChatDetailView {
    var headerSection: some View {
        VStack(spacing: 4) {
            Text("Created")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(vm.chat.timestamp.formatted(date: .abbreviated, time: .shortened))
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
                    chatId: vm.chat.id,
                    pubKey: vm.chat.myPublicKey
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
            
            TextEditor(text: $vm.messageToEncrypt)
                .frame(minHeight: 120)
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                vm.encryptAndShare()
            } label: {
                Label("Encrypt & Share", systemImage: "lock.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!vm.canEncrypt)
            
            if !vm.encryptedMessage.isEmpty {
                encryptedOutput
            }
        }
    }
    
    var encryptedOutput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Encrypted message")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(vm.encryptedMessage)
                .font(.system(.footnote, design: .monospaced))
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contextMenu {
                    Button("Copy") {
                        UIPasteboard.general.string = vm.encryptedMessage
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
            
            TextEditor(text: $vm.messageToDecrypt)
                .frame(minHeight: 120)
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                vm.decryptMessage()
            } label: {
                Label("Decrypt Message", systemImage: "lock.open.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!vm.canDecrypt)
            
            if !vm.decryptedMessage.isEmpty {
                decryptedOutput
            }
        }
    }
    
    var decryptedOutput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Decrypted message")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(vm.decryptedMessage)
                .padding(12)
                .background(Color(uiColor: .tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
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
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
