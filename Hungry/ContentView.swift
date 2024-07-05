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
    @State private var showingImagePicker = false
    @State private var showingIngredientSheet = false
    @State private var showingSavedRecipes = false
    @State private var dietaryFilter: DietaryFilter = CoreDataManager.shared.loadDietaryFilter() {
        didSet {
            CoreDataManager.shared.saveDietaryFilter(dietaryFilter)
        }
    }
    @State private var savedRecipes: [Recipe] = []
    
    
    var filteredRecipes: [Recipe] {
        switch dietaryFilter {
        case .all:
            return possibleRecipes
        case .vegetarian:
            return possibleRecipes.filter { $0.isVegetarian }
        case .vegan:
            return possibleRecipes.filter { $0.isVegan }
        case .glutenFree:
            return possibleRecipes.filter { $0.isGlutenFree }
        case .dairyFree:
            return possibleRecipes.filter { $0.isDairyFree }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(capturedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        }
                    }
                }
                
                Button("Take Photo") {
                    showingImagePicker = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                if !identifiedIngredients.isEmpty {
                    Text("Identified Ingredients:")
                        .font(.headline)
                    Text(identifiedIngredients.joined(separator: ", "))
                        .padding()
                    
                    Button("Edit Ingredients") {
                        showingIngredientSheet = true
                    }
                    .padding()
                    
                    Button("Find Recipes") {
                        generateRecipes()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                if isProcessing {
                    ProgressView("Processing...")
                }
                
                if !possibleRecipes.isEmpty {
                    Picker("Dietary Filter", selection: $dietaryFilter) {
                        ForEach(DietaryFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    List(filteredRecipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe, isSaved: savedRecipes.contains(where: { $0.id == recipe.id }), saveAction: {
                            saveRecipe(recipe)
                        })) {
                            RecipeRowView(recipe: recipe)
                        }
                    }
                }
            }
            .navigationTitle("Kitchen Assistant")
            .navigationBarItems(trailing: Button("Saved Recipes") {
                showingSavedRecipes = true
            })
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: Binding<UIImage?>(
                    get: { self.capturedImages.last },
                    set: { newImage in
                        if let image = newImage {
                            self.capturedImages.append(image)
                        }
                    }
                ), sourceType: .camera) { success in
                    if success, let image = self.capturedImages.last {
                        identifyIngredientsInImage(image)
                    }
                }
            }
            .sheet(isPresented: $showingIngredientSheet) {
                IngredientManagementView(ingredients: $identifiedIngredients, onDone: generateRecipes)
            }
            .sheet(isPresented: $showingSavedRecipes) {
                SavedRecipesView(savedRecipes: $savedRecipes)
            }
        }
        .onAppear(perform: loadSavedData)
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
    
    func generateRecipes() {
        let prompt = """
        Generate 5 recipes using some or all of these ingredients: \(identifiedIngredients.joined(separator: ", ")).
        For each recipe, provide:
        1. Name
        2. Ingredients (with quantities)
        3. Instructions
        4. Preparation time
        5. Required appliances (e.g., oven, microwave, air fryer)
        6. Dietary information (isVegetarian, isVegan, isGlutenFree, isDairyFree)
        
        Format the output as JSON. No need to format it for an HTML view, this needs to be JSON only, and in plain-text.
        """
        
        let query = ChatQuery(messages: [.init(role: .user, content: prompt)!], model: .gpt4_o, temperature: 0.7)
        
        Task {
            do {
                let result = try await openAI.chats(query: query)
                if let content = result.choices.first?.message.content?.string {
                    let recipes = self.parseRecipes(content)
                    DispatchQueue.main.async {
                        self.possibleRecipes = recipes
                        self.isProcessing = false
                    }
                }
            } catch {
                print("Error generating recipes: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
    
    func parseRecipes(_ jsonString: String) -> [Recipe] {
        // Remove markdown code block delimiters and any HTML tags
        let cleanedJsonString = jsonString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        guard let jsonData = cleanedJsonString.data(using: .utf8) else {
            print("Failed to convert string to data")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let recipes = try decoder.decode([Recipe].self, from: jsonData)
            return recipes
        } catch {
            print("Error parsing JSON array: \(error)")
            
            // If parsing fails, try to extract information manually
            return extractRecipesManually(from: cleanedJsonString)
        }
    }

    func extractRecipesManually(from jsonString: String) -> [Recipe] {
        var recipes: [Recipe] = []
        let recipeStrings = jsonString.components(separatedBy: "},{")
        
        for recipeString in recipeStrings {
            if let recipe = extractRecipeManually(from: recipeString) {
                recipes.append(recipe)
            }
        }
        
        return recipes
    }

    func extractRecipeManually(from jsonString: String) -> Recipe? {
        // This function remains largely the same as before, but we'll make it more robust
        var name = ""
        var ingredients: [String] = []
        var instructions: [String] = []
        var prepTime = 0
        var requiredAppliances: [String] = []
        var isVegetarian = false
        var isVegan = false
        var isGlutenFree = false
        var isDairyFree = false
        
        let lines = jsonString.components(separatedBy: .newlines)
        
        for line in lines {
            let cleanedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanedLine.contains("\"name\":") {
                name = extractValue(from: cleanedLine)
            } else if cleanedLine.contains("\"ingredients\":") {
                ingredients = extractArray(from: cleanedLine)
            } else if cleanedLine.contains("\"instructions\":") {
                instructions = extractArray(from: cleanedLine)
            } else if cleanedLine.contains("\"prepTime\":") {
                prepTime = Int(extractValue(from: cleanedLine)) ?? 0
            } else if cleanedLine.contains("\"requiredAppliances\":") {
                requiredAppliances = extractArray(from: cleanedLine)
            } else if cleanedLine.contains("\"isVegetarian\":") {
                isVegetarian = extractValue(from: cleanedLine).lowercased() == "true"
            } else if cleanedLine.contains("\"isVegan\":") {
                isVegan = extractValue(from: cleanedLine).lowercased() == "true"
            } else if cleanedLine.contains("\"isGlutenFree\":") {
                isGlutenFree = extractValue(from: cleanedLine).lowercased() == "true"
            } else if cleanedLine.contains("\"isDairyFree\":") {
                isDairyFree = extractValue(from: cleanedLine).lowercased() == "true"
            }
        }
        
        return Recipe(name: name,
                      ingredients: ingredients,
                      instructions: instructions,
                      prepTime: prepTime,
                      requiredAppliances: requiredAppliances,
                      isVegetarian: isVegetarian,
                      isVegan: isVegan,
                      isGlutenFree: isGlutenFree,
                      isDairyFree: isDairyFree)
    }

    func extractValue(from line: String) -> String {
        let components = line.components(separatedBy: ":")
        guard components.count > 1 else { return "" }
        return components[1...].joined(separator: ":")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: ",", with: "")
    }

    func extractArray(from line: String) -> [String] {
        let components = line.components(separatedBy: ":")
        guard components.count > 1 else { return [] }
        
        let arrayString = components.dropFirst().joined(separator: ":")
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "\"", with: "")
        
        return arrayString.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    func loadSavedData() {
        savedRecipes = CoreDataManager.shared.fetchSavedRecipes()
        dietaryFilter = CoreDataManager.shared.loadDietaryFilter()
    }
    
    func saveRecipe(_ recipe: Recipe) {
            CoreDataManager.shared.saveRecipe(recipe)
            savedRecipes.append(recipe)
        }
    }

    struct Recipe: Identifiable, Codable {
        var id = UUID()
        let name: String
        let ingredients: [String]
        let instructions: [String]
        let prepTime: Int
        let requiredAppliances: [String]
        let isVegetarian: Bool
        let isVegan: Bool
        let isGlutenFree: Bool
        let isDairyFree: Bool
        
        init(id: UUID = UUID(), name: String, ingredients: [String], instructions: [String], prepTime: Int, requiredAppliances: [String], isVegetarian: Bool, isVegan: Bool, isGlutenFree: Bool, isDairyFree: Bool) {
                self.id = id
                self.name = name
                self.ingredients = ingredients
                self.instructions = instructions
                self.prepTime = prepTime
                self.requiredAppliances = requiredAppliances
                self.isVegetarian = isVegetarian
                self.isVegan = isVegan
                self.isGlutenFree = isGlutenFree
                self.isDairyFree = isDairyFree
            }
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
        let isSaved: Bool
        let saveAction: () -> Void
        
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
                    
                    Section(header: Text("Dietary Information").font(.headline)) {
                        Text("Vegetarian: \(recipe.isVegetarian ? "Yes" : "No")")
                        Text("Vegan: \(recipe.isVegan ? "Yes" : "No")")
                        Text("Gluten-Free: \(recipe.isGlutenFree ? "Yes" : "No")")
                        Text("Dairy-Free: \(recipe.isDairyFree ? "Yes" : "No")")
                    }
                    
                    if !isSaved {
                        Button("Save Recipe") {
                            saveAction()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }.padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

#Preview {
    ContentView()
}
