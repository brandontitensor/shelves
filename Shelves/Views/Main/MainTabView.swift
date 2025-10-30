import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                    Text("Home")
                }
                .tag(0)

            // Add Book Tab (Central/Prominent)
            AddBookTabView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Add Book")
                }
                .tag(1)

            // Library Tab
            LibraryView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "books.vertical.fill" : "books.vertical")
                        .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                    Text("Library")
                }
                .tag(2)
        }
        .accentColor(ShelvesDesign.Colors.primary)
        .background(ShelvesDesign.Colors.background)
        .onAppear {
            #if canImport(UIKit)
            updateTabBarAppearance()
            #endif
        }
        .onChange(of: themeManager.currentTheme) { _, _ in
            #if canImport(UIKit)
            updateTabBarAppearance()
            #endif
        }
    }

    #if canImport(UIKit)
    private func updateTabBarAppearance() {
        DispatchQueue.main.async {
            // Customize tab bar appearance
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(ShelvesDesign.Colors.surface)
            tabBarAppearance.selectionIndicatorTintColor = UIColor(ShelvesDesign.Colors.primary)

            // Normal state
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(ShelvesDesign.Colors.secondary)
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(ShelvesDesign.Colors.textSecondary),
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]

            // Selected state
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(ShelvesDesign.Colors.primary)
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(ShelvesDesign.Colors.primary),
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]

            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

            // Customize navigation bar appearance
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = UIColor(ShelvesDesign.Colors.background)
            navBarAppearance.titleTextAttributes = [
                .foregroundColor: UIColor(ShelvesDesign.Colors.text),
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
            navBarAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor(ShelvesDesign.Colors.text),
                .font: UIFont.systemFont(ofSize: 34, weight: .bold)
            ]

            UINavigationBar.appearance().standardAppearance = navBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
            UINavigationBar.appearance().compactAppearance = navBarAppearance

            // Force immediate update of all existing UI elements
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                for window in windowScene.windows {
                    // Recursively find and update all navigation bars
                    updateNavigationBarsRecursively(viewController: window.rootViewController, appearance: navBarAppearance)

                    // Also search the entire view hierarchy for navigation bars
                    updateNavigationBarsInViewHierarchy(view: window, appearance: navBarAppearance)
                }
            }
        }
    }

    private func updateNavigationBarsRecursively(viewController: UIViewController?, appearance: UINavigationBarAppearance) {
        guard let viewController = viewController else { return }

        if let navigationController = viewController as? UINavigationController {
            // Directly set the appearance on this navigation bar
            navigationController.navigationBar.standardAppearance = appearance
            navigationController.navigationBar.scrollEdgeAppearance = appearance
            navigationController.navigationBar.compactAppearance = appearance

            // Force immediate layout update
            navigationController.navigationBar.setNeedsLayout()
            navigationController.navigationBar.layoutIfNeeded()

            for childVC in navigationController.viewControllers {
                updateNavigationBarsRecursively(viewController: childVC, appearance: appearance)
            }
        } else if let tabBarController = viewController as? UITabBarController {
            for childVC in tabBarController.viewControllers ?? [] {
                updateNavigationBarsRecursively(viewController: childVC, appearance: appearance)
            }
        }

        for childVC in viewController.children {
            updateNavigationBarsRecursively(viewController: childVC, appearance: appearance)
        }
    }

    private func updateNavigationBarsInViewHierarchy(view: UIView, appearance: UINavigationBarAppearance) {
        // Check if this view is a navigation bar
        if let navigationBar = view as? UINavigationBar {
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
            navigationBar.setNeedsLayout()
            navigationBar.layoutIfNeeded()
        }

        // Recursively check all subviews
        for subview in view.subviews {
            updateNavigationBarsInViewHierarchy(view: subview, appearance: appearance)
        }
    }
    #endif
}

// MARK: - Add Book Tab View
struct AddBookTabView: View {
    @State private var showingScanner = false
    @State private var showingCoverScanner = false
    @State private var showingManualAdd = false
    @State private var showingSearchResults = false
    @State private var showingFAQ = false
    @State private var scannedCode: String?
    @State private var searchResults: [BookSearchResult]?
    @State private var selectedBook: BookSearchResult?

    var body: some View {
        mainContent
            .modifier(SheetsModifier(
                showingScanner: $showingScanner,
                showingCoverScanner: $showingCoverScanner,
                showingSearchResults: $showingSearchResults,
                showingManualAdd: $showingManualAdd,
                showingFAQ: $showingFAQ,
                scannedCode: $scannedCode,
                searchResults: $searchResults,
                selectedBook: $selectedBook
            ))
    }

    private var mainContent: some View {
        NavigationStack {
            BookshelfBackground()
                .overlay(contentOverlay)
                .navigationTitle("Add Book")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var contentOverlay: some View {
        VStack(spacing: ShelvesDesign.Spacing.xl) {
            Spacer()
            logoArea
            Spacer()
            VStack(spacing: ShelvesDesign.Spacing.md) {
                actionButtons

                // FAQ button
                Button(action: {
                    showingFAQ = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 14))
                        Text("How to use these options")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(ShelvesDesign.Colors.sepia)
                }
                .padding(.top, 8)
            }
            Spacer()
        }
    }

    private var logoArea: some View {
        VStack(spacing: ShelvesDesign.Spacing.md) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 64))
                .foregroundColor(ShelvesDesign.Colors.antiqueGold)
                .softShadow()

            Text("Add to Your Collection")
                .font(ShelvesDesign.Typography.titleMedium)
                .foregroundColor(ShelvesDesign.Colors.sepia)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: ShelvesDesign.Spacing.lg) {
            #if canImport(UIKit)
            AddBookButton(
                title: "Scan Barcode",
                subtitle: "Quick capture with camera",
                icon: "barcode.viewfinder",
                color: ShelvesDesign.Colors.forestGreen
            ) {
                showingScanner = true
            }

            AddBookButton(
                title: "Scan Cover or Spine",
                subtitle: "Identify book from cover",
                icon: "text.viewfinder",
                color: ShelvesDesign.Colors.navy
            ) {
                showingCoverScanner = true
            }
            #endif

            AddBookButton(
                title: "Add Manually",
                subtitle: "Enter details by hand",
                icon: "square.and.pencil",
                color: ShelvesDesign.Colors.burgundy
            ) {
                showingManualAdd = true
            }
        }
        .padding(.horizontal, ShelvesDesign.Spacing.xl)
    }
}

// MARK: - Sheets Modifier
private struct SheetsModifier: ViewModifier {
    @Binding var showingScanner: Bool
    @Binding var showingCoverScanner: Bool
    @Binding var showingSearchResults: Bool
    @Binding var showingManualAdd: Bool
    @Binding var showingFAQ: Bool
    @Binding var scannedCode: String?
    @Binding var searchResults: [BookSearchResult]?
    @Binding var selectedBook: BookSearchResult?

    func body(content: Content) -> some View {
        #if canImport(UIKit)
        content
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView(scannedCode: $scannedCode, isPresented: $showingScanner)
            }
            .sheet(isPresented: $showingCoverScanner) {
                CoverScannerView(searchResults: $searchResults, isPresented: $showingCoverScanner)
            }
            .sheet(isPresented: $showingSearchResults) {
                if let results = searchResults {
                    BookSearchResultsView(searchResults: results) { selectedResult in
                        selectedBook = selectedResult
                        showingManualAdd = true
                    }
                }
            }
            .sheet(isPresented: $showingManualAdd) {
                if let book = selectedBook {
                    AddBookView(
                        isbn: book.isbn,
                        prefillTitle: book.title,
                        prefillAuthor: book.author
                    )
                } else {
                    AddBookView(isbn: scannedCode, prefillTitle: nil, prefillAuthor: nil)
                }
            }
            .sheet(isPresented: $showingFAQ) {
                AddBookFAQView()
            }
            .onChange(of: scannedCode) { _, isbn in
                if isbn != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingManualAdd = true
                    }
                }
            }
            .onChange(of: searchResults) { _, results in
                if results != nil && !results!.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingSearchResults = true
                    }
                }
            }
            .onChange(of: showingManualAdd) { _, isShowing in
                if !isShowing {
                    selectedBook = nil
                }
            }
        #else
        content
            .sheet(isPresented: $showingSearchResults) {
                if let results = searchResults {
                    BookSearchResultsView(searchResults: results) { selectedResult in
                        selectedBook = selectedResult
                        showingManualAdd = true
                    }
                }
            }
            .sheet(isPresented: $showingManualAdd) {
                if let book = selectedBook {
                    AddBookView(
                        isbn: book.isbn,
                        prefillTitle: book.title,
                        prefillAuthor: book.author
                    )
                } else {
                    AddBookView(isbn: scannedCode, prefillTitle: nil, prefillAuthor: nil)
                }
            }
            .sheet(isPresented: $showingFAQ) {
                AddBookFAQView()
            }
            .onChange(of: scannedCode) { _, isbn in
                if isbn != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingManualAdd = true
                    }
                }
            }
            .onChange(of: searchResults) { _, results in
                if results != nil && !results!.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingSearchResults = true
                    }
                }
            }
            .onChange(of: showingManualAdd) { _, isShowing in
                if !isShowing {
                    selectedBook = nil
                }
            }
        #endif
    }
}

// MARK: - Add Book Button Component
struct AddBookButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ShelvesDesign.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Text
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text(title)
                        .font(ShelvesDesign.Typography.headlineMedium)
                        .foregroundColor(ShelvesDesign.Colors.text)
                    
                    Text(subtitle)
                        .font(ShelvesDesign.Typography.bodyMedium)
                        .foregroundColor(ShelvesDesign.Colors.sepia)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ShelvesDesign.Colors.chestnut)
            }
            .padding(ShelvesDesign.Spacing.lg)
            .background(
                WarmCardBackground()
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Book FAQ View
struct AddBookFAQView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(ShelvesDesign.Colors.primary)

                        Text("How to Add Books")
                            .font(ShelvesDesign.Typography.titleLarge)
                            .foregroundColor(ShelvesDesign.Colors.text)

                        Text("Choose the method that works best for you")
                            .font(ShelvesDesign.Typography.bodyMedium)
                            .foregroundColor(ShelvesDesign.Colors.sepia)
                    }
                    .padding(.bottom, 8)

                    // Scan Barcode Section
                    #if canImport(UIKit)
                    FAQCard(
                        icon: "barcode.viewfinder",
                        color: ShelvesDesign.Colors.forestGreen,
                        title: "Scan Barcode",
                        description: "Point your camera at the ISBN barcode on the back of the book.",
                        tips: [
                            "Works best with good lighting",
                            "Hold steady until the barcode is detected",
                            "Book information will load automatically"
                        ]
                    )

                    // Scan Cover Section
                    FAQCard(
                        icon: "text.viewfinder",
                        color: ShelvesDesign.Colors.navy,
                        title: "Scan Cover or Spine",
                        description: "Capture a photo of the book cover or spine to identify the book by its title.",
                        tips: [
                            "Position title clearly in the frame",
                            "Ensure text is readable and well-lit",
                            "Tap the capture button when ready",
                            "You'll see search results to choose from"
                        ]
                    )
                    #endif

                    // Add Manually Section
                    FAQCard(
                        icon: "square.and.pencil",
                        color: ShelvesDesign.Colors.burgundy,
                        title: "Add Manually",
                        description: "Enter book details by hand if scanning doesn't work.",
                        tips: [
                            "Only the title is required",
                            "Add as much detail as you like",
                            "Perfect for rare or old books",
                            "You can add custom cover photos"
                        ]
                    )
                }
                .padding()
            }
            .background(ShelvesDesign.Colors.parchment)
            .navigationTitle("How to Add Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ShelvesDesign.Colors.primary)
                }
            }
        }
    }
}

// MARK: - FAQ Card Component
struct FAQCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let tips: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(ShelvesDesign.Typography.headlineMedium)
                    .foregroundColor(ShelvesDesign.Colors.text)
            }

            // Description
            Text(description)
                .font(ShelvesDesign.Typography.bodyMedium)
                .foregroundColor(ShelvesDesign.Colors.sepia)
                .fixedSize(horizontal: false, vertical: true)

            // Tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Tips:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ShelvesDesign.Colors.chestnut)

                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(color)
                        Text(tip)
                            .font(.system(size: 14))
                            .foregroundColor(ShelvesDesign.Colors.sepia)
                    }
                }
            }
        }
        .padding()
        .background(
            WarmCardBackground()
        )
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}