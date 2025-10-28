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
            
            // Library Tab
            LibraryView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "books.vertical.fill" : "books.vertical")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                    Text("Library")
                }
                .tag(1)
            
            // Add Book Tab (Central/Prominent)
            AddBookTabView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Add Book")
                }
                .tag(2)
            
            // Search Tab
            SearchView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "magnifyingglass" : "magnifyingglass")
                    Text("Search")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                        .environment(\.symbolVariants, selectedTab == 4 ? .fill : .none)
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(ShelvesDesign.Colors.primary)
        .background(ShelvesDesign.Colors.background)
        .onAppear {
            updateTabBarAppearance()
        }
        .onChange(of: themeManager.currentTheme) { _, _ in
            updateTabBarAppearance()
        }
    }
    
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
                    for view in window.subviews {
                        view.setNeedsDisplay()
                    }
                    // Force navigation bars to update
                    window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                    if let navController = window.rootViewController as? UINavigationController {
                        navController.navigationBar.setNeedsLayout()
                        navController.navigationBar.layoutIfNeeded()
                    }
                    // Recursively update all navigation controllers
                    updateNavigationBarsRecursively(viewController: window.rootViewController)
                }
            }
        }
    }
    
    private func updateNavigationBarsRecursively(viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        
        if let navigationController = viewController as? UINavigationController {
            navigationController.navigationBar.setNeedsLayout()
            navigationController.navigationBar.layoutIfNeeded()
            for childVC in navigationController.viewControllers {
                updateNavigationBarsRecursively(viewController: childVC)
            }
        } else if let tabBarController = viewController as? UITabBarController {
            for childVC in tabBarController.viewControllers ?? [] {
                updateNavigationBarsRecursively(viewController: childVC)
            }
        }
        
        for childVC in viewController.children {
            updateNavigationBarsRecursively(viewController: childVC)
        }
    }
}

// MARK: - Add Book Tab View
struct AddBookTabView: View {
    @State private var showingScanner = false
    @State private var showingManualAdd = false
    @State private var scannedCode: String?
    
    var body: some View {
        NavigationStack {
            BookshelfBackground()
                .overlay(
                    VStack(spacing: ShelvesDesign.Spacing.xl) {
                        Spacer()
                        
                        // App Icon/Logo Area
                        VStack(spacing: ShelvesDesign.Spacing.md) {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 64))
                                .foregroundColor(ShelvesDesign.Colors.antiqueGold)
                                .softShadow()
                            
                            Text("Add to Your Collection")
                                .font(ShelvesDesign.Typography.titleMedium)
                                .foregroundColor(ShelvesDesign.Colors.sepia)
                        }
                        
                        Spacer()
                        
                        // Action Buttons
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
                        
                        Spacer()
                    }
                )
                .navigationTitle("Add Book")
                .navigationBarTitleDisplayMode(.inline)
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showingScanner) {
            BarcodeScannerView(scannedCode: $scannedCode, isPresented: $showingScanner)
        }
        #endif
        .sheet(isPresented: $showingManualAdd) {
            AddBookView(isbn: scannedCode)
        }
        .onChange(of: scannedCode) { _, isbn in
            if isbn != nil {
                // Delay showing AddBook sheet to ensure scanner sheet is fully dismissed first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingManualAdd = true
                }
            }
        }
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

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}