//
//  DeveloperSettings.swift
//  Shelves
//
//  Developer tools and feature flags
//

import Foundation
import SwiftUI

class DeveloperSettings: ObservableObject {
    static let shared = DeveloperSettings()

    // MARK: - Developer Mode
    @Published var isDeveloperModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDeveloperModeEnabled, forKey: "developerModeEnabled")
        }
    }

    // MARK: - Feature Flags
    @Published var showTestDataGenerator: Bool {
        didSet {
            UserDefaults.standard.set(showTestDataGenerator, forKey: "showTestDataGenerator")
        }
    }

    @Published var showClearDataOption: Bool {
        didSet {
            UserDefaults.standard.set(showClearDataOption, forKey: "showClearDataOption")
        }
    }

    @Published var showLibraryStats: Bool {
        didSet {
            UserDefaults.standard.set(showLibraryStats, forKey: "showLibraryStats")
        }
    }

    @Published var enableDebugLogging: Bool {
        didSet {
            UserDefaults.standard.set(enableDebugLogging, forKey: "enableDebugLogging")
        }
    }

    @Published var showPerformanceMetrics: Bool {
        didSet {
            UserDefaults.standard.set(showPerformanceMetrics, forKey: "showPerformanceMetrics")
        }
    }

    private init() {
        // Load developer mode state
        self.isDeveloperModeEnabled = UserDefaults.standard.bool(forKey: "developerModeEnabled")

        // Load feature flags (default to false for production)
        self.showTestDataGenerator = UserDefaults.standard.bool(forKey: "showTestDataGenerator")
        self.showClearDataOption = UserDefaults.standard.bool(forKey: "showClearDataOption")
        self.showLibraryStats = UserDefaults.standard.bool(forKey: "showLibraryStats")
        self.enableDebugLogging = UserDefaults.standard.bool(forKey: "enableDebugLogging")
        self.showPerformanceMetrics = UserDefaults.standard.bool(forKey: "showPerformanceMetrics")
    }

    // MARK: - Helper Methods
    func resetAllSettings() {
        isDeveloperModeEnabled = false
        showTestDataGenerator = false
        showClearDataOption = false
        showLibraryStats = false
        enableDebugLogging = false
        showPerformanceMetrics = false
    }

    func enableAllFeatures() {
        showTestDataGenerator = true
        showClearDataOption = true
        showLibraryStats = true
        enableDebugLogging = true
        showPerformanceMetrics = true
    }
}
