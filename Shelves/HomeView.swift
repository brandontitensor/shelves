import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userManager: UserManager
    @State private var showSaveErrorAlert = false
    @State private var saveErrorMessage = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        predicate: NSPredicate(format: "currentlyReading == YES"),
        animation: .default)
    private var currentlyReadingBooks: FetchedResults<Book>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        animation: .default)
    private var allBooks: FetchedResults<Book>
    
    private var featuredBook: Book? {
        if !currentlyReadingBooks.isEmpty {
            return currentlyReadingBooks.first
        }
        
        let booksArray = Array(allBooks)
        return RecommendationService.getWeeklyRecommendation(from: booksArray)
    }
    
    private var carouselBooks: [Book] {
        var books: [Book] = []

        // Add currently reading books
        books.append(contentsOf: currentlyReadingBooks)

        // Add recent additions (last 5 books)
        let recentBooks = allBooks.prefix(5).filter { !$0.currentlyReading }
        books.append(contentsOf: recentBooks)

        // Add some random older books if we don't have enough
        if books.count < 3 {
            let booksSet = Set(books.map { $0.objectID })
            let otherBooks = allBooks.filter { book in
                !booksSet.contains(book.objectID) && !book.currentlyReading
            }
            books.append(contentsOf: otherBooks.prefix(3 - books.count))
        }

        return Array(books.prefix(6)) // Limit to 6 books for performance
    }
    
    @State private var currentIndex = 0
    
    var body: some View {
        NavigationStack {
            BookshelfBackground()
                .overlay(
                    VStack(spacing: 0) {
                        // Personalized header
                        personalizedHeader
                            .padding(.top, ShelvesDesign.Spacing.md)

                        if let featured = featuredBook {
                            fullScreenBookDisplay(book: featured)
                        } else {
                            emptyLibraryView
                        }
                    }
                )
                .navigationBarHidden(true)
        }
        .alert("Save Error", isPresented: $showSaveErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }
    
    private var personalizedHeader: some View {
        VStack(spacing: ShelvesDesign.Spacing.md) {
            // Bookplate
            BookplateView(
                userName: userManager.userName,
                style: userManager.bookplateStyle,
                showBorder: true
            )

            // Library status
            if !currentlyReadingBooks.isEmpty {
                Text("Currently reading \(currentlyReadingBooks.count) book\(currentlyReadingBooks.count == 1 ? "" : "s")")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
            } else if allBooks.isEmpty {
                Text("Ready to start your library journey")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
            } else {
                Text("\(allBooks.count) books in your collection")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
            }
        }
        .padding(.horizontal, ShelvesDesign.Spacing.lg)
    }
    
    private func fullScreenBookDisplay(book: Book) -> some View {
        VStack(spacing: 0) {
            // Main content area
            TabView(selection: $currentIndex) {
                ForEach(Array(carouselBooks.enumerated()), id: \.element.id) { index, book in
                    BookCarouselCard(book: book)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .gesture(
                DragGesture()
                    .onEnded { value in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if value.translation.width > 50 && currentIndex > 0 {
                                currentIndex -= 1
                            } else if value.translation.width < -50 && currentIndex < carouselBooks.count - 1 {
                                currentIndex += 1
                            }
                        }
                    }
            )
            
            // Bottom controls area
            VStack(spacing: ShelvesDesign.Spacing.lg) {
                customPageIndicator
                bookActionsBottomBar(book: book)
            }
            .padding(.bottom, ShelvesDesign.Spacing.lg)
        }
    }
    
    private var customPageIndicator: some View {
        HStack(spacing: ShelvesDesign.Spacing.xs) {
            ForEach(0..<carouselBooks.count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? ShelvesDesign.Colors.antiqueGold : ShelvesDesign.Colors.antiqueGold.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }
    
    private func bookActionsBottomBar(book: Book) -> some View {
        HStack(spacing: ShelvesDesign.Spacing.md) {
            if !book.isRead {
                HorizontalActionButton(
                    title: "Mark Read",
                    icon: "checkmark.circle.fill",
                    color: ShelvesDesign.Colors.forestGreen
                ) {
                    markAsRead(book: book)
                }
            }
            
            NavigationLink(destination: BookDetailView(book: book)) {
                HStack(spacing: ShelvesDesign.Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("View Details")
                        .font(ShelvesDesign.Typography.labelMedium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, ShelvesDesign.Spacing.lg)
                .padding(.vertical, ShelvesDesign.Spacing.md)
                .background(
                    Capsule()
                        .fill(ShelvesDesign.Colors.antiqueGold)
                        .shadow(color: ShelvesDesign.Colors.antiqueGold.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, ShelvesDesign.Spacing.lg)
        .background(
            LinearGradient(
                colors: [
                    Color.clear,
                    ShelvesDesign.Colors.background.opacity(0.9),
                    ShelvesDesign.Colors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
        )
    }
    
    private var emptyLibraryView: some View {
        VStack(spacing: ShelvesDesign.Spacing.xl) {
            Spacer()
            
            VStack(spacing: ShelvesDesign.Spacing.lg) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 80))
                    .foregroundColor(ShelvesDesign.Colors.chestnut.opacity(0.6))
                
                VStack(spacing: ShelvesDesign.Spacing.sm) {
                    Text("Welcome to Libris.")
                        .font(ShelvesDesign.Typography.titleMedium)
                        .foregroundColor(ShelvesDesign.Colors.text)

                    Text("Your personal library sanctuary")
                        .font(ShelvesDesign.Typography.bodyLarge)
                        .foregroundColor(ShelvesDesign.Colors.textSecondary)
                }
            }
            
            VStack(spacing: ShelvesDesign.Spacing.md) {
                Text("Start building your collection")
                    .font(ShelvesDesign.Typography.headlineSmall)
                    .foregroundColor(ShelvesDesign.Colors.text)
                
                Text("Add your first book to see it featured here with personalized recommendations from your collection.")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, ShelvesDesign.Spacing.xl)
            
            Spacer()
        }
    }
    
    private func markAsRead(book: Book) {
        withAnimation(.easeInOut(duration: 0.3)) {
            book.isRead = true
            book.currentlyReading = false
            book.dateRead = Date()

            do {
                try viewContext.save()
            } catch {
                // Revert changes on error
                book.isRead = false
                book.currentlyReading = true
                book.dateRead = nil
                viewContext.rollback()

                // Show user-facing error alert
                saveErrorMessage = "Unable to save changes: \(error.localizedDescription)"
                showSaveErrorAlert = true
            }
        }
    }
}

// MARK: - Book Carousel Card
struct BookCarouselCard: View {
    let book: Book
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Main book cover area
                bookCoverSection(geometry: geometry)
                
                // Book info section
                bookInfoSection
                
                Spacer()
            }
        }
    }
    
    private func bookCoverSection(geometry: GeometryProxy) -> some View {
        BookCoverImage(
            book: book, 
            height: geometry.size.height * 0.5, 
            cornerRadius: ShelvesDesign.CornerRadius.medium,
            contentMode: .fit
        )
        .padding(.horizontal, ShelvesDesign.Spacing.xl)
    }
    
    private var bookInfoSection: some View {
        VStack(spacing: ShelvesDesign.Spacing.md) {
            // Status badge
            if book.currentlyReading {
                StatusBadge(text: "Currently Reading", color: ShelvesDesign.Colors.forestGreen)
            } else if book.isRead {
                StatusBadge(text: "Read", color: ShelvesDesign.Colors.antiqueGold)
            } else {
                StatusBadge(text: "In Library", color: ShelvesDesign.Colors.chestnut)
            }
            
            // Book title and author
            VStack(spacing: ShelvesDesign.Spacing.xs) {
                Text(book.title ?? "Unknown Title")
                    .font(ShelvesDesign.Typography.titleSmall)
                    .foregroundColor(ShelvesDesign.Colors.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if let author = book.author {
                    Text("by \(author)")
                        .font(ShelvesDesign.Typography.bodyLarge)
                        .foregroundColor(ShelvesDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
            }
            
            // Weekly recommendation text
            if !book.currentlyReading {
                let recommendation = RecommendationService.getRecommendationText(for: book)
                Text(recommendation.subtitle)
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, ShelvesDesign.Spacing.lg)
            }
        }
        .padding(.horizontal, ShelvesDesign.Spacing.lg)
        .padding(.top, ShelvesDesign.Spacing.xl)
    }
}

// MARK: - Supporting Components
struct BookPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.medium)
            .fill(
                LinearGradient(
                    colors: [
                        ShelvesDesign.Colors.burgundy,
                        ShelvesDesign.Colors.deepMaroon
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: ShelvesDesign.Spacing.sm) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("No Cover")
                        .font(ShelvesDesign.Typography.labelSmall)
                        .foregroundColor(.white.opacity(0.7))
                }
            )
            .aspectRatio(2/3, contentMode: .fit)
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(ShelvesDesign.Typography.labelSmall)
            .foregroundColor(color)
            .padding(.horizontal, ShelvesDesign.Spacing.md)
            .padding(.vertical, ShelvesDesign.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.small)
                    .fill(color.opacity(0.15))
            )
    }
}

struct BookActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LabeledActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ShelvesDesign.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(color)
                            .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
                    )
                
                Text(title)
                    .font(ShelvesDesign.Typography.labelMedium)
                    .foregroundColor(ShelvesDesign.Colors.text)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}