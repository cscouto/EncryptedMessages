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
    static func generateKey(for id: String) throws -> String  {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        try savePrivateKey(privateKey, id: id)
        return privateKey.publicKey.rawRepresentation.base64EncodedString()
    }
    
    // store private key on keychain
    private static func savePrivateKey(_ key: Curve25519.KeyAgreement.PrivateKey, id: String) throws {
        let data = key.rawRepresentation
        let tag = Data(id.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainError", code: Int(status))
        }
    }

    // load private key for relationship
    private static func loadPrivateKey(for id: String) throws -> Curve25519.KeyAgreement.PrivateKey {
        let tag = Data(id.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            throw NSError(domain: "KeychainError", code: Int(status))
        }

        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
    }

    // delete key from keychain
    static func deleteKey(for id: String) {
        let tag = Data(id.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Failed to delete key from Keychain: \(status)")
        }
    }
    
    //encrypt message for recipient
    static func encrypt(message: String, using recipientPublicKey: String, myKeyId: String) throws -> String {
        //load your private key
        let myPrivateKey = try loadPrivateKey(for: myKeyId)

        //decode recipient's public key
        guard let pubKeyData = Data(base64Encoded: recipientPublicKey) else {
            throw NSError(domain: "CryptoHelper", code: 1)
        }

        let recipientKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: pubKeyData)

        //derive shared secret
        let sharedSecret = try myPrivateKey.sharedSecretFromKeyAgreement(with: recipientKey)

        //derive symmetric key
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )

        //encrypt
        let sealedBox = try AES.GCM.seal(Data(message.utf8), using: symmetricKey)
        return sealedBox.combined!.base64EncodedString()
    }
    
    //decrypt message from sender
    static func decrypt(message: String, using senderPublicKey: String, myKeyId: String) throws -> String {
        //load your private key
        let myPrivateKey = try loadPrivateKey(for: myKeyId)

        //decode sender public key
        guard let pubKeyData = Data(base64Encoded: senderPublicKey),
              let encryptedData = Data(base64Encoded: message)
        else {
            throw NSError(domain: "CryptoHelper", code: 2)
        }

        let senderKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: pubKeyData)

        //derive shared secret
        let sharedSecret = try myPrivateKey.sharedSecretFromKeyAgreement(with: senderKey)

        //derive symmetric key
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )

        //decrypt
        let box = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(box, using: symmetricKey)

        return String(decoding: decryptedData, as: UTF8.self)
    }
    
    //code to generate encrypted messages without needding the recipients key
//    //encrypt message
//    static func encrypt(message: String, using relKeyString: String) throws -> String {
//        guard let keyData = Data(base64Encoded: relKeyString) else {
//            throw NSError(domain: "CryptoHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid key"])
//        }
//        let symmetricKey = SymmetricKey(data: keyData)
//        let sealedBox = try AES.GCM.seal(Data(message.utf8), using: symmetricKey)
//        return sealedBox.combined!.base64EncodedString()
//    }
//    
//    //decrypt message
//    static func decrypt(message: String, using relKeyString: String) throws -> String {
//        guard let keyData = Data(base64Encoded: relKeyString) else {
//            throw NSError(domain: "CryptoHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid key"])
//        }
//        let symmetricKey = SymmetricKey(data: keyData)
//        guard let encryptedData = Data(base64Encoded: message) else {
//            throw NSError(domain: "CryptoHelper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid encrypted message"])
//        }
//        let box = try AES.GCM.SealedBox(combined: encryptedData)
//        let decrypted = try AES.GCM.open(box, using: symmetricKey)
//        return String(data: decrypted, encoding: .utf8) ?? ""
//    }
}
