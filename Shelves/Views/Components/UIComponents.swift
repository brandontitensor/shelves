import SwiftUI
import CoreData

struct RecommendationCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        animation: .default)
    private var allBooks: FetchedResults<Book>
    
    var body: some View {
        let booksArray = Array(allBooks)
        let recommendedBook = RecommendationService.getWeeklyRecommendation(from: booksArray)
        let recommendation = RecommendationService.getRecommendationText(for: recommendedBook)
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Weekly Recommendation")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            Text(recommendation.title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(recommendation.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            if let book = recommendedBook {
                HStack(spacing: 8) {
                    AsyncImage(url: book.coverImageURL.flatMap(URL.init)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "book.closed")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            )
                    }
                    .frame(width: 30, height: 45)
                    .cornerRadius(4)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title ?? "Unknown Title")
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        if let author = book.author {
                            Text(author)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CurrentlyReadingCard: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: book.coverImageURL.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "book.closed")
                            .foregroundColor(.secondary)
                    )
            }
            .frame(width: 80, height: 120)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title ?? "Unknown Title")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text(book.author ?? "Unknown Author")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(.blue)
                    Text("Continue Reading")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

