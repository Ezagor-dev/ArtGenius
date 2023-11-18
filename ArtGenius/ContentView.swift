//
//  ContentView.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var promptText = ""
    @State private var generatedImageURL: URL?
    @State private var isLoading = false
    @State private var isShowingFullScreenImage = false

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter a prompt", text: $promptText)
                    .padding()

                Button("Generate Image") {
                    isLoading = true
                    generateImage()
                }
                .padding()
                .disabled(isLoading)

                if isLoading {
                    ProgressView("Generating Image...")
                        .padding()
                } else if generatedImageURL != nil {
                    ImageURLView(imageURL: generatedImageURL!)
                        .onTapGesture {
                            isShowingFullScreenImage = true
                        }
                }
            }
            .navigationBarTitle("ArtGenius", displayMode: .inline)
        }
        .fullScreenCover(isPresented: $isShowingFullScreenImage) {
            if let imageURL = generatedImageURL {
                FullScreenImageView(imageURL: imageURL)
            }
        }
    }
    struct APIResponse: Codable {
        let data: [ImageData]
    }

    struct ImageData: Codable {
        let url: String
    }
    func generateImage() {
        let apiURL = URL(string: "https://api.openai.com/v1/images/generations")!
        let apiKey = "YOUR_API_KEY"
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "model": "dall-e-3",
            "prompt": promptText,
            "size": "1024x1024",
            "quality": "standard",
            "n": 1
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("Error encoding parameters: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No data received.")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(APIResponse.self, from: data)
                    if let imageURLString = result.data.first?.url,
                       let imageURL = URL(string: imageURLString) {
                        generatedImageURL = imageURL
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }

    
}
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

struct FullScreenImageView: View {
    let imageURL: URL

    var body: some View {
        VStack {
            Spacer()
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .gesture(
                            LongPressGesture(minimumDuration: 1.0).onEnded { _ in
                                saveImageToGallery(image: image)
                            }
                        )
                case .failure(_):
                    Text("Error loading image")
                        .foregroundColor(.red)
                case .empty:
                    ProgressView()
                }
            }
            Spacer()
        }
    }
    
    private func saveImageToGallery(image: Image) {
        // Convert SwiftUI Image to UIImage
        let uiImage = image.asUIImage()

        // Use UIImageWriteToSavedPhotosAlbum to save the image to the user's gallery
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)

        // Provide feedback to the user that the image is saved
        print("Image saved to gallery.")
    }
    }
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }

extension Image {
    func asUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        controller.view.bounds = CGRect(x: 0, y: 0, width: 100, height: 100) // Set the size as needed
        let image = controller.view.renderedImage()
        return image
    }
}

extension UIView {
    func renderedImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        return renderer.image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}
