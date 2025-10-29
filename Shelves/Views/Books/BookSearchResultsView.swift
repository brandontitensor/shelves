import SwiftUI

struct BookSearchResultsView: View {
    let searchResults: [BookSearchResult]
    let onSelect: (BookSearchResult) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)

                        Text("Select Your Book")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Found \(searchResults.count) possible matches")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    // Results list
                    ForEach(searchResults) { result in
                        BookSearchResultCard(result: result) {
                            onSelect(result)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Search Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BookSearchResultCard: View {
    let result: BookSearchResult
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 16) {
                // Cover image
                AsyncImage(url: URL(string: result.coverURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        placeholderCover
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        placeholderCover
                    @unknown default:
                        placeholderCover
                    }
                }
                .frame(width: 80, height: 120)

                // Book info
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(result.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if let publishYear = result.publishYear {
                        Text(publishYear)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Match confidence indicator
                    HStack(spacing: 4) {
                        Image(systemName: matchIcon)
                            .font(.caption)
                        Text("\(Int(result.matchScore * 100))% match")
                            .font(.caption)
                    }
                    .foregroundColor(matchColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(matchColor.opacity(0.1))
                    .cornerRadius(8)
                }

                Spacer()

                // Selection indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var placeholderCover: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 80, height: 120)
            .overlay(
                Image(systemName: "book.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            )
    }

    private var matchIcon: String {
        if result.matchScore >= 0.85 {
            return "checkmark.circle.fill"
        } else if result.matchScore >= 0.70 {
            return "checkmark.circle"
        } else {
            return "questionmark.circle"
        }
    }

    private var matchColor: Color {
        if result.matchScore >= 0.85 {
            return .green
        } else if result.matchScore >= 0.70 {
            return .orange
        } else {
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleResults = [
        BookSearchResult(
            title: "The Adventures of Huckleberry Finn",
            author: "Mark Twain",
            isbn: "9780486280615",
            coverURL: nil,
            publishYear: "1885",
            matchScore: 0.95
        ),
        BookSearchResult(
            title: "Adventures of Huckleberry Finn",
            author: "Mark Twain",
            isbn: "9780143107323",
            coverURL: nil,
            publishYear: "2014",
            matchScore: 0.88
        ),
        BookSearchResult(
            title: "Huckleberry Finn",
            author: "Mark Twain",
            isbn: "9780192834317",
            coverURL: nil,
            publishYear: "1999",
            matchScore: 0.72
        )
    ]

    return BookSearchResultsView(searchResults: sampleResults) { result in
        print("Selected: \(result.title)")
    }
}
