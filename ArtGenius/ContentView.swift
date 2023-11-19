//
//  ContentView.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import SwiftUI
import UIKit

struct APIResponse: Codable {
    let data: [ImageData]
}

struct ImageData: Codable {
    let b64_json: String
}

struct ContentView: View {
    @State private var promptText = ""
    @State private var isLoading = false
    @State private var isShowingFullScreenImage = false
    @State private var generatedImages: [UIImage] = []
    @State private var selectedImageIndex: Int?
    @State private var promptHistory: [HistoryItem] = HistoryManager.shared.loadHistory()
    @State private var selectedImageUrl: URL?
    
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter your prompt:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding()
                        
                        
                        TextEditor(text: $promptText)
                            .frame(height: 100)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary, lineWidth: 1)
                            )
                            .padding()
                    }
                    
                    Button("Generate Image") {
                        isLoading = true
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        generateImage()
                    }
                    .padding()
                    .disabled(isLoading)
                    
                    if isLoading {
                        ProgressView("Generating Image...")
                            .padding()
                    } else {
                        ForEach(0..<generatedImages.count, id: \.self) { index in
                            Image(uiImage: generatedImages[index])
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .onTapGesture {
                                            self.selectedImageIndex = index
                                        }
                        }
                        .background(
                            NavigationLink(
                                "",
                                destination: ImageDetailView(imageURL: selectedImageUrl ?? URL(string: "https://ezagor.com")!),
                                isActive: Binding<Bool>(
                                    get: { self.selectedImageUrl != nil },
                                    set: { if !$0 { self.selectedImageUrl = nil } }
                                )
                            )
                            
                        )// Add the "Show History" Navigation Link
                        NavigationLink("Show History", destination: HistoryView(promptHistory: $promptHistory))
                            .padding()
                        
                        Spacer() // To ensure the link is not at the bottom of the view
                            .navigationBarTitle("ArtGenius", displayMode: .inline)
                    }
                       
                    
                }
            } .fullScreenCover(isPresented: $isShowingFullScreenImage) {
                if let selectedImageIndex = selectedImageIndex, selectedImageIndex < generatedImages.count {
                    FullScreenImageView(image: generatedImages[selectedImageIndex])
                }
            }
            
        }
    }
            
            
            // Call this function when an image is generated successfully
    func saveToHistory(prompt: String, imageBase64: String) {
        let newItem = HistoryItem(id: UUID(), prompt: prompt, imageBase64: imageBase64)
        promptHistory.append(newItem)
        HistoryManager.shared.saveHistory(history: promptHistory)
    }
            
            // func gen img
            
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
                    "n": 1,
                    "response_format": "b64_json"  // Specify the response format as base64
                ]
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                } catch {
                    print("Error encoding parameters: \(error)")
                    
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
                        
                        // Print the raw JSON response for debugging
                        let rawJSON = String(data: data, encoding: .utf8)
                        print("Raw JSON Response: \(rawJSON ?? "No JSON data")")
                        
                        do {
                            let decoder = JSONDecoder()
                            let result = try decoder.decode(APIResponse.self, from: data)
                            if let imageDatas = result.data.first?.b64_json {
                                            self.handleBase64Image(imageDatas)
                                        }
                        } catch {
                            print("Error decoding JSON: \(error)")
                        }
                    }
                }.resume()
            }
            
            
    func handleBase64Image(_ base64String: String) {
        if let imageData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters),
           let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
                self.generatedImages.append(image)
                saveToHistory(prompt: promptText, imageBase64: base64String)
            }
        } else {
            print("Error: Unable to convert Base64 to UIImage")
        }
    }
    
    
    func saveImage(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 1.0) ?? image.pngData() else {
            return nil
        }
        let filename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).png")
        try? data.write(to: filename)
        return filename
    }

            
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

            
        }
    
    
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
    
    
    

