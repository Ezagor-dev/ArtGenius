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
    @State private var uiImage: UIImage?

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit)
                    case .failure(let error):
                        // Log the error
                        Text("Failed to load image: \(error.localizedDescription)")
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
                Spacer()
            }
            .navigationBarItems(trailing: Button(action: {
                loadAndShareImage()
            }) {
                Image(systemName: "square.and.arrow.up")
            })
            .sheet(isPresented: $showShareSheet, content: {
                if let uiImage = self.uiImage {
                    ActivityViewController(activityItems: [uiImage])
                }
            })
        }
    }

    private func loadAndShareImage() {
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = image
                    self.showShareSheet = true
                }
            }
        }.resume()
    }
}

