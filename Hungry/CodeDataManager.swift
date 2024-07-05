//
//  CodeDataManager.swift
//  Hungry
//
//  Created by Rodney Gainous Jr on 7/5/24.
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "HungryModel")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func saveRecipe(_ recipe: Recipe) {
        let context = persistentContainer.viewContext
        let savedRecipe = SavedRecipe(context: context)
        savedRecipe.id = recipe.id
        savedRecipe.name = recipe.name
        savedRecipe.ingredients = recipe.ingredients as NSObject
        savedRecipe.instructions = recipe.instructions as NSObject
        savedRecipe.prepTime = Int16(recipe.prepTime)
        savedRecipe.requiredAppliances = recipe.requiredAppliances as NSObject
        savedRecipe.isVegetarian = recipe.isVegetarian
        savedRecipe.isVegan = recipe.isVegan
        savedRecipe.isGlutenFree = recipe.isGlutenFree
        savedRecipe.isDairyFree = recipe.isDairyFree
        
        saveContext()
    }
    
    func saveDietaryFilter(_ filter: DietaryFilter) {
        UserDefaults.standard.set(filter.rawValue, forKey: "dietaryFilter")
    }
    
    func loadDietaryFilter() -> DietaryFilter {
        if let filterString = UserDefaults.standard.string(forKey: "dietaryFilter"),
           let filter = DietaryFilter(rawValue: filterString) {
            return filter
        }
        return .all // Default value if no filter is saved
    }
    
    func fetchSavedRecipes() -> [Recipe] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<SavedRecipe> = SavedRecipe.fetchRequest()
        
        do {
            let savedRecipes = try context.fetch(fetchRequest)
            return savedRecipes.map { savedRecipe in
                Recipe(name: savedRecipe.name ?? "",
                       ingredients: savedRecipe.ingredients as? [String] ?? [],
                       instructions: savedRecipe.instructions as? [String] ?? [],
                       prepTime: Int(savedRecipe.prepTime),
                       requiredAppliances: savedRecipe.requiredAppliances as? [String] ?? [],
                       isVegetarian: savedRecipe.isVegetarian,
                       isVegan: savedRecipe.isVegan,
                       isGlutenFree: savedRecipe.isGlutenFree,
                       isDairyFree: savedRecipe.isDairyFree)
            }
        } catch {
            print("Failed to fetch recipes: \(error)")
            return []
        }
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<SavedRecipe> = SavedRecipe.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", recipe.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let recipeToDelete = results.first {
                context.delete(recipeToDelete)
                saveContext()
            }
        } catch {
            print("Failed to delete recipe: \(error)")
        }
    }
}
