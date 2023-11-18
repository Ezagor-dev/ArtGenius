//
//  ImageURLView.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import SwiftUI

struct ImageURLView: View {
    let imageURL: URL
    
    var body: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            case .failure(_):
                Text("Error loading image")
                    .foregroundColor(.red)
            case .empty:
                ProgressView()
            }
        }
    }
}



