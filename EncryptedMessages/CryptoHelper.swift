//
//  CryptoHelper.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/27/25.
//

import Foundation
import CryptoKit
import Security

final class CryptoHelper {
    //generate private key for relationship
    static func generateKey(for id: String) -> String {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        return privateKey.publicKey.rawRepresentation.base64EncodedString()
    }
    
    //store private key on keychain
    private static func savePrivateKey(_ key: Curve25519.KeyAgreement.PrivateKey, id: String) throws {
        let data = key.rawRepresentation
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: id,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainError", code: Int(status))
        }
    }
    
    //load private key for relationship
    private static func loadPrivateKey(for id: String) throws -> Curve25519.KeyAgreement.PrivateKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: id,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard
            status == errSecSuccess,
            let data = item as? Data
        else {
            throw NSError(domain: "KeychainError", code: Int(status))
        }

        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
    }
}
