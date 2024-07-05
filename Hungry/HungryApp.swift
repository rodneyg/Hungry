//
//  HungryApp.swift
//  Hungry
//
//  Created by Rodney Gainous Jr on 7/3/24.
//

import SwiftUI

@main
struct HungryApp: App {
    let persistenceController = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
        }
    }
}
