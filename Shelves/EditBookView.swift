import SwiftUI
import CoreData

struct EditBookView: View {
    let book: Book
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var author = ""
    @State private var publishedDate = ""
    @State private var pageCount = ""
    @State private var genre = ""
    @State private var coverImageURL = ""
    @State private var summary = ""
    @State private var personalNotes = ""
    @State private var bookSize = ""
    @State private var rating: Float = 0
    @State private var isRead = false
    @State private var currentlyReading = false
    
    let bookSizes = ["Pocket", "Mass Market", "Trade Paperback", "Hardcover", "Large Print", "Unknown"]
    
    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                readingStatusSection
                additionalDetailsSection
                personalSection
            }
            .navigationTitle("Edit Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                loadBookData()
            }
        }
    }
    
    private var basicInfoSection: some View {
        Section("Book Information") {
            TextField("Title", text: $title)
                .textContentType(.name)
            
            TextField("Author", text: $author)
                .textContentType(.name)
            
            TextField("Published Date", text: $publishedDate)
                .textContentType(.dateTime)
            
            TextField("Page Count", text: $pageCount)
                .keyboardType(.numberPad)
            
            TextField("Genre", text: $genre)
            
            TextField("Cover Image URL", text: $coverImageURL)
                .textContentType(.URL)
                .autocapitalization(.none)
            
            TextField("Summary", text: $summary, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private var readingStatusSection: some View {
        Section("Reading Status") {
            Toggle("Currently Reading", isOn: $currentlyReading)
                .onChange(of: currentlyReading) { _, newValue in
                    if newValue {
                        isRead = false
                        rating = 0
                    }
                }
            
            Toggle("Finished Reading", isOn: $isRead)
                .onChange(of: isRead) { _, newValue in
                    if newValue {
                        currentlyReading = false
                    } else {
                        rating = 0
                    }
                }
            
            if isRead {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rating: \(String(format: "%.1f", rating))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
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
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var additionalDetailsSection: some View {
        Section("Additional Details") {
            Picker("Book Size", selection: $bookSize) {
                ForEach(bookSizes, id: \.self) { size in
                    Text(size).tag(size)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var personalSection: some View {
        Section("Personal Notes") {
            TextField("Your thoughts about this book...", text: $personalNotes, axis: .vertical)
                .lineLimit(4...8)
        }
    }
    
    private func loadBookData() {
        title = book.title ?? ""
        author = book.author ?? ""
        publishedDate = book.publishedDate ?? ""
        pageCount = book.pageCount > 0 ? String(book.pageCount) : ""
        genre = book.genre ?? ""
        coverImageURL = book.coverImageURL ?? ""
        summary = book.summary ?? ""
        personalNotes = book.personalNotes ?? ""
        bookSize = book.size ?? "Unknown"
        rating = book.rating
        isRead = book.isRead
        currentlyReading = book.currentlyReading
    }
    
    private func saveChanges() {
        book.title = title.isEmpty ? "Unknown Title" : title
        book.author = author.isEmpty ? nil : author
        book.publishedDate = publishedDate.isEmpty ? nil : publishedDate
        book.pageCount = Int32(pageCount) ?? 0
        book.genre = genre.isEmpty ? nil : genre
        book.coverImageURL = coverImageURL.isEmpty ? nil : coverImageURL
        book.summary = summary.isEmpty ? nil : summary
        book.personalNotes = personalNotes.isEmpty ? nil : personalNotes
        book.size = bookSize == "Unknown" ? nil : bookSize
        book.rating = rating
        book.isRead = isRead
        book.currentlyReading = currentlyReading
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
}