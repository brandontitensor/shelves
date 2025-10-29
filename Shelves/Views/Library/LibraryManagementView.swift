import SwiftUI
import CoreData

struct LibraryManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.libraryName, ascending: true)],
        animation: .default)
    private var books: FetchedResults<Book>
    
    @State private var libraries: [String] = []
    @State private var showingAddLibrary = false
    @State private var newLibraryName = ""
    @State private var selectedLibrary = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: ShelvesDesign.Spacing.md) {
                    Text("Manage Libraries")
                        .font(ShelvesDesign.Typography.titleMedium)
                        .foregroundColor(ShelvesDesign.Colors.warmBlack)
                    
                    Text("Organize your books across different library locations")
                        .font(ShelvesDesign.Typography.bodyMedium)
                        .foregroundColor(ShelvesDesign.Colors.sepia)
                        .multilineTextAlignment(.center)
                }
                .padding(ShelvesDesign.Spacing.lg)
                
                // Libraries list
                List {
                    ForEach(libraries, id: \.self) { library in
                        LibraryRow(
                            libraryName: library,
                            bookCount: books.filter { $0.libraryName == library }.count
                        ) {
                            selectedLibrary = library
                            showingDeleteAlert = true
                        }
                    }
                    .onDelete(perform: deleteLibraries)
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Library") {
                        showingAddLibrary = true
                    }
                }
            }
            .onAppear {
                loadLibraries()
            }
            .sheet(isPresented: $showingAddLibrary) {
                AddLibrarySheet(
                    newLibraryName: $newLibraryName,
                    isPresented: $showingAddLibrary
                ) {
                    addLibrary()
                }
            }
            .alert("Delete Library", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteLibrary(selectedLibrary)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete '\(selectedLibrary)'? Books in this library will be moved to 'Home Library'.")
            }
        }
    }
    
    private func loadLibraries() {
        let libraryNames = Set(books.compactMap { $0.libraryName })
        libraries = Array(libraryNames).sorted()
        
        if libraries.isEmpty {
            libraries = ["Home Library"]
        }
    }
    
    private func addLibrary() {
        guard !newLibraryName.isEmpty && !libraries.contains(newLibraryName) else { return }
        
        libraries.append(newLibraryName)
        libraries.sort()
        newLibraryName = ""
    }
    
    private func deleteLibraries(offsets: IndexSet) {
        for index in offsets {
            let libraryToDelete = libraries[index]
            deleteLibrary(libraryToDelete)
        }
    }
    
    private func deleteLibrary(_ libraryName: String) {
        // Move books to Home Library
        let booksToMove = books.filter { $0.libraryName == libraryName }
        for book in booksToMove {
            book.libraryName = "Home Library"
        }
        
        try? viewContext.save()
        
        // Remove from libraries list
        if let index = libraries.firstIndex(of: libraryName) {
            libraries.remove(at: index)
        }
    }
}

struct LibraryRow: View {
    let libraryName: String
    let bookCount: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                Text(libraryName)
                    .font(ShelvesDesign.Typography.labelLarge)
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                
                Text("\(bookCount) book\(bookCount == 1 ? "" : "s")")
                    .font(ShelvesDesign.Typography.bodySmall)
                    .foregroundColor(ShelvesDesign.Colors.sepia)
            }
            
            Spacer()
            
            if libraryName != "Home Library" {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, ShelvesDesign.Spacing.sm)
    }
}

struct AddLibrarySheet: View {
    @Binding var newLibraryName: String
    @Binding var isPresented: Bool
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: ShelvesDesign.Spacing.lg) {
                Text("Add New Library")
                    .font(ShelvesDesign.Typography.titleMedium)
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                
                TextField("Library name", text: $newLibraryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                        newLibraryName = ""
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        isPresented = false
                    }
                    .disabled(newLibraryName.isEmpty)
                }
            }
        }
    }
}