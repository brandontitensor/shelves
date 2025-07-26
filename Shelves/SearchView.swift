import SwiftUI
import CoreData

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var searchCategory: SearchCategory = .all
    @State private var recentSearches: [String] = []
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        animation: .default)
    private var allBooks: FetchedResults<Book>
    
    enum SearchCategory: String, CaseIterable {
        case all = "All"
        case title = "Title"
        case author = "Author"
        case genre = "Genre"
        case isbn = "ISBN"
        
        var icon: String {
            switch self {
            case .all: return "magnifyingglass"
            case .title: return "book.closed"
            case .author: return "person"
            case .genre: return "tag"
            case .isbn: return "barcode"
            }
        }
    }
    
    private var searchResults: [Book] {
        guard !searchText.isEmpty else { return [] }
        
        return allBooks.filter { book in
            switch searchCategory {
            case .all:
                return matchesAny(book: book, searchText: searchText)
            case .title:
                return book.title?.localizedCaseInsensitiveContains(searchText) ?? false
            case .author:
                return book.author?.localizedCaseInsensitiveContains(searchText) ?? false
            case .genre:
                return book.genre?.localizedCaseInsensitiveContains(searchText) ?? false
            case .isbn:
                return book.isbn?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    private var suggestedSearches: [String] {
        guard searchText.count > 1 else { return [] }
        
        var suggestions: Set<String> = []
        
        // Add matching titles
        allBooks.compactMap { $0.title }
            .filter { $0.localizedCaseInsensitiveContains(searchText) }
            .prefix(3)
            .forEach { suggestions.insert($0) }
        
        // Add matching authors
        allBooks.compactMap { $0.author }
            .filter { $0.localizedCaseInsensitiveContains(searchText) }
            .prefix(3)
            .forEach { suggestions.insert($0) }
        
        // Add matching genres
        allBooks.compactMap { $0.genre }
            .filter { $0.localizedCaseInsensitiveContains(searchText) }
            .prefix(2)
            .forEach { suggestions.insert($0) }
        
        return Array(suggestions).sorted().prefix(6).map { String($0) }
    }
    
    var body: some View {
        NavigationStack {
            BookshelfBackground()
                .overlay(
                    VStack(spacing: 0) {
                        searchHeaderSection
                        
                        if searchText.isEmpty {
                            emptySearchView
                        } else if searchResults.isEmpty {
                            noResultsView
                        } else {
                            searchResultsView
                        }
                    }
                )
                .navigationTitle("Search")
                .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadRecentSearches()
        }
    }
    
    private var searchHeaderSection: some View {
        VStack(spacing: ShelvesDesign.Spacing.md) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ShelvesDesign.Colors.chestnut)
                    .font(.system(size: 18))
                
                TextField("Search your library...", text: $searchText)
                    .font(ShelvesDesign.Typography.bodyLarge)
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                    .onSubmit {
                        if !searchText.isEmpty {
                            addToRecentSearches(searchText)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ShelvesDesign.Colors.slateGray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(ShelvesDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.medium)
                    .fill(ShelvesDesign.Colors.ivory)
                    .cardShadow()
            )
            
            // Search categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ShelvesDesign.Spacing.sm) {
                    ForEach(SearchCategory.allCases, id: \.self) { category in
                        SearchCategoryChip(
                            category: category,
                            isSelected: searchCategory == category
                        ) {
                            searchCategory = category
                        }
                    }
                }
                .padding(.horizontal, ShelvesDesign.Spacing.md)
            }
        }
        .padding(ShelvesDesign.Spacing.md)
    }
    
    private var emptySearchView: some View {
        ScrollView {
            VStack(spacing: ShelvesDesign.Spacing.xl) {
                // Welcome section
                VStack(spacing: ShelvesDesign.Spacing.lg) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(ShelvesDesign.Colors.chestnut.opacity(0.6))
                    
                    VStack(spacing: ShelvesDesign.Spacing.sm) {
                        Text("Discover Your Collection")
                            .font(ShelvesDesign.Typography.titleMedium)
                            .foregroundColor(ShelvesDesign.Colors.sepia)
                        
                        Text("Search through your personal library")
                            .font(ShelvesDesign.Typography.bodyLarge)
                            .foregroundColor(ShelvesDesign.Colors.slateGray)
                    }
                }
                .padding(.top, ShelvesDesign.Spacing.xxl)
                
                // Recent searches
                if !recentSearches.isEmpty {
                    recentSearchesSection
                }
                
                // Quick access suggestions
                quickAccessSection
                
                Spacer(minLength: ShelvesDesign.Spacing.xxl)
            }
            .padding(.horizontal, ShelvesDesign.Spacing.md)
        }
    }
    
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            HStack {
                Text("Recent Searches")
                    .font(ShelvesDesign.Typography.headlineSmall)
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                
                Spacer()
                
                Button("Clear") {
                    clearRecentSearches()
                }
                .font(ShelvesDesign.Typography.labelMedium)
                .foregroundColor(ShelvesDesign.Colors.antiqueGold)
            }
            
            LazyVStack(spacing: ShelvesDesign.Spacing.xs) {
                ForEach(recentSearches, id: \.self) { search in
                    RecentSearchRow(searchText: search) {
                        searchText = search
                    }
                }
            }
        }
    }
    
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            Text("Browse by Category")
                .font(ShelvesDesign.Typography.headlineSmall)
                .foregroundColor(ShelvesDesign.Colors.warmBlack)
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: ShelvesDesign.Spacing.md
            ) {
                QuickAccessCard(
                    title: "All Books",
                    count: allBooks.count,
                    icon: "books.vertical",
                    color: ShelvesDesign.Colors.burgundy
                ) {
                    searchCategory = .all
                    searchText = "*"
                }
                
                QuickAccessCard(
                    title: "Currently Reading",
                    count: allBooks.filter { $0.currentlyReading }.count,
                    icon: "book.open",
                    color: ShelvesDesign.Colors.forestGreen
                ) {
                    // Navigate to currently reading books
                }
                
                QuickAccessCard(
                    title: "Unread Books",
                    count: allBooks.filter { !$0.isRead && !$0.currentlyReading }.count,
                    icon: "book.closed",
                    color: ShelvesDesign.Colors.navy
                ) {
                    // Navigate to unread books
                }
                
                QuickAccessCard(
                    title: "Favorites",
                    count: allBooks.filter { $0.rating >= 4.0 }.count,
                    icon: "star.fill",
                    color: ShelvesDesign.Colors.antiqueGold
                ) {
                    // Navigate to highly rated books
                }
            }
        }
    }
    
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // Results header
            HStack {
                Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.slateGray)
                
                Spacer()
                
                if !suggestedSearches.isEmpty {
                    Menu("Suggestions") {
                        ForEach(suggestedSearches, id: \.self) { suggestion in
                            Button(suggestion) {
                                searchText = suggestion
                            }
                        }
                    }
                    .font(ShelvesDesign.Typography.labelMedium)
                    .foregroundColor(ShelvesDesign.Colors.antiqueGold)
                }
            }
            .padding(.horizontal, ShelvesDesign.Spacing.md)
            .padding(.bottom, ShelvesDesign.Spacing.sm)
            
            // Results list
            ScrollView {
                LazyVStack(spacing: ShelvesDesign.Spacing.sm) {
                    ForEach(searchResults, id: \.id) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            SearchResultRow(book: book, searchText: searchText)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, ShelvesDesign.Spacing.md)
                .padding(.bottom, ShelvesDesign.Spacing.xl)
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: ShelvesDesign.Spacing.lg) {
            Spacer()
            
            Image(systemName: "questionmark.folder")
                .font(.system(size: 48))
                .foregroundColor(ShelvesDesign.Colors.chestnut.opacity(0.6))
            
            VStack(spacing: ShelvesDesign.Spacing.sm) {
                Text("No Books Found")
                    .font(ShelvesDesign.Typography.headlineLarge)
                    .foregroundColor(ShelvesDesign.Colors.sepia)
                
                Text("Try adjusting your search terms or category")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.slateGray)
                    .multilineTextAlignment(.center)
            }
            
            if !suggestedSearches.isEmpty {
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.sm) {
                    Text("Did you mean:")
                        .font(ShelvesDesign.Typography.labelMedium)
                        .foregroundColor(ShelvesDesign.Colors.warmBlack)
                    
                    ForEach(suggestedSearches.prefix(3), id: \.self) { suggestion in
                        Button(suggestion) {
                            searchText = suggestion
                        }
                        .font(ShelvesDesign.Typography.bodyMedium)
                        .foregroundColor(ShelvesDesign.Colors.antiqueGold)
                    }
                }
                .padding(.top, ShelvesDesign.Spacing.md)
            }
            
            Spacer()
        }
        .padding(.horizontal, ShelvesDesign.Spacing.xl)
    }
    
    // MARK: - Helper Methods
    
    private func matchesAny(book: Book, searchText: String) -> Bool {
        return (book.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
               (book.author?.localizedCaseInsensitiveContains(searchText) ?? false) ||
               (book.genre?.localizedCaseInsensitiveContains(searchText) ?? false) ||
               (book.isbn?.localizedCaseInsensitiveContains(searchText) ?? false)
    }
    
    private func addToRecentSearches(_ search: String) {
        recentSearches.removeAll { $0 == search }
        recentSearches.insert(search, at: 0)
        recentSearches = Array(recentSearches.prefix(10))
        saveRecentSearches()
    }
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }
    
    private func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }
}

// MARK: - Supporting Components

struct SearchCategoryChip: View {
    let category: SearchView.SearchCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ShelvesDesign.Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.rawValue)
                    .font(ShelvesDesign.Typography.labelMedium)
            }
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

struct RecentSearchRow: View {
    let searchText: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16))
                    .foregroundColor(ShelvesDesign.Colors.chestnut)
                
                Text(searchText)
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(ShelvesDesign.Colors.slateGray.opacity(0.6))
            }
            .padding(ShelvesDesign.Spacing.md)
            .background(
                WarmCardBackground()
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickAccessCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: ShelvesDesign.Spacing.md) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(ShelvesDesign.Typography.titleSmall)
                        .foregroundColor(ShelvesDesign.Colors.warmBlack)
                }
                
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text(title)
                        .font(ShelvesDesign.Typography.headlineSmall)
                        .foregroundColor(ShelvesDesign.Colors.warmBlack)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(count == 1 ? "1 book" : "\(count) books")
                        .font(ShelvesDesign.Typography.bodySmall)
                        .foregroundColor(ShelvesDesign.Colors.slateGray)
                        .frame(maxWidth: .infinity, alignment: .leading)
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

struct SearchResultRow: View {
    let book: Book
    let searchText: String
    
    var body: some View {
        HStack(spacing: ShelvesDesign.Spacing.md) {
            // Book cover/spine
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
            .frame(width: 40, height: 56)
            .clipped()
            .cornerRadius(ShelvesDesign.CornerRadius.small)
            
            // Book details
            VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                Text(highlightedText(book.title ?? "Unknown Title", searchText: searchText))
                    .font(ShelvesDesign.Typography.headlineSmall)
                    .lineLimit(2)
                
                if let author = book.author {
                    Text(highlightedText(author, searchText: searchText))
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
                    
                    if let genre = book.genre {
                        StatusPill(text: genre, color: ShelvesDesign.Colors.chestnut)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
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
    
    private func highlightedText(_ text: String, searchText: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        if let range = text.range(of: searchText, options: .caseInsensitive) {
            let nsRange = NSRange(range, in: text)
            if let attributedRange = Range(nsRange, in: attributedString) {
                attributedString[attributedRange].foregroundColor = ShelvesDesign.Colors.antiqueGold
                attributedString[attributedRange].font = .boldSystemFont(ofSize: 16)
            }
        }
        
        return attributedString
    }
}

#Preview {
    SearchView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}