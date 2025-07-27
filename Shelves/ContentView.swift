import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingScanner = false
    @State private var scannedCode: String?
    @State private var showingAddBook = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        animation: .default)
    private var books: FetchedResults<Book>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        predicate: NSPredicate(format: "currentlyReading == YES"),
        animation: .default)
    private var currentlyReadingBooks: FetchedResults<Book>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    currentReadingSection
                    quickActionsSection
                    librariesSection
                }
                .padding()
            }
            .navigationTitle("Shelves")
            .navigationBarTitleDisplayMode(.large)
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showingScanner) {
            BarcodeScannerView(scannedCode: $scannedCode, isPresented: $showingScanner)
        }
        #endif
        .sheet(isPresented: $showingAddBook) {
            AddBookView(isbn: scannedCode)
        }
        .onChange(of: scannedCode) { _, isbn in
            if isbn != nil {
                showingAddBook = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Personal Library")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("A haven for your literary treasures")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var currentReadingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Currently Reading")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if currentlyReadingBooks.isEmpty {
                RecommendationCard()
            } else {
                CurrentlyReadingCard(book: currentlyReadingBooks.first!)
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                #if canImport(UIKit)
                ActionButton(
                    title: "Scan Book",
                    icon: "barcode.viewfinder",
                    color: .blue
                ) {
                    showingScanner = true
                }
                #endif
                
                ActionButton(
                    title: "Add Manually",
                    icon: "plus.circle",
                    color: .green
                ) {
                    scannedCode = nil
                    showingAddBook = true
                }
            }
        }
    }
    
    private var librariesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Books")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                NavigationLink("View All", destination: BookListSimpleView())
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(books.prefix(4)), id: \.id) { book in
                    NavigationLink(destination: BookDetailView(book: book)) {
                        BookCard(book: book)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct BookCard: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BookCoverImage(book: book, height: 120, cornerRadius: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title ?? "Unknown Title")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if let author = book.author {
                    Text(author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BookListSimpleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var showingAddBook = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        animation: .default)
    private var books: FetchedResults<Book>
    
    var filteredBooks: [Book] {
        if searchText.isEmpty {
            return Array(books)
        } else {
            return books.filter { book in
                (book.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (book.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredBooks, id: \.id) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    BookRowView(book: book)
                }
            }
        }
        .navigationTitle("All Books")
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingAddBook = true
                }
            }
        }
        .sheet(isPresented: $showingAddBook) {
            AddBookView(isbn: nil)
        }
    }
}

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 12) {
            BookCoverImage(book: book, style: .list)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title ?? "Unknown Title")
                    .font(.headline)
                    .lineLimit(2)
                
                if let author = book.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    if book.currentlyReading {
                        Text("Currently Reading")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    } else if book.isRead {
                        Text("Read")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if let libraryName = book.libraryName {
                        Text(libraryName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}