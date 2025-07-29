import SwiftUI
import Foundation

enum AppTheme: String, CaseIterable {
    case classic = "Classic Library"
    case midnight = "Midnight Study"
    case autumn = "Autumn Reading"
    
    var description: String {
        switch self {
        case .classic: return "Warm woods and golden light"
        case .midnight: return "Cool blues and brass accents"
        case .autumn: return "Rich oranges and deep reds"
        }
    }
    
    var previewColors: [Color] {
        switch self {
        case .classic:
            return [Color(red: 0.79, green: 0.64, blue: 0.26), Color(red: 0.57, green: 0.37, blue: 0.22), Color(red: 0.50, green: 0.11, blue: 0.10)]
        case .midnight:
            return [Color.blue, Color.indigo, Color.cyan]
        case .autumn:
            return [Color.orange, Color.red, Color.yellow]
        }
    }
    
    var colors: ThemeColors {
        switch self {
        case .classic:
            return ThemeColors(
                primary: Color(red: 0.79, green: 0.64, blue: 0.26), // antiqueGold
                secondary: Color(red: 0.57, green: 0.37, blue: 0.22), // chestnut
                accent: Color(red: 0.50, green: 0.11, blue: 0.10), // burgundy
                background: Color(red: 0.97, green: 0.96, blue: 0.94), // parchment
                surface: Color(red: 0.99, green: 0.99, blue: 0.96), // ivory
                text: Color(red: 0.12, green: 0.10, blue: 0.08), // warmBlack
                textSecondary: Color(red: 0.35, green: 0.29, blue: 0.24) // sepia
            )
        case .midnight:
            return ThemeColors(
                primary: Color(red: 0.4, green: 0.7, blue: 1.0), // Soft blue
                secondary: Color(red: 0.2, green: 0.3, blue: 0.5), // Dark blue-gray
                accent: Color(red: 0.3, green: 0.5, blue: 0.8), // Medium blue
                background: Color(red: 0.08, green: 0.12, blue: 0.20), // Deep blue-black
                surface: Color(red: 0.12, green: 0.16, blue: 0.24), // Slightly lighter blue-black
                text: Color(red: 0.98, green: 0.98, blue: 1.0), // Near white
                textSecondary: Color(red: 0.85, green: 0.88, blue: 0.95) // Lighter blue-gray
            )
        case .autumn:
            return ThemeColors(
                primary: Color.orange,
                secondary: Color.red,
                accent: Color.yellow,
                background: Color(red: 0.98, green: 0.95, blue: 0.9),
                surface: Color(red: 0.95, green: 0.9, blue: 0.85),
                text: Color(red: 0.2, green: 0.1, blue: 0.0),
                textSecondary: Color(red: 0.4, green: 0.2, blue: 0.1)
            )
        }
    }
}

struct ThemeColors {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let surface: Color
    let text: Color
    let textSecondary: Color
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
            print("🎨 Theme changed to: \(currentTheme.rawValue)")
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            if notificationsEnabled {
                Task {
                    let granted = await NotificationManager.shared.requestPermission()
                    if granted {
                        NotificationManager.shared.scheduleReadingReminders()
                    } else {
                        // Permission denied, revert the toggle
                        await MainActor.run {
                            self.notificationsEnabled = false
                        }
                    }
                }
            } else {
                NotificationManager.shared.cancelReadingReminders()
            }
        }
    }
    
    @Published var autoBackupEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoBackupEnabled, forKey: "autoBackupEnabled")
        }
    }
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme")
        self.currentTheme = AppTheme(rawValue: savedTheme ?? AppTheme.classic.rawValue) ?? .classic
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.autoBackupEnabled = UserDefaults.standard.bool(forKey: "autoBackupEnabled")
    }
    
}