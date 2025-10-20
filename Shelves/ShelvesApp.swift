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
    @StateObject private var developerSettings = DeveloperSettings.shared
    @State private var showDatabaseRecoveryAlert = false
    @State private var recoveryAlertMessage = ""

    var body: some Scene {
        WindowGroup {
            if userManager.hasCompletedOnboarding {
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(themeManager)
                    .environmentObject(userManager)
                    .environmentObject(developerSettings)
                    .alert("Database Recovery", isPresented: $showDatabaseRecoveryAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(recoveryAlertMessage)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .coreDataRecoveryRequired)) { notification in
                        if let message = notification.userInfo?["message"] as? String {
                            recoveryAlertMessage = message
                            showDatabaseRecoveryAlert = true
                        }
                    }
            } else {
                OnboardingView()
                    .environmentObject(themeManager)
                    .environmentObject(userManager)
            }
        }
    }
}
