import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager
    @State private var exportFormat: ExportFormat = .csv
    @State private var showingLibraryManagement = false
    @State private var showingDuplicateDetection = false
    @State private var showingExportSheet = false
    @State private var showingBackupAlert = false
    @State private var isExporting = false
    @State private var showingTestDataAlert = false
    @State private var showingClearDataAlert = false
    @State private var showingBulkImport = false
    @State private var showingReadingReminderSettings = false
    
    // Development settings - can be disabled for production
    private let isDevelopmentMode = true
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.title, ascending: true)],
        animation: .default)
    private var books: FetchedResults<Book>
    
    
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
                            
                            // Development section (only shown in development mode)
                            if isDevelopmentMode {
                                developmentSection
                            }
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
                        .foregroundColor(ShelvesDesign.Colors.text)
                    
                    VStack(spacing: ShelvesDesign.Spacing.sm) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            ThemeOption(
                                theme: theme,
                                isSelected: themeManager.currentTheme == theme
                            ) {
                                themeManager.currentTheme = theme
                            }
                        }
                    }
                }
                
                Divider()
                    .background(ShelvesDesign.Colors.paleBeige)
                
                // Notifications
                SettingsButton(
                    title: "Reading Reminders",
                    subtitle: "Configure reading notifications",
                    icon: "bell.fill"
                ) {
                    showingReadingReminderSettings = true
                }
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
                    showingLibraryManagement = true
                }
                
                SettingsButton(
                    title: "Import Books",
                    subtitle: "Bulk import from file or service",
                    icon: "square.and.arrow.down"
                ) {
                    showingBulkImport = true
                }
                
                SettingsButton(
                    title: "Duplicate Detection",
                    subtitle: "Find and merge duplicate entries",
                    icon: "doc.on.doc"
                ) {
                    showingDuplicateDetection = true
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
                    isOn: $themeManager.autoBackupEnabled
                )
                
                Divider()
                    .background(ShelvesDesign.Colors.paleBeige)
                
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
                    Text("Export Format")
                        .font(ShelvesDesign.Typography.headlineSmall)
                        .foregroundColor(ShelvesDesign.Colors.text)
                    
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
                    showingExportSheet = true
                }
                
                SettingsButton(
                    title: "Backup Now",
                    subtitle: "Create manual backup",
                    icon: "icloud.and.arrow.up"
                ) {
                    performManualBackup()
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
                    checkForUpdates()
                }
                
                SettingsButton(
                    title: "Help & Support",
                    subtitle: "Get help using Shelves",
                    icon: "questionmark.circle"
                ) {
                    openHelpAndSupport()
                }
                
                SettingsButton(
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    icon: "hand.raised"
                ) {
                    openPrivacyPolicy()
                }
                
                SettingsButton(
                    title: "Rate Shelves",
                    subtitle: "Share your thoughts on the App Store",
                    icon: "star"
                ) {
                    rateApp()
                }
            }
        }
        .sheet(isPresented: $showingLibraryManagement) {
            LibraryManagementView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingDuplicateDetection) {
            DuplicateDetectionView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingBulkImport) {
            BulkImportView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingReadingReminderSettings) {
            ReadingReminderSettingsView()
                .environmentObject(themeManager)
        }
        .confirmationDialog("Export Library", isPresented: $showingExportSheet) {
            Button("Export as CSV") { exportLibrary(format: .csv) }
            Button("Export as JSON") { exportLibrary(format: .json) }
            Button("Export as PDF") { exportLibrary(format: .pdf) }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Backup Complete", isPresented: $showingBackupAlert) {
            Button("OK") { }
        } message: {
            Text("Your library has been backed up successfully.")
        }
    }
    
    private var developmentSection: some View {
        SettingsCard(
            title: "Development Tools",
            subtitle: "Testing and development utilities",
            icon: "hammer.fill",
            iconColor: Color.orange
        ) {
            VStack(spacing: ShelvesDesign.Spacing.md) {
                // Book count display
                HStack {
                    VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                        Text("Current Library Size")
                            .font(ShelvesDesign.Typography.labelLarge)
                            .foregroundColor(ShelvesDesign.Colors.text)
                        
                        Text("\(books.count) books in library")
                            .font(ShelvesDesign.Typography.bodySmall)
                            .foregroundColor(ShelvesDesign.Colors.sepia)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, ShelvesDesign.Spacing.sm)
                
                Divider()
                    .background(ShelvesDesign.Colors.paleBeige)
                
                SettingsButton(
                    title: "Populate Test Library",
                    subtitle: "Add 100 sample books for testing",
                    icon: "books.vertical"
                ) {
                    showingTestDataAlert = true
                }
                
                SettingsButton(
                    title: "Clear All Books",
                    subtitle: "Remove all books from library",
                    icon: "trash"
                ) {
                    showingClearDataAlert = true
                }
                
                // Library statistics
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text("Quick Stats")
                        .font(ShelvesDesign.Typography.headlineSmall)
                        .foregroundColor(ShelvesDesign.Colors.text)
                    
                    let readBooks = books.filter { $0.isRead }.count
                    let currentlyReading = books.filter { $0.currentlyReading }.count
                    let genres = Set(books.compactMap { $0.genre }).count
                    let libraries = Set(books.compactMap { $0.libraryName }).count
                    
                    HStack {
                        StatItem(label: "Read", value: "\(readBooks)")
                        StatItem(label: "Reading", value: "\(currentlyReading)")
                        StatItem(label: "Genres", value: "\(genres)")
                        StatItem(label: "Libraries", value: "\(libraries)")
                    }
                }
            }
        }
        .alert("Populate Test Library", isPresented: $showingTestDataAlert) {
            Button("Populate", role: .destructive) {
                populateTestLibrary()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will replace all existing books with 100 test books across various genres. This action cannot be undone.")
        }
        .alert("Clear All Books", isPresented: $showingClearDataAlert) {
            Button("Clear All", role: .destructive) {
                clearAllBooks()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all books from your library. This action cannot be undone.")
        }
    }
    
    // MARK: - Action Methods
    
    private func exportLibrary(format: ExportFormat) {
        isExporting = true
        
        DispatchQueue.global(qos: .background).async {
            let allBooks = Array(books)
            if let fileURL = DataExportService.shared.exportLibrary(books: allBooks, format: format) {
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.shareFile(url: fileURL)
                }
            } else {
                DispatchQueue.main.async {
                    self.isExporting = false
                    print("Export failed")
                }
            }
        }
    }
    
    private func shareFile(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func performManualBackup() {
        DataExportService.shared.backupToiCloud()
        showingBackupAlert = true
    }
    
    private func checkForUpdates() {
        if let url = URL(string: "https://apps.apple.com/app/id1234567890") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openHelpAndSupport() {
        if let url = URL(string: "mailto:support@shelves.app?subject=Shelves%20Support") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://shelves.app/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    private func rateApp() {
        if let url = URL(string: "https://apps.apple.com/app/id1234567890?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Development Methods
    
    private func populateTestLibrary() {
        TestDataGenerator.shared.populateTestLibrary(context: viewContext)
    }
    
    private func clearAllBooks() {
        let request: NSFetchRequest<NSFetchRequestResult> = Book.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
            print("Successfully cleared all books")
        } catch {
            print("Failed to clear books: \(error)")
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
                        .foregroundColor(ShelvesDesign.Colors.text)
                    
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
                        .foregroundColor(ShelvesDesign.Colors.text)
                    
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
                    .foregroundColor(ShelvesDesign.Colors.text)
                
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
    let theme: AppTheme
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
                        .foregroundColor(ShelvesDesign.Colors.text)
                    
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
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ShelvesDesign.Spacing.md) {
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text(format.rawValue)
                        .font(ShelvesDesign.Typography.labelLarge)
                        .foregroundColor(ShelvesDesign.Colors.text)
                    
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

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: ShelvesDesign.Spacing.xs) {
            Text(value)
                .font(ShelvesDesign.Typography.headlineSmall)
                .foregroundColor(ShelvesDesign.Colors.antiqueGold)
            
            Text(label)
                .font(ShelvesDesign.Typography.bodySmall)
                .foregroundColor(ShelvesDesign.Colors.sepia)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}