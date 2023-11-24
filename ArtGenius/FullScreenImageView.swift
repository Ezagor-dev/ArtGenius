//
//  FullScreenImageView.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import SwiftUI

struct FullScreenImageView: View {
    let image: UIImage
    @State private var showShareSheet = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Spacer()
            }
            .navigationBarItems(trailing: Button(action: {
                showShareSheet = true
            }) {
                Image(systemName: "square.and.arrow.up")
            })
            .sheet(isPresented: $showShareSheet) {
                ActivityViewController(activityItems: [image])
            }
        }
    }
}
