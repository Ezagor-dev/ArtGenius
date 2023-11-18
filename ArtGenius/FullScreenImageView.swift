//
//  FullScreenImageView.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import SwiftUI

struct FullScreenImageView: View {
    let imageURL: URL

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit)
                    case .failure:
                        Text("Failed to load image")
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
                Spacer()
            }
        }
    }
}


