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
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var userManager = UserManager.shared

    var body: some Scene {
        WindowGroup {
            if userManager.hasCompletedOnboarding {
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(themeManager)
                    .environmentObject(userManager)
            } else {
                OnboardingView()
                    .environmentObject(userManager)
            }
        }
    }
}
