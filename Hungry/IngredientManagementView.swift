//
//  IngredientManagementView.swift
//  Hungry
//
//  Created by Rodney Gainous Jr on 7/5/24.
//

import SwiftUI

struct IngredientManagementView: View {
    @Binding var ingredients: [String]
    let onDone: () -> Void
    @State private var newIngredient = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(ingredients, id: \.self) { ingredient in
                    Text(ingredient)
                }
                .onDelete(perform: deleteIngredients)

                HStack {
                    TextField("New ingredient", text: $newIngredient)
                    Button("Add") {
                        if !newIngredient.isEmpty {
                            ingredients.append(newIngredient)
                            newIngredient = ""
                        }
                    }
                }
            }
            .navigationBarTitle("Edit Ingredients")
            .navigationBarItems(trailing: Button("Done") {
                onDone()
            })
        }
    }

    func deleteIngredients(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }
}

struct IngredientManagementView_Previews: PreviewProvider {
    @State static var previewIngredients = ["Flour", "Sugar", "Eggs"]
    
    static var previews: some View {
        IngredientManagementView(ingredients: $previewIngredients, onDone: {})
    }
}
