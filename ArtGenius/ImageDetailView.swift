//
//  ImageDetailView.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import SwiftUI

struct ImageDetailView: View {
    let image: UIImage

    var body: some View {
        FullScreenImageView(image: image)
    }
}
