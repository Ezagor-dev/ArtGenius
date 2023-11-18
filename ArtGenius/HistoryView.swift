//
//  HistoryView.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import SwiftUI


struct HistoryView: View {
    @Binding var promptHistory: [HistoryItem]
    @State private var selectedImage: HistoryItem?



    var body: some View {
        List(promptHistory) { item in
            Text(item.prompt)
                .onTapGesture {
                    self.selectedImage = item
                }
        }
        .sheet(item: $selectedImage) { item in
            FullScreenImageView(imageURL: item.imageURL)
        }
    }
}

