//
//  ChatListViewModelTests.swift
//  EncryptedMessagesTests
//
//  Created by Tiago Do Couto on 12/28/25.
//

import XCTest
@testable import EncryptedMessages

import XCTest
import SwiftData
@testable import EncryptedMessages

@MainActor
final class ChatListViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var idsToCleanup: [String] = []

    override func setUp() {
        super.setUp()
        container = try! ModelContainer(
            for: Chat.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    override func tearDown() {
        idsToCleanup.forEach { CryptoHelper.deleteKey(for: $0) }
        idsToCleanup.removeAll()
        container = nil
        context = nil
        super.tearDown()
    }

    private func fetchChats() throws -> [Chat] {
        try context.fetch(FetchDescriptor<Chat>())
    }

    func testAddChatInsertsOneChat() throws {
        let vm = ChatListViewModel()
        vm.addChat(modelContext: context)

        let chats = try fetchChats()
        XCTAssertEqual(chats.count, 1)
        XCTAssertFalse(chats[0].myPublicKey.isEmpty)

        idsToCleanup.append(chats[0].id)
    }

    func testDeleteChatsDeletesAndRemovesKey() throws {
        let vm = ChatListViewModel()
        vm.addChat(modelContext: context)

        var chats = try fetchChats()
        XCTAssertEqual(chats.count, 1)
        let deletedId = chats[0].id
        idsToCleanup.append(deletedId)

        let otherId = UUID().uuidString
        idsToCleanup.append(otherId)
        let otherPub = try CryptoHelper.generateKey(for: otherId)

        vm.deleteChats(offsets: IndexSet(integer: 0), chats: chats, modelContext: context)

        chats = try fetchChats()
        XCTAssertEqual(chats.count, 0)

        XCTAssertThrowsError(try CryptoHelper.encrypt(message: "x", using: otherPub, myKeyId: deletedId))
    }

    func testHandleScannedQRCodeCreatesNewChat() throws {
        let vm = ChatListViewModel()

        let remoteId = UUID().uuidString
        let remotePub = try CryptoHelper.generateKey(for: remoteId)
        idsToCleanup.append(remoteId)

        let payload = QRPayload(chatId: remoteId, pubKey: remotePub)
        let scannedString = String(data: try JSONEncoder().encode(payload), encoding: .utf8)!
        
        vm.handleScannedQRCode(scannedString, chats: [], modelContext: context)

        let chats = try fetchChats()
        XCTAssertEqual(chats.count, 1)
        XCTAssertEqual(chats[0].id, remoteId)
        XCTAssertEqual(chats[0].theirPublicKey, remotePub)
        XCTAssertFalse(chats[0].myPublicKey.isEmpty)

        idsToCleanup.append(chats[0].id)
    }

    func testHandleScannedQRCodeUpdatesExistingChat() throws {
        let vm = ChatListViewModel()

        let chatId = UUID().uuidString
        let myPub = try CryptoHelper.generateKey(for: chatId)
        idsToCleanup.append(chatId)

        let existing = Chat(id: chatId, writingKey: myPub, readingKey: nil, timestamp: Date())
        context.insert(existing)

        let remoteId = UUID().uuidString
        let remotePub = try CryptoHelper.generateKey(for: remoteId)
        idsToCleanup.append(remoteId)

        let payload = QRPayload(chatId: chatId, pubKey: remotePub)
        let scannedString = String(data: try JSONEncoder().encode(payload), encoding: .utf8)!

        vm.handleScannedQRCode(scannedString, chats: [existing], modelContext: context)

        let chats = try fetchChats()
        XCTAssertEqual(chats.count, 1)
        XCTAssertEqual(chats[0].id, chatId)
        XCTAssertEqual(chats[0].theirPublicKey, remotePub)
    }

    func testHandleScannedQRCodeNoOpWhenAlreadyProcessing() throws {
        let vm = ChatListViewModel()
        vm.isProcessingScan = true

        let payload = QRPayload(chatId: UUID().uuidString, pubKey: "x")
        let scannedString = String(data: try JSONEncoder().encode(payload), encoding: .utf8)!

        vm.handleScannedQRCode(scannedString, chats: [], modelContext: context)

        let chats = try fetchChats()
        XCTAssertEqual(chats.count, 0)
    }
}

