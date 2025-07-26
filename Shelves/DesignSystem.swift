import SwiftUI

// MARK: - Design System for Shelves App
// Theme: Classic, Timeless, Rich, and Homey Library

struct ShelvesDesign {
    
    // MARK: - Color Palette
    struct Colors {
        // Main backgrounds
        static let parchment = Color(red: 0.97, green: 0.96, blue: 0.94) // #F8F5EF
        static let ivory = Color(red: 0.99, green: 0.99, blue: 0.96) // #FCFCF5
        static let paleBeige = Color(red: 0.96, green: 0.94, blue: 0.90) // #F5F0E6
        
        // Wood tones
        static let mahogany = Color(red: 0.29, green: 0.18, blue: 0.09) // #4B2E16
        static let chestnut = Color(red: 0.57, green: 0.37, blue: 0.22) // #915E38
        static let walnut = Color(red: 0.45, green: 0.31, blue: 0.20) // #734F33
        
        // Accent colors
        static let antiqueGold = Color(red: 0.79, green: 0.64, blue: 0.26) // #C9A442
        static let warmGold = Color(red: 0.85, green: 0.70, blue: 0.30) // #D9B34D
        
        // Book colors
        static let burgundy = Color(red: 0.50, green: 0.11, blue: 0.10) // #801B1A
        static let forestGreen = Color(red: 0.24, green: 0.31, blue: 0.18) // #3D4F2F
        static let navy = Color(red: 0.14, green: 0.20, blue: 0.29) // #24324A
        static let deepMaroon = Color(red: 0.42, green: 0.15, blue: 0.15) // #6B2626
        
        // Text colors
        static let slateGray = Color(red: 0.25, green: 0.25, blue: 0.25) // #404040
        static let sepia = Color(red: 0.35, green: 0.29, blue: 0.24) // #594A3D
        static let warmBlack = Color(red: 0.12, green: 0.10, blue: 0.08) // #1F1A14
        
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
    var body: some View {
        LinearGradient(
            colors: [
                ShelvesDesign.Colors.parchment,
                ShelvesDesign.Colors.paleBeige.opacity(0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            // Subtle wood grain texture effect
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            ShelvesDesign.Colors.chestnut.opacity(0.02),
                            Color.clear,
                            ShelvesDesign.Colors.mahogany.opacity(0.01)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .ignoresSafeArea()
    }
}

struct WarmCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.medium)
            .fill(ShelvesDesign.Colors.ivory)
            .cardShadow()
    }
}