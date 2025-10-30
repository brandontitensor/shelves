import SwiftUI

// MARK: - Bookplate Style
enum BookplateStyle: String, CaseIterable {
    case classic = "Classic"
    case modern = "Modern"
    case elegant = "Elegant"

    var description: String {
        switch self {
        case .classic:
            return "Traditional ornate frame"
        case .modern:
            return "Clean, minimalist design"
        case .elegant:
            return "Decorative corners"
        }
    }
}

// MARK: - Bookplate View
struct BookplateView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let userName: String
    let style: BookplateStyle
    let showBorder: Bool

    init(userName: String, style: BookplateStyle = .classic, showBorder: Bool = true) {
        self.userName = userName
        self.style = style
        self.showBorder = showBorder
    }

    var displayText: String {
        if userName.isEmpty {
            return "Your Library"
        } else {
            return userName.hasSuffix("s") ? "\(userName)' Library" : "\(userName)'s Library"
        }
    }

    var body: some View {
        VStack(spacing: ShelvesDesign.Spacing.xs) {
            Text("EX LIBRIS")
                .font(.system(size: 10, weight: .medium, design: .serif))
                .tracking(2)
                .foregroundColor(ShelvesDesign.Colors.textSecondary)

            Text(displayText)
                .font(ShelvesDesign.Typography.titleMedium)
                .foregroundColor(ShelvesDesign.Colors.text)
        }
        .padding(.vertical, ShelvesDesign.Spacing.md)
        .padding(.horizontal, ShelvesDesign.Spacing.lg)
        .background(
            bookplateBackground
        )
    }

    @ViewBuilder
    private var bookplateBackground: some View {
        switch style {
        case .classic:
            classicFrame
        case .modern:
            modernFrame
        case .elegant:
            elegantFrame
        }
    }

    // Classic ornate frame
    private var classicFrame: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(ShelvesDesign.Colors.surface.opacity(0.95))

            // Ornate border
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            ShelvesDesign.Colors.antiqueGold,
                            ShelvesDesign.Colors.chestnut,
                            ShelvesDesign.Colors.antiqueGold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )

            // Inner decorative border
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(ShelvesDesign.Colors.antiqueGold.opacity(0.3), lineWidth: 1)
                .padding(4)

            // Corner decorations
            VStack {
                HStack {
                    cornerOrnament
                    Spacer()
                    cornerOrnament
                }
                Spacer()
                HStack {
                    cornerOrnament
                        .rotationEffect(.degrees(90))
                    Spacer()
                    cornerOrnament
                        .rotationEffect(.degrees(90))
                }
            }
            .padding(8)
        }
    }

    // Modern minimalist frame
    private var modernFrame: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 2)
                .fill(ShelvesDesign.Colors.surface.opacity(0.95))

            // Simple border
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(ShelvesDesign.Colors.text.opacity(0.4), lineWidth: 1)

            // Accent line at bottom
            VStack {
                Spacer()
                Rectangle()
                    .fill(ShelvesDesign.Colors.antiqueGold)
                    .frame(height: 2)
            }
        }
    }

    // Elegant decorative corners
    private var elegantFrame: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(ShelvesDesign.Colors.surface.opacity(0.95))

            // Subtle border
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(ShelvesDesign.Colors.chestnut.opacity(0.3), lineWidth: 1)

            // Corner decorations - simple L-shapes
            VStack {
                HStack {
                    elegantCorner
                    Spacer()
                    elegantCorner
                        .rotationEffect(.degrees(90))
                }
                Spacer()
                HStack {
                    elegantCorner
                        .rotationEffect(.degrees(-90))
                    Spacer()
                    elegantCorner
                        .rotationEffect(.degrees(180))
                }
            }
            .padding(10)
        }
    }

    // Corner ornament for classic style
    private var cornerOrnament: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 12))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 12, y: 0))
        }
        .stroke(ShelvesDesign.Colors.antiqueGold, lineWidth: 1.5)
        .frame(width: 12, height: 12)
    }

    // Corner decoration for elegant style
    private var elegantCorner: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(ShelvesDesign.Colors.chestnut)
                .frame(width: 16, height: 1)
            Rectangle()
                .fill(ShelvesDesign.Colors.chestnut)
                .frame(width: 1, height: 16)
        }
    }
}

// MARK: - Bookplate Style Selector (for Settings)
struct BookplateStyleOption: View {
    @EnvironmentObject var themeManager: ThemeManager
    let style: BookplateStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ShelvesDesign.Spacing.md) {
                // Style preview
                BookplateView(userName: "Library", style: style, showBorder: true)
                    .frame(width: 120, height: 60)
                    .scaleEffect(0.7)

                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text(style.rawValue)
                        .font(ShelvesDesign.Typography.labelLarge)
                        .foregroundColor(ShelvesDesign.Colors.text)

                    Text(style.description)
                        .font(ShelvesDesign.Typography.bodySmall)
                        .foregroundColor(ShelvesDesign.Colors.sepia)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ShelvesDesign.Colors.antiqueGold)
                } else {
                    Circle()
                        .stroke(ShelvesDesign.Colors.slateGray.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.vertical, ShelvesDesign.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: ShelvesDesign.Spacing.xl) {
        BookplateView(userName: "Brandon", style: .classic)
        BookplateView(userName: "Brandon", style: .modern)
        BookplateView(userName: "Brandon", style: .elegant)
    }
    .padding()
    .background(BookshelfBackground())
}
