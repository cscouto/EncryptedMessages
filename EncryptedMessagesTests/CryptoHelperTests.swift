//
//  CryptoHelperTests.swift
//  EncryptedMessagesTests
//
//  Created by Tiago Do Couto on 12/28/25.
//

import XCTest
@testable import EncryptedMessages

final class CryptoHelperTests: XCTestCase {
    private var idsToCleanup: [String] = []

    override func tearDown() {
        idsToCleanup.forEach { CryptoHelper.deleteKey(for: $0) }
        idsToCleanup.removeAll()
        super.tearDown()
    }

    func testEncryptDecryptRoundTrip_AtoB() throws {
        let aId = UUID().uuidString
        let bId = UUID().uuidString
        idsToCleanup.append(contentsOf: [aId, bId])

        let aPub = try CryptoHelper.generateKey(for: aId)
        let bPub = try CryptoHelper.generateKey(for: bId)

        let plaintext = "hello"
        let ciphertext = try CryptoHelper.encrypt(message: plaintext, using: bPub, myKeyId: aId)
        let decrypted = try CryptoHelper.decrypt(message: ciphertext, using: aPub, myKeyId: bId)

        XCTAssertEqual(decrypted, plaintext)
    }

    func testDecryptFailsWithWrongRecipientPrivateKey() throws {
        let aId = UUID().uuidString
        let bId = UUID().uuidString
        let cId = UUID().uuidString
        idsToCleanup.append(contentsOf: [aId, bId, cId])

        let aPub = try CryptoHelper.generateKey(for: aId)
        let bPub = try CryptoHelper.generateKey(for: bId)
        _ = try CryptoHelper.generateKey(for: cId)

        let ciphertext = try CryptoHelper.encrypt(message: "secret", using: bPub, myKeyId: aId)

        XCTAssertThrowsError(try CryptoHelper.decrypt(message: ciphertext, using: aPub, myKeyId: cId))
    }

    func testDeleteKeyMakesFutureLoadFail() throws {
        let aId = UUID().uuidString
        let bId = UUID().uuidString
        idsToCleanup.append(contentsOf: [aId, bId])

        _ = try CryptoHelper.generateKey(for: aId)
        let bPub = try CryptoHelper.generateKey(for: bId)

        CryptoHelper.deleteKey(for: aId)

        XCTAssertThrowsError(try CryptoHelper.encrypt(message: "x", using: bPub, myKeyId: aId))
    }
}
