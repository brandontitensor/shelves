//
//  ShelvesApp.swift
//  Shelves
//
//  Created by Brandon Titensor on 7/26/25.
//

import SwiftUI

@main
struct ShelvesApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
