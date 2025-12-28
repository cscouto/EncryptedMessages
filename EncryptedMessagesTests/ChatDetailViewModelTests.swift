//
//  ChatDetailViewModelTests.swift
//  EncryptedMessagesTests
//
//  Created by Tiago Do Couto on 12/28/25.
//

import XCTest
@testable import EncryptedMessages

import XCTest
@testable import EncryptedMessages

@MainActor
final class ChatDetailViewModelTests: XCTestCase {
    private var idsToCleanup: [String] = []

    override func tearDown() {
        idsToCleanup.forEach { CryptoHelper.deleteKey(for: $0) }
        idsToCleanup.removeAll()
        super.tearDown()
    }

    func testCanEncryptAndCanDecryptTrimming() {
        let chat = Chat(id: UUID().uuidString, writingKey: "x", readingKey: "y", timestamp: Date())
        let vm = ChatDetailViewModel(chat: chat)

        vm.messageToEncrypt = "   "
        XCTAssertFalse(vm.canEncrypt)

        vm.messageToEncrypt = "hi"
        XCTAssertTrue(vm.canEncrypt)

        vm.messageToDecrypt = "\n  "
        XCTAssertFalse(vm.canDecrypt)

        vm.messageToDecrypt = "cipher"
        XCTAssertTrue(vm.canDecrypt)
    }

    func testEncryptRequiresTheirPublicKey() {
        let chat = Chat(id: UUID().uuidString, writingKey: "x", readingKey: nil, timestamp: Date())
        let vm = ChatDetailViewModel(chat: chat)

        vm.messageToEncrypt = "hello"
        vm.encryptAndShare()

        XCTAssertTrue(vm.encryptedMessage.contains("Missing recipient public key"))
        XCTAssertFalse(vm.isShowingShareSheet)
    }

    func testEncryptThenDecryptAcrossTwoUsers() throws {
        let aId = UUID().uuidString
        let bId = UUID().uuidString
        idsToCleanup.append(contentsOf: [aId, bId])

        let aPub = try CryptoHelper.generateKey(for: aId)
        let bPub = try CryptoHelper.generateKey(for: bId)

        let chatA = Chat(id: aId, writingKey: aPub, readingKey: bPub, timestamp: Date())
        let vmA = ChatDetailViewModel(chat: chatA)

        vmA.messageToEncrypt = "message from A"
        vmA.encryptAndShare()

        XCTAssertFalse(vmA.encryptedMessage.isEmpty)
        XCTAssertTrue(vmA.isShowingShareSheet)

        let chatB = Chat(id: bId, writingKey: bPub, readingKey: aPub, timestamp: Date())
        let vmB = ChatDetailViewModel(chat: chatB)

        vmB.messageToDecrypt = vmA.encryptedMessage
        vmB.decryptMessage()

        XCTAssertEqual(vmB.decryptedMessage, "message from A")
    }
}
