import SwiftUI
import CoreData

struct DuplicateDetectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.title, ascending: true)],
        animation: .default)
    private var books: FetchedResults<Book>
    
    @State private var duplicateGroups: [[Book]] = []
    @State private var isScanning = false
    @State private var showingMergeAlert = false
    @State private var selectedGroup: [Book] = []
    @State private var primaryBook: Book?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isScanning {
                    scanningView
                } else if duplicateGroups.isEmpty {
                    emptyStateView
                } else {
                    duplicatesListView
                }
            }
            .navigationTitle("Duplicate Detection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Scan Again") {
                        scanForDuplicates()
                    }
                    .disabled(isScanning)
                }
            }
            .onAppear {
                if duplicateGroups.isEmpty {
                    scanForDuplicates()
                }
            }
            .alert("Merge Duplicates", isPresented: $showingMergeAlert) {
                Button("Merge", role: .destructive) {
                    mergeDuplicates()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will keep the selected book and remove the duplicates. This action cannot be undone.")
            }
        }
    }
    
    private var scanningView: some View {
        VStack(spacing: ShelvesDesign.Spacing.xl) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: ShelvesDesign.Colors.antiqueGold))
            
            VStack(spacing: ShelvesDesign.Spacing.md) {
                Text("Scanning for Duplicates")
                    .font(ShelvesDesign.Typography.titleMedium)
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                
                Text("Analyzing your library for potential duplicate books...")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.sepia)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(ShelvesDesign.Spacing.xl)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: ShelvesDesign.Spacing.xl) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(ShelvesDesign.Colors.forestGreen)
            
            VStack(spacing: ShelvesDesign.Spacing.md) {
                Text("No Duplicates Found")
                    .font(ShelvesDesign.Typography.titleMedium)
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                
                Text("Your library is clean! No duplicate books were detected.")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.sepia)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(ShelvesDesign.Spacing.xl)
    }
    
    private var duplicatesListView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: ShelvesDesign.Spacing.md) {
                Text("\(duplicateGroups.count) Duplicate Group\(duplicateGroups.count == 1 ? "" : "s") Found")
                    .font(ShelvesDesign.Typography.titleMedium)
                    .foregroundColor(ShelvesDesign.Colors.warmBlack)
                
                Text("Review and merge duplicate books to keep your library organized")
                    .font(ShelvesDesign.Typography.bodyMedium)
                    .foregroundColor(ShelvesDesign.Colors.sepia)
                    .multilineTextAlignment(.center)
            }
            .padding(ShelvesDesign.Spacing.lg)
            
            // Duplicates list
            List {
                ForEach(Array(duplicateGroups.enumerated()), id: \.offset) { index, group in
                    DuplicateGroupView(
                        books: group,
                        onMerge: { primaryBook in
                            self.primaryBook = primaryBook
                            self.selectedGroup = group
                            showingMergeAlert = true
                        }
                    )
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func scanForDuplicates() {
        isScanning = true
        
        DispatchQueue.global(qos: .background).async {
            let allBooks = Array(books)
            let foundDuplicates = DuplicateDetectionService.shared.findDuplicates(in: allBooks)
            
            DispatchQueue.main.async {
                self.duplicateGroups = foundDuplicates
                self.isScanning = false
            }
        }
    }
    
    private func mergeDuplicates() {
        guard let primary = primaryBook else { return }
        
        // Keep the primary book and remove duplicates
        for book in selectedGroup {
            if book != primary {
                viewContext.delete(book)
            }
        }
        
        do {
            try viewContext.save()
            // Remove this group from the list
            if let groupIndex = duplicateGroups.firstIndex(where: { $0.contains(primary) }) {
                duplicateGroups.remove(at: groupIndex)
            }
        } catch {
            print("Error merging duplicates: \(error)")
        }
    }
}

struct DuplicateGroupView: View {
    let books: [Book]
    let onMerge: (Book) -> Void
    
    @State private var selectedPrimary: Book?
    
    var body: some View {
        VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.md) {
            Text("Potential Duplicates")
                .font(ShelvesDesign.Typography.headlineSmall)
                .foregroundColor(ShelvesDesign.Colors.warmBlack)
            
            ForEach(books, id: \.objectID) { book in
                DuplicateBookRow(
                    book: book,
                    isSelected: selectedPrimary == book
                ) {
                    selectedPrimary = book
                }
            }
            
            if let primary = selectedPrimary {
                Button("Merge Duplicates") {
                    onMerge(primary)
                }
                .buttonStyle(.borderedProminent)
                .tint(ShelvesDesign.Colors.antiqueGold)
            }
        }
        .padding(ShelvesDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.medium)
                .fill(ShelvesDesign.Colors.paleBeige.opacity(0.3))
        )
        .onAppear {
            selectedPrimary = books.first
        }
    }
}

struct DuplicateBookRow: View {
    let book: Book
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: ShelvesDesign.Spacing.md) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? ShelvesDesign.Colors.antiqueGold : ShelvesDesign.Colors.slateGray)
                
                VStack(alignment: .leading, spacing: ShelvesDesign.Spacing.xs) {
                    Text(book.title ?? "Unknown Title")
                        .font(ShelvesDesign.Typography.labelLarge)
                        .foregroundColor(ShelvesDesign.Colors.warmBlack)
                        .lineLimit(1)
                    
                    if let author = book.author {
                        Text("by \(author)")
                            .font(ShelvesDesign.Typography.bodySmall)
                            .foregroundColor(ShelvesDesign.Colors.sepia)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        if let isbn = book.isbn, !isbn.isEmpty {
                            Text("ISBN: \(isbn)")
                                .font(ShelvesDesign.Typography.bodySmall)
                                .foregroundColor(ShelvesDesign.Colors.slateGray)
                        }
                        
                        Spacer()
                        
                        Text(book.libraryName ?? "Unknown Library")
                            .font(ShelvesDesign.Typography.bodySmall)
                            .foregroundColor(ShelvesDesign.Colors.slateGray)
                    }
                }
                
                Spacer()
            }
            .padding(ShelvesDesign.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ShelvesDesign.CornerRadius.small)
                    .fill(isSelected ? ShelvesDesign.Colors.antiqueGold.opacity(0.1) : Color.clear)
                    .stroke(isSelected ? ShelvesDesign.Colors.antiqueGold : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}