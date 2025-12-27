//
//  QRCodeView.swift
//  EncryptedMessages
//
//  Created by Tiago Do Couto on 12/27/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let payload: QRPayload
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        if let qrImage = generateQRCode(from: payload) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Text("Failed to generate QR code")
                .foregroundColor(.red)
        }
    }
    
    private func generateQRCode(from payload: QRPayload) -> UIImage? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(payload) else { return nil }
        
        filter.setValue(data, forKey: "inputMessage")
        if let outputImage = filter.outputImage {
            let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cgimg = context.createCGImage(scaled, from: scaled.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return nil
    }
}
