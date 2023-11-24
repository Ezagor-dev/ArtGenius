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
    @State private var generatedImages: [UIImage] = []
    @State private var promptHistory: [HistoryItem] = HistoryManager.shared.loadHistory()
    
    var body: some View {
            NavigationView {
                ZStack {
                    // Background gradient from top to bottom
                    LinearGradient(gradient: Gradient(colors: [Color(hex: "#yourHexValueForTopColor"), Color(hex: "#yourHexValueForTopColor")]), startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                    
                    // Content
                    VStack {
                        Spacer()
                        
                        // App title
                        Text("ArtGenius")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#F4DFC8"))
                        
                        // Prompt input area
                        TextEditor(text: $promptText)
                            .frame(height: 150)
                            .padding(4)
                            .background(Color(hex: "F4DFC8"))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding()
                        
                        // Generate Image Button
                        Button(action: {
                            isLoading.toggle()
                            generateImage()
                            // Call your generate image function here
                        }) {
                            Text(isLoading ? "Loading..." : "Generate Image")
                                .font(.headline)
                                .foregroundColor(Color(hex: "F4DFC8"))
                                .frame(height: 55)
                                .frame(maxWidth: .infinity)
                                .background(Color("ButtonColor"))
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
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
                                                            showImageDetailView(image: generatedImages[index])
                                                        }
                                                }
                                            }
                        
                        Spacer()
                        
                        // Show History Button
                        NavigationLink(destination: HistoryView(promptHistory: $promptHistory)) {
                            Text("Show History")
                                .font(.headline)
                                .foregroundColor(Color(hex: "F4DFC8"))
                                .frame(height: 55)
                                .frame(maxWidth: .infinity)
                                .background(Color("ButtonColor"))
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                }
                .navigationBarHidden(true)
            }
        }
    
    
    private func showImageDetailView(image: UIImage) {
        let imageDetailView = ImageDetailView(image: image)
        let hostingController = UIHostingController(rootView: imageDetailView)
        UIApplication.shared.windows.first?.rootViewController?.present(hostingController, animated: true)
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
                
                
                var request = URLRequest(url: apiURL)
                request.httpMethod = "POST"
                request.addValue("Bearer \(Secrets.apiKey)", forHTTPHeaderField: "Authorization")
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
    
    
    

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
