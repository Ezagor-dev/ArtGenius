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
    @State private var isLoading = false
    @State private var isShowingFullScreenImage = false
    @State private var generatedImageURLs: [URL] = [] // An array to store generated image URLs
    @State private var selectedImageIndex: Int? // Property to track the selected image index

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter a prompt", text: $promptText)
                    .padding()

                Button("Generate Image") {
                    isLoading = true
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) // Close the keyboard
                    generateImage()
                }
                .padding()
                .disabled(isLoading)

                if isLoading {
                    ProgressView("Generating Image...")
                        .padding()
                } else if generatedImageURLs.count > 0 {
                    ImageURLView(imageURL: generatedImageURLs.last!)
                        .onTapGesture {
                            selectedImageIndex = generatedImageURLs.count - 1
                            isShowingFullScreenImage = true
                        }
                }
            }
            .navigationBarTitle("ArtGenius", displayMode: .inline)
        }
        .fullScreenCover(isPresented: $isShowingFullScreenImage) {
            if let selectedImageIndex = selectedImageIndex {
                FullScreenImageView(imageURL: generatedImageURLs[selectedImageIndex],
                                    selectedImageIndex: selectedImageIndex,
                                    generatedImageURLs: generatedImageURLs)
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
                        generatedImageURLs.append(imageURL) // Append the generated image URL
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
       let selectedImageIndex: Int? // Pass selectedImageIndex as a parameter
       let generatedImageURLs: [URL] // Pass generatedImageURLs as a parameter

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
                                                       if let selectedImageIndex = selectedImageIndex {
                                                           let imageURL = generatedImageURLs[selectedImageIndex]
                                                           if let uiImage = UIImage(contentsOfFile: imageURL.path) {
                                                               shareOrSaveImage(image: uiImage)
                                                           } else {
                                                               print("Invalid image URL or failed to load the image.")
                                                           }
                                                       } else {
                                                           print("No image selected.")
                                                       }
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
        .navigationBarItems(trailing: Button(action: {
            if let selectedImageIndex = selectedImageIndex {
                let imageURL = generatedImageURLs[selectedImageIndex]
                if let uiImage = UIImage(contentsOfFile: imageURL.path) {
                    shareOrSaveImage(image: uiImage)
                } else {
                    print("Invalid image URL or failed to load the image.")
                }
            } else {
                print("No image selected.")
            }
        }) {
            Image(systemName: "square.and.arrow.up")
        })
    }

    // Function to share or save the image
    private func shareOrSaveImage(image: UIImage) {
        // Share the image
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
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
