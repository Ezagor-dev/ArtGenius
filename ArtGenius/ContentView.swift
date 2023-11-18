//
//  ContentView.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import SwiftUI

struct ContentView: View {
    @State private var promptText = ""
    @State private var generatedImageURL: String?
    @State private var isLoading = false
    
    var body: some View {
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
            } else if let imageURL = generatedImageURL {
                ImageURLView(imageURL: imageURL)
            }
        }
    }
    
    func generateImage() {
        let apiURL = URL(string: "https://api.openai.com/v1/images/generations")!
        let apiKey = "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"
        
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
                    if let imageURL = result.data.first?.url {
                        generatedImageURL = imageURL
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }
}

struct APIResponse: Codable {
    let data: [ImageData]
}

struct ImageData: Codable {
    let url: String
}

struct ImageURLView: View {
    let imageURL: String
    
    var body: some View {
        if let url = URL(string: imageURL), let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
        } else {
            Text("Error loading image")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
