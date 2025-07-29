import SwiftUI
import CoreData

struct BookDetailView: View {
    let book: Book
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingEditView = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                bookHeaderSection
                readingStatusSection
                bookInfoSection
                if let summary = book.summary, !summary.isEmpty {
                    summarySection
                }
                personalNotesSection
            }
            .padding()
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditBookView(book: book)
        }
    }
    
    private var bookHeaderSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                BookCoverImage(book: book, style: .detail)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title ?? "Unknown Title")
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(3)
                    
                    if let author = book.author {
                        Text("by \(author)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    if let genre = book.genre {
                        Text(genre)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
    
    private var readingStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Status tags - only show selected ones
            let statusTags = getStatusTags()
            if !statusTags.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], alignment: .leading, spacing: 8) {
                    ForEach(statusTags, id: \.title) { tag in
                        StatusTag(title: tag.title, color: tag.color)
                    }
                }
            } else {
                Text("No status selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            if book.isRead && book.rating > 0 {
                HStack {
                    Text("Rating:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= Int(book.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    Text(String(format: "%.1f", book.rating))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var bookInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Book Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                if let publishedDate = book.publishedDate, !publishedDate.isEmpty {
                    InfoRow(label: "Published", value: publishedDate)
                }
                
                if book.pageCount > 0 {
                    InfoRow(label: "Pages", value: "\(book.pageCount)")
                }
                
                if let size = book.size {
                    InfoRow(label: "Size", value: size)
                }
                
                if let isbn = book.isbn {
                    InfoRow(label: "ISBN", value: isbn)
                }
                
                InfoRow(label: "Added", value: book.dateAdded?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(book.summary ?? "")
                .font(.body)
                .lineLimit(nil)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var personalNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Notes")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let notes = book.personalNotes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .lineLimit(nil)
            } else {
                Text("No notes yet. Tap 'Edit' to add your thoughts about this book.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getStatusTags() -> [(title: String, color: Color)] {
        var tags: [(title: String, color: Color)] = []
        
        if book.isWantToRead {
            tags.append((title: "Want to Read", color: .orange))
        }
        
        if book.currentlyReading {
            tags.append((title: "Currently Reading", color: .blue))
        }
        
        if book.isRead {
            tags.append((title: "Finished", color: .green))
        }
        
        if book.isOwned {
            tags.append((title: "Owned", color: .indigo))
        }
        
        if book.isWantToBuy {
            tags.append((title: "Want to Buy", color: .purple))
        }
        
        return tags
    }
    
}

struct StatusTag: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .cornerRadius(20)
    }
}


struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
    }
}