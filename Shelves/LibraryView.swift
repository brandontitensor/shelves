import SwiftUI
import CoreData

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .covers
    @State private var sortOption: SortOption = .dateAdded
    @State private var showingFilters = false
    @State private var selectedRoom = "All Libraries"
    
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
        case dateRead = "Date Read"
        
        var sortDescriptors: [NSSortDescriptor] {
            switch self {
            case .dateAdded:
                return [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)]
            case .title:
                return [NSSortDescriptor(keyPath: \Book.title, ascending: true)]
            case .author:
                return [NSSortDescriptor(keyPath: \Book.author, ascending: true)]
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
                (book.genre?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter by room
        if selectedRoom != "All Libraries" {
            result = result.filter { book in
                book.libraryName == selectedRoom
            }
        }
        
        return result
    }
    
    private var availableRooms: [String] {
        let rooms = books.compactMap { $0.libraryName }.unique()
        return ["All Libraries"] + rooms.sorted()
    }
    
    var body: some View {
        NavigationStack {
            BookshelfBackground()
                .overlay(
                    VStack(spacing: 0) {
                        // Search and filters
                        searchAndFiltersSection
                        
                        // Library content
                        if filteredBooks.isEmpty {
                            emptyLibraryView
                        } else {
                            libraryContentView
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
    }
    
    private var searchAndFiltersSection: some View {
        VStack(spacing: ShelvesDesign.Spacing.md) {
            // Room filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ShelvesDesign.Spacing.sm) {
                    ForEach(availableRooms, id: \.self) { room in
                        RoomFilterChip(
                            room: room,
                            isSelected: selectedRoom == room
                        ) {
                            selectedRoom = room
                        }
                    }
                }
                .padding(.horizontal, ShelvesDesign.Spacing.md)
            }
            
            // Sort and view options
            HStack {
                // Sort picker
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
                    .foregroundColor(ShelvesDesign.Colors.sepia)
                    .padding(.horizontal, ShelvesDesign.Spacing.md)
                    .padding(.vertical, ShelvesDesign.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.small)
                            .fill(ShelvesDesign.Colors.ivory)
                            .cardShadow()
                    )
                }
                
                Spacer()
                
                // Book count
                Text("\(filteredBooks.count) books")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.slateGray)
            }
            .padding(.horizontal, ShelvesDesign.Spacing.md)
        }
        .padding(.top, ShelvesDesign.Spacing.sm)
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
    
    var body: some View {
        VStack(spacing: ShelvesDesign.Spacing.sm) {
            // Book cover
            AsyncImage(url: book.coverImageURL.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                BookSpinePlaceholder(
                    title: book.title ?? "",
                    author: book.author ?? "",
                    color: bookSpineColor(for: book)
                )
            }
            .frame(height: 140)
            .clipped()
            .cornerRadius(ShelvesDesign.CornerRadius.medium)
            .bookShadow()
            
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
            }
            .frame(maxWidth: .infinity)
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

struct BookSpineRow: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: ShelvesDesign.Spacing.md) {
            // Spine representation
            BookSpinePlaceholder(
                title: book.title ?? "",
                author: book.author ?? "",
                color: bookSpineColor(for: book),
                isHorizontal: true
            )
            .frame(width: 60, height: 40)
            
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

#Preview {
    LibraryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}