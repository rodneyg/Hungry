//
//  ContentView.swift
//  Hungry
//
//  Created by Rodney Gainous Jr on 7/3/24.
//

import SwiftUI
import OpenAI

struct ContentView: View {
    @State private var capturedImages: [UIImage] = []
    @State private var identifiedIngredients: [String] = []
    @State private var possibleRecipes: [Recipe] = []
    @State private var isProcessing = false
    
    let openAI = OpenAI(apiToken: "YOUR_API_KEY_HERE")
    
    var body: some View {
        NavigationView {
            VStack {
                if capturedImages.isEmpty {
                    CameraButton(action: captureImage)
                } else {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(capturedImages, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                            }
                        }
                    }
                    Button("Process Images") {
                        processImages()
                    }
                    .disabled(isProcessing)
                }
                
                if isProcessing {
                    ProgressView("Identifying ingredients and generating recipes...")
                }
                
                if !possibleRecipes.isEmpty {
                    List(possibleRecipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeRowView(recipe: recipe)
                        }
                    }
                }
            }
            .navigationTitle("Kitchen Assistant")
        }
    }
    
    func captureImage() {
        // Implement camera functionality
        // Add captured image to capturedImages array
    }
    
    func processImages() {
        isProcessing = true
        
        let group = DispatchGroup()
        
        //        for image in capturedImages {
        //            group.enter()
        //            identifyIngredientsInImage(image) { ingredients in
        //                identifiedIngredients.append(contentsOf: ingredients)
        //                group.leave()
        //            }
        //        }
        
        group.notify(queue: .main) {
            generateRecipes()
        }
    }
    
    func identifyIngredientsInImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data")
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        isProcessing = true
        
        let textContent = ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam.Content.VisionContent.ChatCompletionContentPartTextParam(text: "")
        
        let imageContent = ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam.Content.VisionContent.ChatCompletionContentPartImageParam(imageUrl: .init(url: imageData, detail: .high))
        
        // Create the message parameter
        let messageParam = ChatQuery.ChatCompletionMessageParam(
            role: .user,
            content: [
                ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam.Content.VisionContent.chatCompletionContentPartTextParam(textContent),
                ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam.Content.VisionContent.chatCompletionContentPartImageParam(imageContent)
            ]
        )
        
        guard let params = messageParam else {
            print("parameters wrong")
            return
        }
        
        let query = ChatQuery(
            messages: [params],
            model: .gpt4_o,
            temperature: 1.0
        )
        
        Task {
            do {
                
                
                let result = try await openAI.chats(query: query)
                
                if let content = result.choices.first?.message.content?.string {
                    DispatchQueue.main.async {
                        self.identifiedIngredients = content.components(separatedBy: ", ")
                        self.isProcessing = false
                    }
                }
            } catch {
                print("Error identifying ingredients: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
    
    func parseIngredientsFromResponse(_ response: String) -> [String] {
        // Implement parsing logic to extract ingredients from the response
        // This will depend on how the Vision API formats its response
        return []
    }
    
    func generateRecipes() {
        let prompt = """
        Generate 5 recipes using some or all of these ingredients: \(identifiedIngredients.joined(separator: ", ")).
        For each recipe, provide:
        1. Name
        2. Ingredients (with quantities)
        3. Instructions
        4. Preparation time
        5. Required appliances (e.g., oven, microwave, air fryer)
        
        Format the output as JSON.
        """
        
        let query = ChatQuery(messages: [.init(role: .user, content: prompt)!], model: .gpt4_o, temperature: 0.7)
        
        openAI.chats(query: query) { result in
            switch result {
            case .success(let chatResult):
                if let text = chatResult.choices.first?.message.content?.string {
                    possibleRecipes = self.parseRecipesFromJSON(text)
                }
            case .failure(let error):
                print("Transformation failed: \(error)")
            }
            
            isProcessing = false
        }
    }
    
    func parseRecipesFromJSON(_ jsonString: String) -> [Recipe] {
        // Implement JSON parsing to create Recipe objects
        // This will depend on the exact JSON format returned by GPT-4
        return []
    }
}

struct Recipe: Identifiable, Codable {
    let id = UUID()
    let name: String
    let ingredients: [String]
    let instructions: [String]
    let prepTime: Int
    let requiredAppliances: [String]
}

struct RecipeRowView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(recipe.name).font(.headline)
            Text("Prep Time: \(recipe.prepTime) minutes").font(.subheadline)
            Text("Appliances: \(recipe.requiredAppliances.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(recipe.name).font(.title)
                Text("Prep Time: \(recipe.prepTime) minutes").font(.subheadline)
                
                Section(header: Text("Required Appliances").font(.headline)) {
                    Text(recipe.requiredAppliances.joined(separator: ", "))
                }
                
                Section(header: Text("Ingredients").font(.headline)) {
                    ForEach(recipe.ingredients, id: \.self) { ingredient in
                        Text("• \(ingredient)")
                    }
                }
                
                Section(header: Text("Instructions").font(.headline)) {
                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                        Text("\(index + 1). \(instruction)")
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CameraButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "camera")
                .font(.largeTitle)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
        }
    }
}

#Preview {
    ContentView()
}
