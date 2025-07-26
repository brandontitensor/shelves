import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
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
            let otherBooks = allBooks.filter { book in
                !books.contains(book) && !book.currentlyReading
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
                        if let featured = featuredBook {
                            fullScreenBookDisplay(book: featured)
                        } else {
                            emptyLibraryView
                        }
                    }
                )
                .navigationBarHidden(true)
        }
    }
    
    private func fullScreenBookDisplay(book: Book) -> some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(carouselBooks.enumerated()), id: \.element.id) { index, book in
                BookCarouselCard(book: book)
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .overlay(alignment: .bottom) {
            customPageIndicator
        }
        .overlay(alignment: .bottomTrailing) {
            bookActionsOverlay(book: book)
        }
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
        .padding(.bottom, ShelvesDesign.Spacing.xxl)
    }
    
    private func bookActionsOverlay(book: Book) -> some View {
        VStack(spacing: ShelvesDesign.Spacing.md) {
            if !book.isRead {
                BookActionButton(
                    icon: "checkmark.circle.fill",
                    color: ShelvesDesign.Colors.forestGreen
                ) {
                    markAsRead(book: book)
                }
            }
            
            NavigationLink(destination: BookDetailView(book: book)) {
                BookActionButton(
                    icon: "note.text",
                    color: ShelvesDesign.Colors.burgundy
                ) {}
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.trailing, ShelvesDesign.Spacing.lg)
        .padding(.bottom, ShelvesDesign.Spacing.xxl)
    }
    
    private var emptyLibraryView: some View {
        VStack(spacing: ShelvesDesign.Spacing.xl) {
            Spacer()
            
            VStack(spacing: ShelvesDesign.Spacing.lg) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 80))
                    .foregroundColor(ShelvesDesign.Colors.chestnut.opacity(0.6))
                
                VStack(spacing: ShelvesDesign.Spacing.sm) {
                    Text("Welcome to Shelves")
                        .font(ShelvesDesign.Typography.titleMedium)
                        .foregroundColor(ShelvesDesign.Colors.sepia)
                    
                    Text("Your personal library sanctuary")
                        .font(ShelvesDesign.Typography.bodyLarge)
                        .foregroundColor(ShelvesDesign.Colors.slateGray)
                }
            }
            
            VStack(spacing: ShelvesDesign.Spacing.md) {
                Text("Start building your collection")
                    .font(ShelvesDesign.Typography.headlineSmall)
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                
                Text("Add your first book to see it featured here with personalized recommendations from your collection.")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.sepia)
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
            try? viewContext.save()
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
        AsyncImage(url: book.coverImageURL.flatMap(URL.init)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } placeholder: {
            BookPlaceholder()
        }
        .frame(maxHeight: geometry.size.height * 0.5)
        .bookShadow()
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
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if let author = book.author {
                    Text("by \(author)")
                        .font(ShelvesDesign.Typography.bodyLarge)
                        .foregroundColor(ShelvesDesign.Colors.sepia)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
            }
            
            // Weekly recommendation text
            if !book.currentlyReading {
                let recommendation = RecommendationService.getRecommendationText(for: book)
                Text(recommendation.subtitle)
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.slateGray)
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

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}