//
//  ChatDetailViewModel.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/28/25.
//

import Foundation
import SwiftUI

@MainActor
final class ChatDetailViewModel: ObservableObject {
    @Published var messageToEncrypt: String = ""
    @Published var encryptedMessage: String = ""
    
    @Published var messageToDecrypt: String = ""
    @Published var decryptedMessage: String = ""
    
    @Published var isShowingShareSheet: Bool = false
    @Published var selectedMode: Mode = .encrypt
    
    let chat: Chat
    
    init(chat: Chat) {
        self.chat = chat
    }
    
    var canEncrypt: Bool {
        !messageToEncrypt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canDecrypt: Bool {
        !messageToDecrypt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func encryptAndShare() {
        guard let theirPublicKey = chat.theirPublicKey, !theirPublicKey.isEmpty else {
            encryptedMessage = "Missing recipient public key. Scan their QR first."
            return
        }
        
        do {
            encryptedMessage = try CryptoHelper.encrypt(
                message: messageToEncrypt,
                using: theirPublicKey,
                myKeyId: chat.id
            )
            UIPasteboard.general.string = encryptedMessage
            isShowingShareSheet = true
        } catch {
            encryptedMessage = "Encryption failed: \(error.localizedDescription)"
        }
    }
    
    func decryptMessage() {
        guard let theirPublicKey = chat.theirPublicKey, !theirPublicKey.isEmpty else {
            decryptedMessage = "Missing sender public key. Scan their QR first."
            return
        }
        
        do {
            decryptedMessage = try CryptoHelper.decrypt(
                message: messageToDecrypt,
                using: theirPublicKey,
                myKeyId: chat.id
            )
        } catch {
            decryptedMessage = "Decryption failed: \(error.localizedDescription)"
        }
    }
}

