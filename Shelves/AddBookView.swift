import SwiftUI
import CoreData

struct AddBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let isbn: String?
    
    @State private var title = ""
    @State private var author = ""
    @State private var isbnText = ""
    @State private var publishedDate = ""
    @State private var pageCount = ""
    @State private var genre = ""
    @State private var summary = ""
    @State private var personalNotes = ""
    @State private var isRead = false
    @State private var rating: Float = 0
    @State private var bookSize = "Unknown"
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var libraryName = "Home Library"
    
    #if canImport(UIKit)
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage?
    #endif
    
    private let bookSizes = ["Pocket", "Mass Market", "Trade Paperback", "Hardcover", "Large Print", "Unknown"]
    
    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                additionalDetailsSection
                readingStatusSection
                personalSection
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBook()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let prefilledISBN = isbn {
                    self.isbnText = prefilledISBN
                    fetchBookData(isbn: prefilledISBN)
                }
            }
            #if canImport(UIKit)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $capturedImage, isPresented: $showingImagePicker, sourceType: .camera)
            }
            .onChange(of: capturedImage) { _, image in
                if let image = image {
                    bookSize = BookSizeEstimator.estimateSize(from: image)
                }
            }
            #endif
        }
    }
    
    private var basicInfoSection: some View {
        Section("Book Information") {
            TextField("Title *", text: $title)
            TextField("Author", text: $author)
            TextField("ISBN", text: $isbnText)
            TextField("Published Date", text: $publishedDate)
            TextField("Page Count", text: $pageCount)
                .keyboardType(.numberPad)
            TextField("Genre", text: $genre)
        }
    }
    
    private var additionalDetailsSection: some View {
        Section("Additional Details") {
            HStack {
                Picker("Book Size", selection: $bookSize) {
                    ForEach(bookSizes, id: \.self) { size in
                        Text(size).tag(size)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                #if canImport(UIKit)
                Button("📷 Estimate") {
                    showingImagePicker = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                #endif
            }
            
            TextField("Library", text: $libraryName)
        }
    }
    
    private var readingStatusSection: some View {
        Section("Reading Status") {
            Toggle("I've read this book", isOn: $isRead)
            
            if isRead {
                HStack {
                    Text("Rating:")
                    Spacer()
                    StarRatingView(rating: $rating)
                }
            }
        }
    }
    
    private var personalSection: some View {
        Section("Personal Notes") {
            TextField("Summary", text: $summary, axis: .vertical)
                .lineLimit(3...6)
            
            TextField("Personal thoughts and notes", text: $personalNotes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private func fetchBookData(isbn: String) {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if let bookData = try await OpenLibraryService.shared.fetchBookData(isbn: isbn) {
                    await MainActor.run {
                        title = bookData.title
                        author = bookData.author
                        publishedDate = bookData.publishedDate ?? ""
                        pageCount = bookData.pageCount.map(String.init) ?? ""
                        summary = bookData.summary ?? ""
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Book not found"
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to fetch book data: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func saveBook() {
        let newBook = Book(context: viewContext)
        newBook.id = UUID()
        newBook.title = title
        newBook.author = author.isEmpty ? nil : author
        newBook.publishedDate = publishedDate.isEmpty ? nil : publishedDate
        newBook.pageCount = Int32(pageCount) ?? 0
        newBook.genre = genre.isEmpty ? nil : genre
        newBook.summary = summary.isEmpty ? nil : summary
        newBook.personalNotes = personalNotes.isEmpty ? nil : personalNotes
        newBook.isRead = isRead
        newBook.rating = isRead ? rating : 0
        newBook.size = bookSize
        newBook.dateAdded = Date()
        newBook.libraryName = libraryName.isEmpty ? "Home Library" : libraryName
        newBook.isbn = isbnText.isEmpty ? nil : isbnText
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save book: \(error.localizedDescription)"
        }
    }
}

struct StarRatingView: View {
    @Binding var rating: Float
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Button(action: {
                    rating = Float(index)
                }) {
                    Image(systemName: index <= Int(rating) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    AddBookView(isbn: nil)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}