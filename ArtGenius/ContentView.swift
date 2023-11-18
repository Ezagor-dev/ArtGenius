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
    @State private var generatedImageURLs: [URL] = []
    @State private var selectedImageIndex: Int?
    @State private var promptHistory: [HistoryItem] = HistoryManager.shared.loadHistory()


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
                    } else if !generatedImageURLs.isEmpty {
                        ForEach(generatedImageURLs.indices, id: \.self) { index in
                            ImageURLView(imageURL: generatedImageURLs[index])
                                .onTapGesture {
                                    self.selectedImageIndex = index
                                    self.isShowingFullScreenImage = true
                                }
                        }
                    }
                    
                    NavigationLink("Show History", destination: HistoryView(promptHistory: $promptHistory))
                        .padding()
                }
                .navigationBarTitle("ArtGenius", displayMode: .inline)
            }
            .fullScreenCover(isPresented: $isShowingFullScreenImage) {
                            if let selectedImageIndex = selectedImageIndex {
                                    FullScreenImageView(imageURL: generatedImageURLs[selectedImageIndex])
                                }
                        }
            
        }
    }
            
            struct APIResponse: Codable {
                let data: [ImageData]
            }
            
            struct ImageData: Codable {
                let url: String
            }
    // Call this function when an image is generated successfully
    func saveToHistory(prompt: String, imageURL: URL) {
        let newItem = HistoryItem(id: UUID(), prompt: prompt, imageURL: imageURL)
        promptHistory.append(newItem)
        HistoryManager.shared.saveHistory(history: promptHistory)
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
                                    print("Image URL:", imageURL)
                                    saveToHistory(prompt: promptText, imageURL: imageURL) // Update this line
                                }
                            } catch {
                                print("Error decoding JSON: \(error)")
                            }
                        }
                    }.resume()
                }
        }
        
        
        
        struct ContentView_Previews: PreviewProvider {
            static var previews: some View {
                ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            }
        }
        
        

