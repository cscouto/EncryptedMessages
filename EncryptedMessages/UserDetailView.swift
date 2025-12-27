//
//  UserDetailView.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/27/25.
//

import SwiftUI

struct UserDetailView: View {
    var user: User
    
    var body: some View {
        VStack(spacing: 20) {
            Text("User ID: \(user.id)")
                .font(.headline)
            
            if let publicKey = user.userPublicKey {
                Text("Public Key: \(publicKey)")
                    .font(.subheadline)
            } else {
                Text("No public key shared yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text("Created: \(user.timestamp.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            QRCodeView(payload: QRPayload(userId: user.id, relKey: user.relKey))
                .frame(width: 200, height: 200)
        }
        .padding()
    }
}

