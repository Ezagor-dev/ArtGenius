//
//  ImageDetailView.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import SwiftUI

struct ImageDetailView: View {
    let imageURL: URL
    @State private var showShareSheet = false

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
            .navigationBarItems(trailing: Button(action: {
                showShareSheet = true
            }) {
                Image(systemName: "square.and.arrow.up")
            })
            .sheet(isPresented: $showShareSheet, content: {
                if let imageData = try? Data(contentsOf: imageURL),
                   let uiImage = UIImage(data: imageData) {
                    ActivityViewController(activityItems: [uiImage])
                }
            })
        }
    }
}
