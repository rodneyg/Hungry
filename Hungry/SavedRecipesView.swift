//
//  SavedRecipesView.swift
//  Hungry
//
//  Created by Rodney Gainous Jr on 7/5/24.
//

import SwiftUI

struct SavedRecipesView: View {
    @Binding var savedRecipes: [Recipe]

    var body: some View {
        NavigationView {
            List {
                ForEach(savedRecipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe, isSaved: true, saveAction: {})) {
                        RecipeRowView(recipe: recipe)
                    }
                }
                .onDelete(perform: deleteRecipes)
            }
            .navigationBarTitle("Saved Recipes")
        }
    }

    func deleteRecipes(at offsets: IndexSet) {
        savedRecipes.remove(atOffsets: offsets)
        // Update CoreData here
        for index in offsets {
            CoreDataManager.shared.deleteRecipe(savedRecipes[index])
        }
    }
}

struct SavedRecipesView_Previews: PreviewProvider {
    static var previews: some View {
        SavedRecipesView(savedRecipes: .constant(sampleRecipes))
    }
    
    static var sampleRecipes: [Recipe] = [
        Recipe(name: "Pasta Carbonara",
               ingredients: ["Spaghetti", "Eggs", "Bacon", "Parmesan cheese"],
               instructions: ["Cook pasta", "Fry bacon", "Mix eggs and cheese", "Combine all ingredients"],
               prepTime: 30,
               requiredAppliances: ["Stove", "Frying pan"],
               isVegetarian: false,
               isVegan: false,
               isGlutenFree: false,
               isDairyFree: false),
        Recipe(name: "Vegetable Stir-Fry",
               ingredients: ["Mixed vegetables", "Tofu", "Soy sauce", "Ginger"],
               instructions: ["Chop vegetables", "Fry tofu", "Stir-fry vegetables", "Add sauce"],
               prepTime: 25,
               requiredAppliances: ["Wok", "Stove"],
               isVegetarian: true,
               isVegan: true,
               isGlutenFree: true,
               isDairyFree: true)
    ]
}
