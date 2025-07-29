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
    @State private var isWantToRead = false
    @State private var isWantToBuy = false
    @State private var rating: Float = 0
    @State private var bookSize = "Unknown"
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var libraryName = "Home Library"
    @State private var showingCustomLibraryInput = false
    @State private var customLibraryName = ""
    @State private var format = "Physical"
    @State private var showingSaveConfirmation = false
    @State private var showingDuplicateAlert = false
    @State private var duplicateBooks: [Book] = []
    @State private var coverImageURL: String?
    @State private var showingCoverOptions = false
    @State private var selectedCoverImage: UIImage?
    
    #if canImport(UIKit)
    @State private var showingImagePicker = false
    @State private var showingPhotoLibrary = false
    @State private var capturedImage: UIImage?
    #endif
    
    private let bookSizes = ["Pocket", "Mass Market", "Trade Paperback", "Hardcover", "Large Print", "Unknown"]
    private let bookFormats = ["Physical", "Ebook", "Audiobook"]
    
    private var predefinedLibraries: [String] {
        ["Home Library", "Work Library", "Vacation Reading"]
    }
    
    private var availableLibraries: [String] {
        // Get existing libraries from Core Data
        let request: NSFetchRequest<Book> = Book.fetchRequest()
        do {
            let books = try viewContext.fetch(request)
            let existingLibraries = Set(books.compactMap { $0.libraryName })
            let allLibraries = Set(predefinedLibraries).union(existingLibraries)
            return Array(allLibraries).sorted() + ["Add New Library..."]
        } catch {
            return predefinedLibraries + ["Add New Library..."]
        }
    }
    
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
                    .foregroundColor(title.isEmpty ? .gray : .blue)
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
                ImagePicker(image: $selectedCoverImage, isPresented: $showingImagePicker, sourceType: .camera)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                ImagePicker(image: $selectedCoverImage, isPresented: $showingPhotoLibrary, sourceType: .photoLibrary)
            }
            .onChange(of: capturedImage) { _, image in
                if let image = image {
                    bookSize = BookSizeEstimator.estimateSize(from: image)
                }
            }
            #endif
            .alert("Book Saved Successfully!", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your book has been added to your library.")
            }
            .alert("Possible Duplicate Book", isPresented: $showingDuplicateAlert) {
                Button("Add Anyway") {
                    performSave()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if duplicateBooks.count == 1 {
                    let bookTitle = duplicateBooks[0].title ?? "Unknown Title"
                    let bookAuthor = duplicateBooks[0].author ?? "Unknown Author"
                    Text("You already have a similar book in your library: \"\(bookTitle)\" by \(bookAuthor). Would you like to add this book anyway?")
                } else {
                    Text("You already have \(duplicateBooks.count) similar books in your library. Would you like to add this book anyway?")
                }
            }
            .confirmationDialog("Add Book Cover", isPresented: $showingCoverOptions, titleVisibility: .visible) {
                #if canImport(UIKit)
                Button("Take Photo") {
                    showingImagePicker = true
                }
                Button("Choose from Library") {
                    showingPhotoLibrary = true
                }
                #endif
                Button("Cancel", role: .cancel) { }
            }
            .alert("Add New Library", isPresented: $showingCustomLibraryInput) {
                TextField("Library name", text: $customLibraryName)
                Button("Add") {
                    if !customLibraryName.isEmpty {
                        libraryName = customLibraryName
                        customLibraryName = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    customLibraryName = ""
                }
            } message: {
                Text("Enter the name for your new library.")
            }
        }
    }
    
    private var basicInfoSection: some View {
        Section("Book Information") {
            TextField("ISBN (enter to auto-fill)", text: $isbnText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit {
                    if !isbnText.isEmpty {
                        fetchBookData(isbn: isbnText)
                    }
                }
            
            // Book Format Picker
            Picker("Format", selection: $format) {
                ForEach(bookFormats, id: \.self) { format in
                    Text(format).tag(format)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Book Cover Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Book Cover")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button("Add Cover") {
                        showingCoverOptions = true
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    // Cover preview
                    if let selectedImage = selectedCoverImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 70)
                            .cornerRadius(8)
                    } else if let urlString = coverImageURL, !urlString.isEmpty, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "book.closed")
                                        .foregroundColor(.gray)
                                )
                        }
                        .frame(width: 50, height: 70)
                        .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "book.closed")
                                    .foregroundColor(.gray)
                            )
                            .frame(width: 50, height: 70)
                            .cornerRadius(8)
                    }
                }
            }
            
            TextField("Title *", text: $title)
            if title.isEmpty {
                Text("Title is required to save")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            TextField("Author", text: $author)
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
            
            HStack {
                Text("Library:")
                Spacer()
                Picker("Library", selection: $libraryName) {
                    ForEach(availableLibraries, id: \.self) { library in
                        Text(library).tag(library)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: libraryName) { _, newValue in
                    if newValue == "Add New Library..." {
                        showingCustomLibraryInput = true
                        libraryName = "Home Library" // Reset to default
                    }
                }
            }
        }
    }
    
    private var readingStatusSection: some View {
        Section("Reading Status") {
            Toggle("Want to Read", isOn: $isWantToRead)
                .onChange(of: isWantToRead) { _, newValue in
                    if newValue {
                        isRead = false
                    }
                }
            
            Toggle("I've read this book", isOn: $isRead)
                .onChange(of: isRead) { _, newValue in
                    if newValue {
                        isWantToRead = false
                    }
                }
            
            Toggle("Want to Buy", isOn: $isWantToBuy)
            
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
                        coverImageURL = bookData.coverImageURL
                        isLoading = false
                        print("🖼️ Fetched book data and cover for: \(bookData.title)")
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
        print("📚 Starting save process...")
        print("📝 Title: '\(title)' (isEmpty: \(title.isEmpty))")
        print("👤 Author: '\(author)'")
        
        // Check for duplicates first
        checkForDuplicates { shouldProceed in
            print("🔍 Duplicate check result: shouldProceed = \(shouldProceed)")
            if shouldProceed {
                performSave()
            } else {
                print("⚠️ Save cancelled due to duplicate detection")
            }
        }
    }
    
    private func checkForDuplicates(completion: @escaping (Bool) -> Void) {
        let request: NSFetchRequest<Book> = Book.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        // Check for same title and author
        if !title.isEmpty && !author.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ AND author CONTAINS[cd] %@", title, author))
        }
        
        // Check for same ISBN if provided
        if !isbnText.isEmpty {
            predicates.append(NSPredicate(format: "isbn == %@", isbnText))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
            
            do {
                let results = try viewContext.fetch(request)
                print("🔍 Found \(results.count) potential duplicates")
                if !results.isEmpty {
                    duplicateBooks = results
                    showingDuplicateAlert = true
                    completion(false)
                    return
                }
            } catch {
                print("Error checking for duplicates: \(error)")
            }
        } else {
            print("🔍 No predicates for duplicate checking - proceeding with save")
        }
        
        completion(true)
    }
    
    private func performSave() {
        print("💾 performSave() called - creating new book...")
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
        newBook.isWantToRead = isWantToRead
        newBook.isWantToBuy = isWantToBuy
        newBook.rating = isRead ? rating : 0
        newBook.size = bookSize
        newBook.format = format
        newBook.dateAdded = Date()
        newBook.dateRead = isRead ? Date() : nil
        newBook.libraryName = libraryName.isEmpty ? "Home Library" : libraryName
        newBook.isbn = isbnText.isEmpty ? nil : isbnText
        
        // Handle cover image
        if let selectedImage = selectedCoverImage {
            // Save custom image to documents directory
            if let imageURL = saveImageToDocuments(selectedImage) {
                newBook.coverImageURL = imageURL.absoluteString
            }
        } else {
            newBook.coverImageURL = coverImageURL
        }
        
        do {
            try viewContext.save()
            print("✅ Book saved successfully to Core Data")
            
            // Ensure the alert shows and then dismisses the view
            DispatchQueue.main.async {
                self.showingSaveConfirmation = true
            }
        } catch {
            print("❌ Failed to save book: \(error.localizedDescription)")
            errorMessage = "Failed to save book: \(error.localizedDescription)"
        }
    }
    
    private func saveImageToDocuments(_ image: UIImage) -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save image: \(error)")
            return nil
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