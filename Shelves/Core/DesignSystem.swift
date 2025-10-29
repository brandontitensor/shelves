import SwiftUI

// MARK: - Design System for Shelves App
// Theme: Classic, Timeless, Rich, and Homey Library

struct ShelvesDesign {
    
    // MARK: - Color Palette
    struct Colors {
        // Dynamic colors that change with theme
        static var primary: Color { ThemeManager.shared.currentTheme.colors.primary }
        static var secondary: Color { ThemeManager.shared.currentTheme.colors.secondary }
        static var accent: Color { ThemeManager.shared.currentTheme.colors.accent }
        static var background: Color { ThemeManager.shared.currentTheme.colors.background }
        static var surface: Color { ThemeManager.shared.currentTheme.colors.surface }
        static var text: Color { ThemeManager.shared.currentTheme.colors.text }
        static var textSecondary: Color { ThemeManager.shared.currentTheme.colors.textSecondary }
        
        // Theme-aware aliases for existing color usage
        static var parchment: Color { background }
        static var ivory: Color { surface }
        static var paleBeige: Color { surface.opacity(0.8) }
        static var antiqueGold: Color { primary }
        static var chestnut: Color { secondary }
        static var burgundy: Color { accent }
        static var warmBlack: Color { text }
        static var sepia: Color { textSecondary }
        static var slateGray: Color { textSecondary.opacity(0.8) }
        
        // Static book spine colors (these should remain consistent across themes)
        static let forestGreen = Color(red: 0.24, green: 0.31, blue: 0.18) // #3D4F2F
        static let navy = Color(red: 0.14, green: 0.20, blue: 0.29) // #24324A
        static let deepMaroon = Color(red: 0.42, green: 0.15, blue: 0.15) // #6B2626
        static let mahogany = Color(red: 0.29, green: 0.18, blue: 0.09) // #4B2E16
        static let walnut = Color(red: 0.45, green: 0.31, blue: 0.20) // #734F33
        static let warmGold = Color(red: 0.85, green: 0.70, blue: 0.30) // #D9B34D
        
        // UI States
        static let softShadow = Color.black.opacity(0.1)
        static let cardShadow = Color.black.opacity(0.08)
        static let warmOverlay = Color.black.opacity(0.6)
    }
    
    // MARK: - Typography
    struct Typography {
        // Primary serif fonts
        static let titleLarge = Font.custom("Georgia", size: 32).weight(.medium)
        static let titleMedium = Font.custom("Georgia", size: 24).weight(.medium)
        static let titleSmall = Font.custom("Georgia", size: 20).weight(.medium)
        
        static let headlineLarge = Font.custom("Baskerville", size: 22).weight(.semibold)
        static let headlineMedium = Font.custom("Baskerville", size: 18).weight(.semibold)
        static let headlineSmall = Font.custom("Baskerville", size: 16).weight(.semibold)
        
        // Secondary sans-serif fonts
        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
        
        static let labelLarge = Font.system(size: 16, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 14, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 12, weight: .medium, design: .default)
        
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    // MARK: - Shadow Styles
    struct Shadows {
        static let soft = (color: Colors.softShadow, radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let card = (color: Colors.cardShadow, radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let book = (color: Colors.softShadow, radius: CGFloat(6), x: CGFloat(2), y: CGFloat(4))
    }

    // MARK: - Utilities
    static func bookSpineColor(for book: Book) -> Color {
        let colors = [
            Colors.burgundy,
            Colors.forestGreen,
            Colors.navy,
            Colors.deepMaroon,
            Colors.chestnut
        ]

        let hash = book.title?.hashValue ?? 0
        return colors[abs(hash) % colors.count]
    }
}

// MARK: - Custom Modifiers
extension View {
    func bookShadow() -> some View {
        self.shadow(
            color: ShelvesDesign.Shadows.book.color,
            radius: ShelvesDesign.Shadows.book.radius,
            x: ShelvesDesign.Shadows.book.x,
            y: ShelvesDesign.Shadows.book.y
        )
    }
    
    func cardShadow() -> some View {
        self.shadow(
            color: ShelvesDesign.Shadows.card.color,
            radius: ShelvesDesign.Shadows.card.radius,
            x: ShelvesDesign.Shadows.card.x,
            y: ShelvesDesign.Shadows.card.y
        )
    }
    
    func softShadow() -> some View {
        self.shadow(
            color: ShelvesDesign.Shadows.soft.color,
            radius: ShelvesDesign.Shadows.soft.radius,
            x: ShelvesDesign.Shadows.soft.x,
            y: ShelvesDesign.Shadows.soft.y
        )
    }
    
}

// MARK: - Background Textures
struct BookshelfBackground: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            // Subtle texture effect based on theme
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: textureColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.3), value: themeManager.currentTheme)
    }
    
    private var gradientColors: [Color] {
        switch themeManager.currentTheme {
        case .midnight:
            return [
                ShelvesDesign.Colors.background,
                ShelvesDesign.Colors.surface
            ]
        default:
            return [
                ShelvesDesign.Colors.background,
                ShelvesDesign.Colors.surface.opacity(0.8)
            ]
        }
    }
    
    private var textureColors: [Color] {
        switch themeManager.currentTheme {
        case .midnight:
            return [
                ShelvesDesign.Colors.primary.opacity(0.03),
                Color.clear,
                ShelvesDesign.Colors.secondary.opacity(0.02)
            ]
        default:
            return [
                ShelvesDesign.Colors.secondary.opacity(0.02),
                Color.clear,
                ShelvesDesign.Colors.mahogany.opacity(0.01)
            ]
        }
    }
}

struct WarmCardBackground: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.medium)
            .fill(ShelvesDesign.Colors.surface)
            .cardShadow()
            .animation(.easeInOut(duration: 0.2), value: themeManager.currentTheme)
    }
}