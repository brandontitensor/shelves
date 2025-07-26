import SwiftUI

struct SettingsView: View {
    @State private var enableNotifications = true
    @State private var autoBackup = true
    @State private var selectedTheme: AppTheme = .classic
    @State private var exportFormat: ExportFormat = .csv
    
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
                return [ShelvesDesign.Colors.antiqueGold, ShelvesDesign.Colors.chestnut, ShelvesDesign.Colors.burgundy]
            case .midnight:
                return [Color.blue, Color.indigo, Color.cyan]
            case .autumn:
                return [Color.orange, Color.red, Color.yellow]
            }
        }
    }
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        case pdf = "PDF"
        
        var description: String {
            switch self {
            case .csv: return "Spreadsheet format"
            case .json: return "Data interchange format"
            case .pdf: return "Printable document"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            BookshelfBackground()
                .overlay(
                    ScrollView {
                        VStack(spacing: ShelvesDesign.Spacing.lg) {
                            personalizeSection
                            librarySection
                            dataSection
                            aboutSection
                        }
                        .padding(ShelvesDesign.Spacing.md)
                        .padding(.bottom, ShelvesDesign.Spacing.xl)
                    }
                )
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var personalizeSection: some View {
        SettingsCard(
            title: "Personalize",
            subtitle: "Customize your library experience",
            icon: "paintbrush.fill",
            iconColor: ShelvesDesign.Colors.antiqueGold
        ) {
            VStack(spacing: ShelvesDesign.Spacing.lg) {
                // Theme selection
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
                    Text("Theme")
                        .font(ShelvesDesign.Typography.headlineSmall)
                        .foregroundColor(ShelvesDesign.Colors.warmBlack)
                    
                    VStack(spacing: ShelvesDesign.Spacing.sm) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            ThemeOption(
                                theme: theme,
                                isSelected: selectedTheme == theme
                            ) {
                                selectedTheme = theme
                            }
                        }
                    }
                }
                
                Divider()
                    .background(ShelvesDesign.Colors.paleBeige)
                
                // Notifications
                SettingsToggle(
                    title: "Reading Reminders",
                    subtitle: "Get gentle nudges to read",
                    isOn: $enableNotifications
                )
            }
        }
    }
    
    private var librarySection: some View {
        SettingsCard(
            title: "Library Management",
            subtitle: "Organize and maintain your collection",
            icon: "books.vertical.fill",
            iconColor: ShelvesDesign.Colors.forestGreen
        ) {
            VStack(spacing: ShelvesDesign.Spacing.md) {
                SettingsButton(
                    title: "Manage Libraries",
                    subtitle: "Add or edit your library locations",
                    icon: "house.fill"
                ) {
                    // Navigate to library management
                }
                
                SettingsButton(
                    title: "Import Books",
                    subtitle: "Bulk import from file or service",
                    icon: "square.and.arrow.down"
                ) {
                    // Navigate to import options
                }
                
                SettingsButton(
                    title: "Duplicate Detection",
                    subtitle: "Find and merge duplicate entries",
                    icon: "doc.on.doc"
                ) {
                    // Run duplicate detection
                }
            }
        }
    }
    
    private var dataSection: some View {
        SettingsCard(
            title: "Data & Backup",
            subtitle: "Keep your library safe and portable",
            icon: "externaldrive.fill",
            iconColor: ShelvesDesign.Colors.burgundy
        ) {
            VStack(spacing: ShelvesDesign.Spacing.md) {
                SettingsToggle(
                    title: "Auto Backup",
                    subtitle: "Automatically backup to iCloud",
                    isOn: $autoBackup
                )
                
                Divider()
                    .background(ShelvesDesign.Colors.paleBeige)
                
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
                    Text("Export Format")
                        .font(ShelvesDesign.Typography.headlineSmall)
                        .foregroundColor(ShelvesDesign.Colors.warmBlack)
                    
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        ExportFormatOption(
                            format: format,
                            isSelected: exportFormat == format
                        ) {
                            exportFormat = format
                        }
                    }
                }
                
                Divider()
                    .background(ShelvesDesign.Colors.paleBeige)
                
                SettingsButton(
                    title: "Export Library",
                    subtitle: "Download your complete collection",
                    icon: "square.and.arrow.up"
                ) {
                    // Export library
                }
                
                SettingsButton(
                    title: "Backup Now",
                    subtitle: "Create manual backup",
                    icon: "icloud.and.arrow.up"
                ) {
                    // Manual backup
                }
            }
        }
    }
    
    private var aboutSection: some View {
        SettingsCard(
            title: "About Shelves",
            subtitle: "App information and support",
            icon: "info.circle.fill",
            iconColor: ShelvesDesign.Colors.chestnut
        ) {
            VStack(spacing: ShelvesDesign.Spacing.md) {
                SettingsButton(
                    title: "Version 1.0.0",
                    subtitle: "Check for updates",
                    icon: "arrow.triangle.2.circlepath"
                ) {
                    // Check for updates
                }
                
                SettingsButton(
                    title: "Help & Support",
                    subtitle: "Get help using Shelves",
                    icon: "questionmark.circle"
                ) {
                    // Open help
                }
                
                SettingsButton(
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    icon: "hand.raised"
                ) {
                    // Open privacy policy
                }
                
                SettingsButton(
                    title: "Rate Shelves",
                    subtitle: "Share your thoughts on the App Store",
                    icon: "star"
                ) {
                    // Rate app
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.lg) {
            // Header
            HStack(spacing: ShelvesDesign.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text(title)
                        .font(ShelvesDesign.Typography.headlineMedium)
                        .foregroundColor(ShelvesDesign.Colors.warmBlack)
                    
                    Text(subtitle)
                        .font(ShelvesDesign.Typography.bodyMedium)
                        .foregroundColor(ShelvesDesign.Colors.sepia)
                }
                
                Spacer()
            }
            
            // Content
            content
        }
        .padding(ShelvesDesign.Spacing.lg)
        .background(
            WarmCardBackground()
        )
    }
}

struct SettingsButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ShelvesDesign.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(ShelvesDesign.Colors.chestnut)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text(title)
                        .font(ShelvesDesign.Typography.labelLarge)
                        .foregroundColor(ShelvesDesign.Colors.warmBlack)
                    
                    Text(subtitle)
                        .font(ShelvesDesign.Typography.bodySmall)
                        .foregroundColor(ShelvesDesign.Colors.sepia)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ShelvesDesign.Colors.slateGray.opacity(0.6))
            }
            .padding(.vertical, ShelvesDesign.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: ShelvesDesign.Spacing.md) {
            VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                Text(title)
                    .font(ShelvesDesign.Typography.labelLarge)
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                
                Text(subtitle)
                    .font(ShelvesDesign.Typography.bodySmall)
                    .foregroundColor(ShelvesDesign.Colors.sepia)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(ShelvesDesign.Colors.antiqueGold)
        }
        .padding(.vertical, ShelvesDesign.Spacing.sm)
    }
}

struct ThemeOption: View {
    let theme: SettingsView.AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ShelvesDesign.Spacing.md) {
                // Theme preview
                HStack(spacing: 2) {
                    ForEach(Array(theme.previewColors.enumerated()), id: \.offset) { index, color in
                        Circle()
                            .fill(color)
                            .frame(width: 12, height: 12)
                    }
                }
                
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text(theme.rawValue)
                        .font(ShelvesDesign.Typography.labelLarge)
                        .foregroundColor(ShelvesDesign.Colors.warmBlack)
                    
                    Text(theme.description)
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

struct ExportFormatOption: View {
    let format: SettingsView.ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ShelvesDesign.Spacing.md) {
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text(format.rawValue)
                        .font(ShelvesDesign.Typography.labelLarge)
                        .foregroundColor(ShelvesDesign.Colors.warmBlack)
                    
                    Text(format.description)
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

#Preview {
    SettingsView()
}