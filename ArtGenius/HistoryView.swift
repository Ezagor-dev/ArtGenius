//
//  HistoryView.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import SwiftUI


// IdentifiableImage struct
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct HistoryView: View {
    @Binding var promptHistory: [HistoryItem]
    @State private var selectedIdentifiableImage: IdentifiableImage?

    var body: some View {
        List(promptHistory) { item in
            Text(item.prompt)
                .onTapGesture {
                    if let uiImage = item.imageBase64.imageFromBase64 {
                        self.selectedIdentifiableImage = IdentifiableImage(image: uiImage)
                    }
                }
        }
        .sheet(item: $selectedIdentifiableImage) { identifiableImage in
            FullScreenImageView(image: identifiableImage.image)
        }
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
