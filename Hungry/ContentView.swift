//
//  ContentView.swift
//  Hungry
//
//  Created by Rodney Gainous Jr on 7/3/24.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    @State private var capturedImages: [UIImage] = []
    @State private var identifiedIngredients: [String] = []
    @State private var possibleRecipes: [Recipe] = []
    @State private var isProcessing = false
    
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
            .navigationTitle("Hungry")
        }
    }
    
    func captureImage() {
        // Implement camera functionality
        // Add captured image to capturedImages array
    }
    
    func processImages() {
        isProcessing = true
        // Call OpenAI Vision API to identify ingredients
        // Then call GPT-4 API to generate recipes
        // Update identifiedIngredients and possibleRecipes
        // Set isProcessing to false when done
    }
}

struct Recipe: Identifiable {
    let id = UUID()
    let name: String
    let ingredients: [String]
    let instructions: [String]
    let prepTime: Int
}

struct RecipeRowView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(recipe.name).font(.headline)
            Text("Prep Time: \(recipe.prepTime) minutes").font(.subheadline)
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
