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
    @State private var isWantToRead = false
    @State private var isWantToBuy = false
    @State private var currentlyReading = false
    @State private var format = "Physical"
    @State private var showingSaveConfirmation = false
    @State private var showingCoverOptions = false
    @State private var selectedCoverImage: UIImage?
    @State private var showingCustomLibraryInput = false
    @State private var customLibraryName = ""
    
    #if canImport(UIKit)
    @State private var showingImagePicker = false
    @State private var showingPhotoLibrary = false
    #endif
    
    let bookSizes = ["Pocket", "Mass Market", "Trade Paperback", "Hardcover", "Large Print", "Unknown"]
    let bookFormats = ["Physical", "Ebook", "Audiobook"]
    
    private var predefinedLibraries: [String] {
        ["Home Library", "Wishlist", "Borrowed Books", "Work Library", "Vacation Reading"]
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
            #if canImport(UIKit)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedCoverImage, isPresented: $showingImagePicker, sourceType: .camera)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                ImagePicker(image: $selectedCoverImage, isPresented: $showingPhotoLibrary, sourceType: .photoLibrary)
            }
            #endif
            .confirmationDialog("Update Book Cover", isPresented: $showingCoverOptions, titleVisibility: .visible) {
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
            .alert("Book Updated Successfully!", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your changes have been saved.")
            }
            .alert("Add New Library", isPresented: $showingCustomLibraryInput) {
                TextField("Library name", text: $customLibraryName)
                Button("Add") {
                    if !customLibraryName.isEmpty {
                        book.libraryName = customLibraryName
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
            TextField("Title", text: $title)
                .textContentType(.name)
            
            TextField("Author", text: $author)
                .textContentType(.name)
            
            TextField("Published Date", text: $publishedDate)
                .textContentType(.dateTime)
            
            TextField("Page Count", text: $pageCount)
                .keyboardType(.numberPad)
            
            TextField("Genre", text: $genre)
            
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
                    Button("Update Cover") {
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
                    } else if !coverImageURL.isEmpty, let url = URL(string: coverImageURL) {
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
            
            TextField("Summary", text: $summary, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private var readingStatusSection: some View {
        Section("Reading Status") {
            Toggle("Want to Read", isOn: $isWantToRead)
                .onChange(of: isWantToRead) { _, newValue in
                    if newValue {
                        currentlyReading = false
                        isRead = false
                        rating = 0
                    }
                }
            
            Toggle("Currently Reading", isOn: $currentlyReading)
                .onChange(of: currentlyReading) { _, newValue in
                    if newValue {
                        isRead = false
                        isWantToRead = false
                        rating = 0
                    }
                }
            
            Toggle("Finished Reading", isOn: $isRead)
                .onChange(of: isRead) { _, newValue in
                    if newValue {
                        currentlyReading = false
                        isWantToRead = false
                    } else {
                        rating = 0
                    }
                }
            
            Toggle("Want to Buy", isOn: $isWantToBuy)
            
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
            
            HStack {
                Text("Library:")
                Spacer()
                Picker("Library", selection: Binding(
                    get: { book.libraryName ?? "Home Library" },
                    set: { newValue in
                        if newValue == "Add New Library..." {
                            showingCustomLibraryInput = true
                        } else {
                            book.libraryName = newValue
                        }
                    }
                )) {
                    ForEach(availableLibraries, id: \.self) { library in
                        Text(library).tag(library)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
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
        format = book.format ?? "Physical"
        rating = book.rating
        isRead = book.isRead
        isWantToRead = book.isWantToRead ?? false
        isWantToBuy = book.isWantToBuy ?? false
        currentlyReading = book.currentlyReading
    }
    
    private func saveChanges() {
        print("📚 Starting edit save process...")
        book.title = title.isEmpty ? "Unknown Title" : title
        book.author = author.isEmpty ? nil : author
        book.publishedDate = publishedDate.isEmpty ? nil : publishedDate
        book.pageCount = Int32(pageCount) ?? 0
        book.genre = genre.isEmpty ? nil : genre
        book.summary = summary.isEmpty ? nil : summary
        book.personalNotes = personalNotes.isEmpty ? nil : personalNotes
        book.size = bookSize == "Unknown" ? nil : bookSize
        book.format = format
        book.rating = rating
        book.isRead = isRead
        book.isWantToRead = isWantToRead
        book.isWantToBuy = isWantToBuy
        book.currentlyReading = currentlyReading
        
        // Update dateRead when marking as read
        if isRead && book.dateRead == nil {
            book.dateRead = Date()
        } else if !isRead {
            book.dateRead = nil
        }
        
        // Handle custom cover image
        if let selectedImage = selectedCoverImage {
            // Save image to documents directory and update URL
            if let imageURL = saveImageToDocuments(selectedImage) {
                book.coverImageURL = imageURL.absoluteString
            }
        } else if !coverImageURL.isEmpty {
            book.coverImageURL = coverImageURL
        }
        
        do {
            try viewContext.save()
            print("✅ Book updated successfully in Core Data")
            
            // Ensure the alert shows and then dismisses the view
            DispatchQueue.main.async {
                self.showingSaveConfirmation = true
            }
        } catch {
            print("❌ Failed to save changes: \(error.localizedDescription)")
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