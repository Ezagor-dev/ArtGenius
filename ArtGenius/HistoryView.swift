//
//  HistoryView.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//
import SwiftUI
import UIKit

struct HistoryView: View {
    @Binding var promptHistory: [HistoryItem]

    var body: some View {
        List(promptHistory) { item in
            Text(item.prompt)
                .onTapGesture {
                    if let image = item.imageBase64.imageFromBase64 {
                        showImageDetailView(image: image)
                    }
                }
        }
    }
    
    private func showImageDetailView(image: UIImage) {
        let imageDetailView = ImageDetailView(image: image)
        let hostingController = UIHostingController(rootView: imageDetailView)
        UIApplication.shared.windows.first?.rootViewController?.present(hostingController, animated: true)
    }
}


extension String {
    var imageFromBase64: UIImage? {
        guard let imageData = Data(base64Encoded: self, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}
