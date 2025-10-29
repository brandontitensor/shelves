import SwiftUI
import CoreData

struct AddBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    let isbn: String?
    let prefillTitle: String?
    let prefillAuthor: String?

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
    @State private var currentlyReading = false
    @State private var isOwned = true
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

    // Search section state
    @State private var searchTitle = ""
    @State private var searchAuthor = ""
    @State private var searchISBN = ""
    @State private var isSearching = false
    @State private var searchResults: [BookSearchResult] = []
    @State private var showingSearchResults = false

    #if canImport(UIKit)
    @State private var selectedCoverImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingPhotoLibrary = false
    @State private var capturedImage: UIImage?
    #endif
    
    private let bookSizes = ["Pocket", "Mass Market", "Trade Paperback", "Hardcover", "Large Print", "Unknown"]
    private let bookFormats = ["Physical", "Ebook", "Audiobook"]

    private var predefinedLibraries: [String] {
        ["Home Library", "Work Library", "Vacation Reading"]
    }

    @FetchRequest(
        sortDescriptors: [],
        animation: .default)
    private var allBooksForLibraries: FetchedResults<Book>

    private var availableLibraries: [String] {
        // Use existing FetchRequest instead of manual fetch
        let existingLibraries = Set(allBooksForLibraries.compactMap { $0.libraryName })
        let allLibraries = Set(predefinedLibraries).union(existingLibraries)
        return Array(allLibraries).sorted() + ["Add New Library..."]
    }
    
    var body: some View {
        NavigationStack {
            Form {
                searchSection
                orDividerSection
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
                    .foregroundColor(title.isEmpty ? ShelvesDesign.Colors.textSecondary : ShelvesDesign.Colors.primary)
                }
            }
            .onAppear {
                // Handle prefilled data from cover scan
                if let prefillTitle = prefillTitle {
                    self.title = prefillTitle
                }
                if let prefillAuthor = prefillAuthor {
                    self.author = prefillAuthor
                }

                // Handle ISBN prefill
                if let prefilledISBN = isbn {
                    self.isbnText = prefilledISBN
                    // Only fetch if we don't already have title/author from cover scan
                    if prefillTitle == nil && prefillAuthor == nil {
                        fetchBookData(isbn: prefilledISBN)
                    }
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
            .sheet(isPresented: $showingSearchResults) {
                if !searchResults.isEmpty {
                    BookSearchResultsView(searchResults: searchResults) { selectedBook in
                        fillFromSearchResult(selectedBook)
                        showingSearchResults = false
                    }
                }
            }
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Search for Your Book")
                    .font(.headline)
                    .foregroundColor(ShelvesDesign.Colors.text)

                Text("Enter title, author, or ISBN to search online")
                    .font(.caption)
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)

                VStack(spacing: 0) {
                    TextField("Title", text: $searchTitle)
                        .textInputAutocapitalization(.words)
                        .padding(.vertical, 8)

                    Divider()

                    TextField("Author", text: $searchAuthor)
                        .textInputAutocapitalization(.words)
                        .padding(.vertical, 8)

                    Divider()

                    TextField("ISBN", text: $searchISBN)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.numbersAndPunctuation)
                        .padding(.vertical, 8)
                }
                .padding(.vertical, 4)

                Button(action: performSearch) {
                    HStack {
                        if isSearching {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text(isSearching ? "Searching..." : "Search")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(searchButtonEnabled ? ShelvesDesign.Colors.primary : ShelvesDesign.Colors.textSecondary.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!searchButtonEnabled || isSearching)
            }
            .padding(.vertical, 8)
        }
    }

    private var searchButtonEnabled: Bool {
        !searchTitle.isEmpty || !searchAuthor.isEmpty || !searchISBN.isEmpty
    }

    private var orDividerSection: some View {
        Section {
            HStack {
                Rectangle()
                    .fill(ShelvesDesign.Colors.textSecondary.opacity(0.3))
                    .frame(height: 1)

                Text("OR")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
                    .padding(.horizontal, 12)

                Rectangle()
                    .fill(ShelvesDesign.Colors.textSecondary.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, 8)
        }
    }

    private var basicInfoSection: some View {
        Section("Manual Entry") {
            TextField("ISBN (optional)", text: $isbnText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.numbersAndPunctuation)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
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
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
                
                HStack {
                    Button("Add Cover") {
                        showingCoverOptions = true
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()

                    // Cover preview
                    coverPreviewImage
                }
            }
            
            TextField("Title *", text: $title)
            if title.isEmpty {
                Text("Title is required to save")
                    .font(.caption)
                    .foregroundColor(ShelvesDesign.Colors.textSecondary)
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
                .foregroundColor(ShelvesDesign.Colors.primary)
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
                        currentlyReading = false
                    }
                }
            
            Toggle("Currently Reading", isOn: $currentlyReading)
                .onChange(of: currentlyReading) { _, newValue in
                    if newValue {
                        isRead = false
                        isWantToRead = false
                    }
                }
            
            Toggle("I've read this book", isOn: $isRead)
                .onChange(of: isRead) { _, newValue in
                    if newValue {
                        isWantToRead = false
                        currentlyReading = false
                    }
                }
            
            Toggle("Owned", isOn: $isOwned)
                .onChange(of: isOwned) { _, newValue in
                    if newValue {
                        isWantToBuy = false
                    } else if isRead {
                        isWantToBuy = true
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
    
    private func isValidISBN(_ isbn: String) -> Bool {
        let cleanISBN = isbn.replacingOccurrences(of: "-", with: "")
                           .replacingOccurrences(of: " ", with: "")
        return cleanISBN.count == 10 || cleanISBN.count == 13
    }

    private func fetchBookData(isbn: String) {
        guard isValidISBN(isbn) else {
            errorMessage = "Invalid ISBN format. ISBN should be 10 or 13 digits."
            return
        }

        isLoading = true
        errorMessage = ""

        Task {
            do {
                let bookData = try await OpenLibraryService.shared.fetchBookData(isbn: isbn)
                await MainActor.run {
                    title = bookData.title
                    author = bookData.author
                    publishedDate = bookData.publishedDate ?? ""
                    pageCount = bookData.pageCount.map(String.init) ?? ""
                    genre = bookData.genre ?? ""
                    summary = bookData.summary ?? ""
                    coverImageURL = bookData.coverImageURL
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func performSearch() {
        isSearching = true
        errorMessage = ""

        Task {
            do {
                var results: [BookSearchResult] = []

                // Try ISBN search first if provided
                if !searchISBN.isEmpty && isValidISBN(searchISBN) {
                    let bookData = try await OpenLibraryService.shared.fetchBookData(isbn: searchISBN)
                    let result = BookSearchResult(
                        title: bookData.title,
                        author: bookData.author,
                        isbn: searchISBN,
                        coverURL: bookData.coverImageURL,
                        publishYear: bookData.publishedDate,
                        matchScore: 1.0
                    )
                    results = [result]
                } else if !searchTitle.isEmpty {
                    // Search by title and/or author (title is required)
                    results = try await OpenLibraryService.shared.searchByTitleAuthor(
                        title: searchTitle,
                        author: searchAuthor.isEmpty ? nil : searchAuthor
                    )
                } else if !searchAuthor.isEmpty {
                    // If only author is provided, search with author as title
                    results = try await OpenLibraryService.shared.searchByTitleAuthor(
                        title: searchAuthor,
                        author: nil
                    )
                }

                await MainActor.run {
                    searchResults = results
                    isSearching = false

                    if results.isEmpty {
                        errorMessage = "No results found. Try adjusting your search or add the book manually below."
                    } else {
                        showingSearchResults = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Search failed: \(error.localizedDescription)"
                    isSearching = false
                }
            }
        }
    }

    private func fillFromSearchResult(_ result: BookSearchResult) {
        // Fill basic info from search result
        title = result.title
        author = result.author
        isbnText = result.isbn ?? ""
        publishedDate = result.publishYear ?? ""
        coverImageURL = result.coverURL

        // If we have an ISBN, fetch full details
        if let isbn = result.isbn, !isbn.isEmpty {
            fetchBookData(isbn: isbn)
        }

        // Clear search fields
        searchTitle = ""
        searchAuthor = ""
        searchISBN = ""
        searchResults = []
    }

    @ViewBuilder
    private var coverPreviewImage: some View {
        #if canImport(UIKit)
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
                            .foregroundColor(ShelvesDesign.Colors.textSecondary)
                    )
            }
            .frame(width: 50, height: 70)
            .cornerRadius(8)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "book.closed")
                        .foregroundColor(ShelvesDesign.Colors.textSecondary)
                )
                .frame(width: 50, height: 70)
                .cornerRadius(8)
        }
        #else
        if let urlString = coverImageURL, !urlString.isEmpty, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "book.closed")
                            .foregroundColor(ShelvesDesign.Colors.textSecondary)
                    )
            }
            .frame(width: 50, height: 70)
            .cornerRadius(8)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "book.closed")
                        .foregroundColor(ShelvesDesign.Colors.textSecondary)
                )
                .frame(width: 50, height: 70)
                .cornerRadius(8)
        }
        #endif
    }

    private func saveBook() {
        // Check for duplicates first
        checkForDuplicates { shouldProceed in
            if shouldProceed {
                performSave()
            }
        }
    }
    
    private func checkForDuplicates(completion: @escaping (Bool) -> Void) {
        let request: NSFetchRequest<Book> = Book.fetchRequest()

        var predicates: [NSPredicate] = []

        // Check for exact ISBN match (most reliable)
        if !isbnText.isEmpty {
            predicates.append(NSPredicate(format: "isbn == %@", isbnText))
        }

        // Check for exact title and author match
        if !title.isEmpty && !author.isEmpty {
            predicates.append(NSPredicate(format: "title ==[cd] %@ AND author ==[cd] %@", title, author))
        } else if !title.isEmpty {
            // If no author, check title only
            predicates.append(NSPredicate(format: "title ==[cd] %@", title))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)

            do {
                let results = try viewContext.fetch(request)
                if !results.isEmpty {
                    duplicateBooks = results
                    showingDuplicateAlert = true
                    completion(false)
                    return
                }
            } catch {
                // Error checking for duplicates - proceed with save anyway
            }
        }

        completion(true)
    }
    
    private func performSave() {
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
        newBook.currentlyReading = currentlyReading
        newBook.isOwned = isOwned
        newBook.rating = isRead ? rating : 0
        newBook.size = bookSize
        newBook.format = format
        newBook.dateAdded = Date()
        newBook.dateRead = isRead ? Date() : nil
        newBook.libraryName = libraryName.isEmpty ? "Home Library" : libraryName
        newBook.isbn = isbnText.isEmpty ? nil : isbnText

        // Handle cover image
        #if canImport(UIKit)
        if let selectedImage = selectedCoverImage {
            // Save custom image to documents directory
            if let imageURL = saveImageToDocuments(selectedImage) {
                newBook.coverImageURL = imageURL.absoluteString
            }
        } else {
            newBook.coverImageURL = coverImageURL
        }
        #else
        newBook.coverImageURL = coverImageURL
        #endif
        
        do {
            try viewContext.save()

            // Ensure the alert shows and then dismisses the view
            DispatchQueue.main.async {
                self.showingSaveConfirmation = true
            }
        } catch {
            errorMessage = "Failed to save book: \(error.localizedDescription)"
        }
    }

    #if canImport(UIKit)
    private func saveImageToDocuments(_ image: UIImage) -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }

        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
    #endif
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
    AddBookView(isbn: nil, prefillTitle: nil, prefillAuthor: nil)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}