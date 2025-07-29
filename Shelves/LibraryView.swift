import SwiftUI
import CoreData

// Environment object to pass sort state to child views
class LibraryViewEnvironment: ObservableObject {
    @Published var currentSortOption: LibraryView.SortOption?
}

// Smart Collection Model
struct SmartCollection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let count: Int
}

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var libraryEnvironment = LibraryViewEnvironment()
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .covers
    @State private var sortOption: SortOption = .dateAdded
    @State private var showingFilters = false
    @State private var selectedSmartCollection: String? = nil
    @State private var selectedCustomLibrary: String? = nil
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        animation: .default)
    private var books: FetchedResults<Book>
    
    enum ViewMode: String, CaseIterable {
        case covers = "Books"
        case spines = "Spines"
        
        var icon: String {
            switch self {
            case .covers: return "square.grid.2x2"
            case .spines: return "line.3.horizontal"
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case dateAdded = "Date Added"
        case title = "Title"
        case author = "Author"
        case genre = "Genre"
        case format = "Format"
        case rating = "Rating"
        case dateRead = "Date Read"
        
        var sortDescriptors: [NSSortDescriptor] {
            switch self {
            case .dateAdded:
                return [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)]
            case .title:
                return [NSSortDescriptor(keyPath: \Book.title, ascending: true)]
            case .author:
                return [
                    NSSortDescriptor(keyPath: \Book.author, ascending: true),
                    NSSortDescriptor(keyPath: \Book.title, ascending: true)
                ]
            case .genre:
                return [
                    NSSortDescriptor(keyPath: \Book.genre, ascending: true),
                    NSSortDescriptor(keyPath: \Book.author, ascending: true),
                    NSSortDescriptor(keyPath: \Book.title, ascending: true)
                ]
            case .format:
                return [
                    NSSortDescriptor(keyPath: \Book.format, ascending: true),
                    NSSortDescriptor(keyPath: \Book.author, ascending: true),
                    NSSortDescriptor(keyPath: \Book.title, ascending: true)
                ]
            case .rating:
                return [
                    NSSortDescriptor(keyPath: \Book.rating, ascending: false),
                    NSSortDescriptor(keyPath: \Book.author, ascending: true),
                    NSSortDescriptor(keyPath: \Book.title, ascending: true)
                ]
            case .dateRead:
                return [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)] // Placeholder for actual read date
            }
        }
    }
    
    private var filteredBooks: [Book] {
        var result = Array(books)
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { book in
                (book.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (book.author?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (book.genre?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (book.format?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter by Smart Collection or Custom Library
        if let smartCollection = selectedSmartCollection {
            switch smartCollection {
            case "my_library":
                result = result.filter { book in
                    !book.isWantToRead && !book.isWantToBuy && book.libraryName != "Borrowed Books"
                }
            case "want_to_read":
                result = result.filter { $0.isWantToRead }
            case "want_to_buy":
                result = result.filter { $0.isWantToBuy }
            case "read_not_owned":
                result = result.filter { book in
                    book.isRead && !book.isWantToRead && !book.isWantToBuy && 
                    (book.libraryName == "Borrowed Books" || book.libraryName == nil)
                }
            default:
                break
            }
        } else if let customLibrary = selectedCustomLibrary {
            result = result.filter { book in
                book.libraryName == customLibrary
            }
        }
        
        // Apply sorting with multi-level subsorts
        return result.sorted { lhs, rhs in
            switch sortOption {
            case .dateAdded:
                return (lhs.dateAdded ?? Date.distantPast) > (rhs.dateAdded ?? Date.distantPast)
                
            case .title:
                return (lhs.title ?? "") < (rhs.title ?? "")
                
            case .author:
                // Primary sort: Author, Secondary sort: Title
                let lhsAuthor = lhs.author ?? ""
                let rhsAuthor = rhs.author ?? ""
                if lhsAuthor != rhsAuthor {
                    return lhsAuthor < rhsAuthor
                }
                return (lhs.title ?? "") < (rhs.title ?? "")
                
            case .genre:
                // Primary sort: Genre, Secondary sort: Author, Tertiary sort: Title
                let lhsGenre = lhs.genre ?? ""
                let rhsGenre = rhs.genre ?? ""
                if lhsGenre != rhsGenre {
                    return lhsGenre < rhsGenre
                }
                let lhsAuthor = lhs.author ?? ""
                let rhsAuthor = rhs.author ?? ""
                if lhsAuthor != rhsAuthor {
                    return lhsAuthor < rhsAuthor
                }
                return (lhs.title ?? "") < (rhs.title ?? "")
                
            case .format:
                // Primary sort: Format, Secondary sort: Author, Tertiary sort: Title
                let lhsFormat = lhs.format ?? "Physical"
                let rhsFormat = rhs.format ?? "Physical"
                if lhsFormat != rhsFormat {
                    return lhsFormat < rhsFormat
                }
                let lhsAuthor = lhs.author ?? ""
                let rhsAuthor = rhs.author ?? ""
                if lhsAuthor != rhsAuthor {
                    return lhsAuthor < rhsAuthor
                }
                return (lhs.title ?? "") < (rhs.title ?? "")
                
            case .rating:
                // Primary sort: Rating (highest first), Secondary sort: Author, Tertiary sort: Title
                if lhs.rating != rhs.rating {
                    return lhs.rating > rhs.rating
                }
                let lhsAuthor = lhs.author ?? ""
                let rhsAuthor = rhs.author ?? ""
                if lhsAuthor != rhsAuthor {
                    return lhsAuthor < rhsAuthor
                }
                return (lhs.title ?? "") < (rhs.title ?? "")
                
            case .dateRead:
                let lhsDate = lhs.isRead ? (lhs.dateAdded ?? Date.distantPast) : Date.distantPast
                let rhsDate = rhs.isRead ? (rhs.dateAdded ?? Date.distantPast) : Date.distantPast
                return lhsDate > rhsDate
            }
        }
    }
    
    // Smart Collections
    private var smartCollections: [SmartCollection] {
        [
            SmartCollection(
                id: "my_library",
                title: "My Library",
                subtitle: "Books I own",
                icon: "house.fill",
                color: ShelvesDesign.Colors.forestGreen,
                count: ownedBooksCount
            ),
            SmartCollection(
                id: "want_to_read",
                title: "Want to Read",
                subtitle: "Reading wishlist",
                icon: "book.fill",
                color: ShelvesDesign.Colors.antiqueGold,
                count: wantToReadCount
            ),
            SmartCollection(
                id: "want_to_buy",
                title: "Want to Buy",
                subtitle: "Purchase wishlist",
                icon: "cart.fill",
                color: ShelvesDesign.Colors.burgundy,
                count: wantToBuyCount
            ),
            SmartCollection(
                id: "read_not_owned",
                title: "Read but Don't Own",
                subtitle: "Books I've read",
                icon: "checkmark.circle.fill",
                color: ShelvesDesign.Colors.chestnut,
                count: readNotOwnedCount
            )
        ]
    }
    
    private var customLibraries: [String] {
        let allLibraries = books.compactMap { $0.libraryName }.unique().sorted()
        return allLibraries.filter { !["Borrowed Books"].contains($0) } // Filter out old confusing names
    }
    
    // Smart Collection Counts
    private var ownedBooksCount: Int {
        books.filter { book in
            !book.isWantToRead && !book.isWantToBuy && book.libraryName != "Borrowed Books"
        }.count
    }
    
    private var wantToReadCount: Int {
        books.filter { $0.isWantToRead }.count
    }
    
    private var wantToBuyCount: Int {
        books.filter { $0.isWantToBuy }.count
    }
    
    private var readNotOwnedCount: Int {
        books.filter { book in
            book.isRead && !book.isWantToRead && !book.isWantToBuy && 
            (book.libraryName == "Borrowed Books" || book.libraryName == nil)
        }.count
    }
    
    var body: some View {
        NavigationStack {
            BookshelfBackground()
                .overlay(
                    VStack(spacing: 0) {
                        // Show content based on selection
                        if selectedSmartCollection != nil || selectedCustomLibrary != nil {
                            // Selected collection/library view
                            selectedCollectionView
                        } else {
                            // Main library overview
                            mainLibraryView
                        }
                    }
                )
                .navigationTitle("Library")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        viewModeToggle
                    }
                }
        }
        .searchable(text: $searchText, prompt: "Search your library...")
        .environmentObject(libraryEnvironment)
        .onChange(of: sortOption) { _, newValue in
            libraryEnvironment.currentSortOption = newValue
        }
        .onAppear {
            libraryEnvironment.currentSortOption = sortOption
        }
    }
    
    // MARK: - Main Library View
    private var mainLibraryView: some View {
        ScrollView {
            VStack(spacing: ShelvesDesign.Spacing.lg) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ShelvesDesign.Colors.textSecondary)
                    
                    TextField("Search books...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(ShelvesDesign.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.medium)
                        .fill(ShelvesDesign.Colors.surface)
                        .cardShadow()
                )
                .padding(.horizontal, ShelvesDesign.Spacing.md)
                
                // Smart Collections Section
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(ShelvesDesign.Colors.antiqueGold)
                            .font(.title3)
                        
                        Text("Smart Collections")
                            .font(ShelvesDesign.Typography.headlineMedium)
                            .foregroundColor(ShelvesDesign.Colors.text)
                        
                        Spacer()
                    }
                    .padding(.horizontal, ShelvesDesign.Spacing.md)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: ShelvesDesign.Spacing.md) {
                        ForEach(smartCollections) { collection in
                            SmartCollectionCard(collection: collection) {
                                selectedSmartCollection = collection.id
                            }
                        }
                    }
                    .padding(.horizontal, ShelvesDesign.Spacing.md)
                }
                
                // Custom Libraries Section
                if !customLibraries.isEmpty {
                    VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(ShelvesDesign.Colors.chestnut)
                                .font(.title3)
                            
                            Text("My Libraries")
                                .font(ShelvesDesign.Typography.headlineMedium)
                                .foregroundColor(ShelvesDesign.Colors.text)
                            
                            Spacer()
                        }
                        .padding(.horizontal, ShelvesDesign.Spacing.md)
                        
                        LazyVStack(spacing: ShelvesDesign.Spacing.sm) {
                            ForEach(customLibraries, id: \.self) { library in
                                CustomLibraryRow(
                                    name: library,
                                    count: books.filter { $0.libraryName == library }.count
                                ) {
                                    selectedCustomLibrary = library
                                }
                            }
                        }
                        .padding(.horizontal, ShelvesDesign.Spacing.md)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top, ShelvesDesign.Spacing.md)
        }
    }
    
    // MARK: - Selected Collection View
    private var selectedCollectionView: some View {
        VStack(spacing: 0) {
            // Back button and title
            HStack {
                Button(action: {
                    selectedSmartCollection = nil
                    selectedCustomLibrary = nil
                }) {
                    HStack(spacing: ShelvesDesign.Spacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Library")
                    }
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.primary)
                }
                
                Spacer()
                
                // Collection title
                if let smartCollectionId = selectedSmartCollection,
                   let collection = smartCollections.first(where: { $0.id == smartCollectionId }) {
                    Text(collection.title)
                        .font(ShelvesDesign.Typography.headlineMedium)
                        .foregroundColor(ShelvesDesign.Colors.text)
                } else if let customLibrary = selectedCustomLibrary {
                    Text(customLibrary)
                        .font(ShelvesDesign.Typography.headlineMedium)
                        .foregroundColor(ShelvesDesign.Colors.text)
                }
                
                Spacer()
                
                // View mode toggle
                Button(action: {
                    viewMode = viewMode == .covers ? .spines : .covers
                }) {
                    Image(systemName: viewMode.icon)
                        .font(ShelvesDesign.Typography.bodyMedium)
                        .foregroundColor(ShelvesDesign.Colors.textSecondary)
                }
            }
            .padding(ShelvesDesign.Spacing.md)
            
            // Sort options
            HStack {
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            sortOption = option
                        }
                    }
                } label: {
                    HStack(spacing: ShelvesDesign.Spacing.xs) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOption.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(ShelvesDesign.Typography.labelMedium)
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
                    .padding(.horizontal, ShelvesDesign.Spacing.md)
                    .padding(.vertical, ShelvesDesign.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.small)
                            .fill(ShelvesDesign.Colors.surface)
                            .cardShadow()
                    )
                }
                
                Spacer()
            }
            .padding(.horizontal, ShelvesDesign.Spacing.md)
            .padding(.bottom, ShelvesDesign.Spacing.sm)
            
            // Books grid/list
            if filteredBooks.isEmpty {
                emptyCollectionView
            } else {
                libraryContentView
            }
        }
    }
    
    private var emptyCollectionView: some View {
        VStack(spacing: ShelvesDesign.Spacing.lg) {
            Spacer()
            
            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundColor(ShelvesDesign.Colors.textSecondary.opacity(0.6))
            
            Text("No books in this collection")
                .font(ShelvesDesign.Typography.headlineMedium)
                .foregroundColor(ShelvesDesign.Colors.text)
            
            Text("Start adding books to see them here")
                .font(ShelvesDesign.Typography.bodyMedium)
                .foregroundColor(ShelvesDesign.Colors.textSecondary)
            
            Spacer()
        }
    }
    
    
    private var viewModeToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewMode = viewMode == .covers ? .spines : .covers
            }
        } label: {
            Image(systemName: viewMode.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ShelvesDesign.Colors.antiqueGold)
        }
    }
    
    private var libraryContentView: some View {
        ScrollView {
            LazyVStack(spacing: ShelvesDesign.Spacing.md) {
                if viewMode == .covers {
                    bookCoversGrid
                } else {
                    bookSpinesList
                }
            }
            .padding(.horizontal, ShelvesDesign.Spacing.md)
            .padding(.bottom, ShelvesDesign.Spacing.xl)
        }
    }
    
    private var bookCoversGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: ShelvesDesign.Spacing.md),
                GridItem(.flexible(), spacing: ShelvesDesign.Spacing.md),
                GridItem(.flexible(), spacing: ShelvesDesign.Spacing.md)
            ],
            spacing: ShelvesDesign.Spacing.lg
        ) {
            ForEach(filteredBooks, id: \.id) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    BookCoverCard(book: book)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var bookSpinesList: some View {
        VStack(spacing: ShelvesDesign.Spacing.xs) {
            ForEach(filteredBooks, id: \.id) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    BookSpineRow(book: book)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var emptyLibraryView: some View {
        VStack(spacing: ShelvesDesign.Spacing.xl) {
            Spacer()
            
            VStack(spacing: ShelvesDesign.Spacing.lg) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 64))
                    .foregroundColor(ShelvesDesign.Colors.chestnut.opacity(0.5))
                
                VStack(spacing: ShelvesDesign.Spacing.sm) {
                    Text(searchText.isEmpty ? "Your Library Awaits" : "No Books Found")
                        .font(ShelvesDesign.Typography.headlineLarge)
                        .foregroundColor(ShelvesDesign.Colors.sepia)
                    
                    Text(searchText.isEmpty ? 
                         "Start adding books to build your personal collection" :
                         "Try adjusting your search or filters")
                        .font(ShelvesDesign.Typography.bodyLarge)
                        .foregroundColor(ShelvesDesign.Colors.slateGray)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, ShelvesDesign.Spacing.xl)
    }
}

// MARK: - Supporting Components

struct RoomFilterChip: View {
    let room: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(room)
                .font(ShelvesDesign.Typography.labelMedium)
                .foregroundColor(isSelected ? .white : ShelvesDesign.Colors.sepia)
                .padding(.horizontal, ShelvesDesign.Spacing.md)
                .padding(.vertical, ShelvesDesign.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.large)
                        .fill(isSelected ? ShelvesDesign.Colors.antiqueGold : ShelvesDesign.Colors.ivory)
                        .softShadow()
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BookCoverCard: View {
    let book: Book
    @EnvironmentObject private var libraryView: LibraryViewEnvironment
    
    var body: some View {
        VStack(spacing: ShelvesDesign.Spacing.sm) {
            // Book cover
            BookCoverImage(book: book, style: .grid)
            
            // Book info
            VStack(spacing: ShelvesDesign.Spacing.xs) {
                Text(book.title ?? "Unknown Title")
                    .font(ShelvesDesign.Typography.labelMedium)
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if let author = book.author {
                    Text(author)
                        .font(ShelvesDesign.Typography.caption)
                        .foregroundColor(ShelvesDesign.Colors.sepia)
                        .lineLimit(1)
                }
                
                // Show additional info based on sort option
                additionalInfoView
                
                // Show wishlist status
                wishlistStatusView
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    private var additionalInfoView: some View {
        if let currentSort = libraryView.currentSortOption {
            switch currentSort {
            case .genre:
                if let genre = book.genre, !genre.isEmpty {
                    Text(genre)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(ShelvesDesign.Colors.chestnut)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ShelvesDesign.Colors.chestnut.opacity(0.1))
                        )
                        .lineLimit(1)
                }
            case .format:
                if let format = book.format, !format.isEmpty {
                    Text(format)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(ShelvesDesign.Colors.navy)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ShelvesDesign.Colors.navy.opacity(0.1))
                        )
                        .lineLimit(1)
                }
            case .rating:
                if book.rating > 0 {
                    HStack(spacing: 1) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= Int(book.rating) ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundColor(ShelvesDesign.Colors.antiqueGold)
                        }
                    }
                }
            default:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private var wishlistStatusView: some View {
        HStack(spacing: 4) {
            if book.isWantToRead ?? false {
                Text("Want to Read")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.orange.opacity(0.1))
                    )
                    .lineLimit(1)
            }
            
            if book.isWantToBuy ?? false {
                Text("Want to Buy")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.purple.opacity(0.1))
                    )
                    .lineLimit(1)
            }
        }
    }
}
    
    private func bookSpineColor(for book: Book) -> Color {
        let colors = [
            ShelvesDesign.Colors.burgundy,
            ShelvesDesign.Colors.forestGreen,
            ShelvesDesign.Colors.navy,
            ShelvesDesign.Colors.deepMaroon,
            ShelvesDesign.Colors.chestnut
        ]
        
        let hash = book.title?.hashValue ?? 0
        return colors[abs(hash) % colors.count]
    }


struct BookSpineRow: View {
    let book: Book
    @EnvironmentObject private var libraryView: LibraryViewEnvironment
    
    var body: some View {
        HStack(spacing: ShelvesDesign.Spacing.md) {
            // Miniaturized book cover
            BookCoverImage(book: book, style: .list)
            
            // Book details
            VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                Text(book.title ?? "Unknown Title")
                    .font(ShelvesDesign.Typography.headlineSmall)
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                    .lineLimit(1)
                
                if let author = book.author {
                    Text(author)
                        .font(ShelvesDesign.Typography.bodyMedium)
                        .foregroundColor(ShelvesDesign.Colors.sepia)
                        .lineLimit(1)
                }
                
                HStack(spacing: ShelvesDesign.Spacing.sm) {
                    if book.currentlyReading {
                        StatusPill(text: "Reading", color: ShelvesDesign.Colors.forestGreen)
                    } else if book.isRead {
                        StatusPill(text: "Read", color: ShelvesDesign.Colors.antiqueGold)
                    }
                    
                    if let library = book.libraryName {
                        StatusPill(text: library, color: ShelvesDesign.Colors.chestnut)
                    }
                    
                    // Show wishlist status
                    if book.isWantToRead ?? false {
                        StatusPill(text: "Want to Read", color: .orange)
                    }
                    
                    if book.isWantToBuy ?? false {
                        StatusPill(text: "Want to Buy", color: .purple)
                    }
                    
                    // Show additional info based on sort option
                    additionalSpineInfo
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ShelvesDesign.Colors.chestnut.opacity(0.6))
        }
        .padding(ShelvesDesign.Spacing.md)
        .background(
            WarmCardBackground()
        )
    }
    
    @ViewBuilder
    private var additionalSpineInfo: some View {
        if let currentSort = libraryView.currentSortOption {
            switch currentSort {
            case .genre:
                if let genre = book.genre, !genre.isEmpty {
                    StatusPill(text: genre, color: ShelvesDesign.Colors.burgundy)
                }
            case .format:
                if let format = book.format, !format.isEmpty {
                    StatusPill(text: format, color: ShelvesDesign.Colors.navy)
                }
            case .rating:
                if book.rating > 0 {
                    HStack(spacing: 1) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= Int(book.rating) ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(ShelvesDesign.Colors.antiqueGold)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ShelvesDesign.Colors.antiqueGold.opacity(0.1))
                    )
                }
            default:
                EmptyView()
            }
        }
    }
    
    private func bookSpineColor(for book: Book) -> Color {
        let colors = [
            ShelvesDesign.Colors.burgundy,
            ShelvesDesign.Colors.forestGreen,
            ShelvesDesign.Colors.navy,
            ShelvesDesign.Colors.deepMaroon,
            ShelvesDesign.Colors.chestnut
        ]
        
        let hash = book.title?.hashValue ?? 0
        return colors[abs(hash) % colors.count]
    }
}

struct BookSpinePlaceholder: View {
    let title: String
    let author: String
    let color: Color
    var isHorizontal: Bool = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.small)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: 2) {
                    if !isHorizontal {
                        Spacer()
                    }
                    
                    Text(title.prefix(isHorizontal ? 15 : 20))
                        .font(.system(size: isHorizontal ? 10 : 8, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(isHorizontal ? 1 : 3)
                        .multilineTextAlignment(.center)
                    
                    if !author.isEmpty {
                        Text(author.prefix(isHorizontal ? 10 : 15))
                            .font(.system(size: isHorizontal ? 8 : 6, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    
                    if !isHorizontal {
                        Spacer()
                    }
                }
                .padding(isHorizontal ? 4 : 6)
            )
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
            )
    }
}

// MARK: - Array Extension
extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - Smart Collection Card
struct SmartCollectionCard: View {
    let collection: SmartCollection
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ShelvesDesign.Spacing.sm) {
                // Icon and count
                HStack {
                    Image(systemName: collection.icon)
                        .font(.title2)
                        .foregroundColor(collection.color)
                    
                    Spacer()
                    
                    Text("\(collection.count)")
                        .font(ShelvesDesign.Typography.headlineMedium)
                        .foregroundColor(ShelvesDesign.Colors.text)
                        .fontWeight(.semibold)
                }
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    HStack {
                        Text(collection.title)
                            .font(ShelvesDesign.Typography.labelLarge)
                            .foregroundColor(ShelvesDesign.Colors.text)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(collection.subtitle)
                            .font(ShelvesDesign.Typography.bodySmall)
                            .foregroundColor(ShelvesDesign.Colors.textSecondary)
                        
                        Spacer()
                    }
                }
            }
            .padding(ShelvesDesign.Spacing.md)
            .background(
                WarmCardBackground()
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Library Row
struct CustomLibraryRow: View {
    let name: String
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ShelvesDesign.Spacing.md) {
                // Folder icon
                Image(systemName: "folder.fill")
                    .font(.title3)
                    .foregroundColor(ShelvesDesign.Colors.chestnut)
                
                // Library name
                Text(name)
                    .font(ShelvesDesign.Typography.bodyLarge)
                    .foregroundColor(ShelvesDesign.Colors.text)
                
                Spacer()
                
                // Book count
                Text("\(count) books")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
            }
            .padding(ShelvesDesign.Spacing.md)
            .background(
                WarmCardBackground()
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LibraryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
