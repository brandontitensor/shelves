import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var showingNameInput = false
    
    private let onboardingPages = [
        OnboardingPage(
            title: "Welcome to Libris.",
            subtitle: "Ex Libris — From Your Library",
            description: "Create your personal digital bookplate and curate a collection that's uniquely yours. Organize, track, and cherish every book you own.",
            imageName: "books.vertical",
            primaryColor: Color(red: 0.79, green: 0.64, blue: 0.26)
        ),
        OnboardingPage(
            title: "Curate Your Collection",
            subtitle: "Libraries, rooms, and shelves",
            description: "Organize books by location, reading status, or genre. Create custom libraries that reflect how you truly organize your personal collection.",
            imageName: "house.fill",
            primaryColor: Color(red: 0.57, green: 0.37, blue: 0.22)
        ),
        OnboardingPage(
            title: "Your Reading Journey",
            subtitle: "Progress, notes, and memories",
            description: "Add personal inscriptions and notes to each book. Track your reading journey and preserve the stories behind your collection.",
            imageName: "chart.line.uptrend.xyaxis",
            primaryColor: Color(red: 0.50, green: 0.11, blue: 0.10)
        ),
        OnboardingPage(
            title: "Quick & Easy Adding",
            subtitle: "Scan, search, or manual entry",
            description: "Add books by scanning barcodes, searching by ISBN, or entering details manually. Cover art and metadata are fetched automatically.",
            imageName: "barcode.viewfinder",
            primaryColor: Color(red: 0.24, green: 0.31, blue: 0.18)
        )
    ]
    
    var body: some View {
        ZStack {
            BookshelfBackground()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(onboardingPages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Bottom section
                VStack(spacing: ShelvesDesign.Spacing.lg) {
                    // Page indicator
                    HStack(spacing: ShelvesDesign.Spacing.sm) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? onboardingPages[currentPage].primaryColor : Color.gray.opacity(0.3))
                                .frame(width: 10, height: 10)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: ShelvesDesign.Spacing.md) {
                        if currentPage == onboardingPages.count - 1 {
                            // Final page - Get Started button
                            Button("Get Started") {
                                showingNameInput = true
                            }
                            .buttonStyle(PrimaryButtonStyle(color: onboardingPages[currentPage].primaryColor))
                        } else {
                            // Navigation buttons
                            HStack {
                                Button("Skip") {
                                    showingNameInput = true
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                
                                Spacer()
                                
                                Button("Next") {
                                    withAnimation {
                                        currentPage += 1
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle(color: onboardingPages[currentPage].primaryColor))
                            }
                        }
                    }
                }
                .padding(ShelvesDesign.Spacing.xl)
                .padding(.bottom, ShelvesDesign.Spacing.lg)
            }
        }
        .sheet(isPresented: $showingNameInput) {
            NameInputView(userName: $userName) {
                userManager.completeOnboarding(with: userName)
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: ShelvesDesign.Spacing.xl) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(page.primaryColor)
                .shadow(color: page.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Text content
            VStack(spacing: ShelvesDesign.Spacing.lg) {
                VStack(spacing: ShelvesDesign.Spacing.sm) {
                    Text(page.title)
                        .font(ShelvesDesign.Typography.titleLarge)
                        .foregroundColor(ShelvesDesign.Colors.warmBlack)
                        .multilineTextAlignment(.center)
                    
                    Text(page.subtitle)
                        .font(ShelvesDesign.Typography.headlineMedium)
                        .foregroundColor(page.primaryColor)
                        .multilineTextAlignment(.center)
                }
                
                Text(page.description)
                    .font(ShelvesDesign.Typography.bodyLarge)
                    .foregroundColor(ShelvesDesign.Colors.sepia)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(.horizontal, ShelvesDesign.Spacing.xl)
    }
}

struct NameInputView: View {
    @Binding var userName: String
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: ShelvesDesign.Spacing.xl) {
                Spacer()
                
                VStack(spacing: ShelvesDesign.Spacing.lg) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.26))
                    
                    VStack(spacing: ShelvesDesign.Spacing.md) {
                        Text("Create Your Bookplate")
                            .font(ShelvesDesign.Typography.titleMedium)
                            .foregroundColor(ShelvesDesign.Colors.warmBlack)

                        Text("Ex libris — from the library of...")
                            .font(ShelvesDesign.Typography.bodyMedium)
                            .foregroundColor(ShelvesDesign.Colors.sepia)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: ShelvesDesign.Spacing.md) {
                    TextField("Enter your name", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(ShelvesDesign.Typography.bodyLarge)
                        .submitLabel(.done)
                        .onSubmit {
                            if !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onComplete()
                            }
                        }
                    
                    Button("Continue") {
                        onComplete()
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Color(red: 0.79, green: 0.64, blue: 0.26)))
                    .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                Button("Skip for now") {
                    userName = ""
                    onComplete()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
            }
            .padding(ShelvesDesign.Spacing.xl)
            .navigationTitle("Your Bookplate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let primaryColor: Color
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ShelvesDesign.Typography.labelLarge)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ShelvesDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.medium)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ShelvesDesign.Typography.labelMedium)
            .foregroundColor(ShelvesDesign.Colors.sepia)
            .padding(.vertical, ShelvesDesign.Spacing.sm)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserManager.shared)
}