import Foundation

struct OpenLibraryService {
    static let shared = OpenLibraryService()
    private let baseURL = "https://openlibrary.org"
    
    private init() {}
    
    func fetchBookData(isbn: String) async throws -> BookData {
        let cleanISBN = isbn.replacingOccurrences(of: "-", with: "")
        let urlString = "\(baseURL)/api/books?bibkeys=ISBN:\(cleanISBN)&format=json&jscmd=data"
        
        guard let url = URL(string: urlString) else {
            throw OpenLibraryError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenLibraryError.networkError
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let bookDict = json?["ISBN:\(cleanISBN)"] as? [String: Any] else {
            throw OpenLibraryError.noData
        }

        return parseBookData(from: bookDict)
    }
    
    private func extractGenre(from subjects: [String]) -> String? {
        // Define primary genre patterns (most specific first)
        let primaryGenres = [
            "science fiction", "historical fiction", "literary fiction", "young adult fiction",
            "dystopian fiction", "apocalyptic fiction", "coming of age fiction", "domestic fiction",
            "contemporary fiction", "action and adventure fiction", "legal fiction",
            "fantasy", "mystery", "thriller", "romance", "horror", "western", "crime",
            "detective", "biography", "autobiography", "memoir", "poetry", "drama"
        ]
        
        // Look for exact matches with primary genres first
        for subject in subjects {
            let lowercaseSubject = subject.lowercased()
            for genre in primaryGenres {
                if lowercaseSubject == genre {
                    return subject
                }
            }
        }
        
        // Look for subjects that contain primary genre terms
        for subject in subjects {
            let lowercaseSubject = subject.lowercased()
            for genre in primaryGenres {
                if lowercaseSubject.contains(genre) {
                    return subject
                }
            }
        }
        
        // Secondary genre keywords
        let secondaryGenres = [
            "fiction", "classics", "children", "young adult", "history", "philosophy", 
            "psychology", "self-help", "health", "cooking", "travel", "religion", 
            "spirituality", "business", "politics", "science", "nature", "technology",
            "art", "music", "comedy", "adventure", "paranormal", "urban fantasy"
        ]
        
        // Look for secondary genre matches
        for subject in subjects {
            let lowercaseSubject = subject.lowercased()
            for genre in secondaryGenres {
                if lowercaseSubject == genre || lowercaseSubject.hasSuffix(" \(genre)") {
                    return subject
                }
            }
        }
        
        // Filter out geographic, temporal, and overly broad subjects
        let filteredSubjects = subjects.filter { subject in
            let lowercaseSubject = subject.lowercased()
            return !lowercaseSubject.contains("american") &&
                   !lowercaseSubject.contains("british") &&
                   !lowercaseSubject.contains("english") &&
                   !lowercaseSubject.contains("century") &&
                   !lowercaseSubject.contains("literature") &&
                   !lowercaseSubject.contains("authors") &&
                   !lowercaseSubject.contains("--") &&
                   !lowercaseSubject.contains("(") &&
                   subject.count > 3
        }
        
        // Return the first filtered subject that looks like a genre
        return filteredSubjects.first ?? subjects.first
    }
    
    private func parseBookData(from dict: [String: Any]) -> BookData {
        let title = dict["title"] as? String ?? "Unknown Title"
        
        var authors: [String] = []
        if let authorsArray = dict["authors"] as? [[String: Any]] {
            authors = authorsArray.compactMap { $0["name"] as? String }
        }
        let author = authors.first ?? "Unknown Author"
        
        let publishDate = dict["publish_date"] as? String
        let pageCount = dict["number_of_pages"] as? Int
        
        var coverImageURL: String?
        if let cover = dict["cover"] as? [String: Any],
           let medium = cover["medium"] as? String {
            coverImageURL = medium
        }
        
        // Extract genre from subjects array using intelligent genre detection
        var subjects: [String] = []
        if let subjectsArray = dict["subjects"] as? [[String: Any]] {
            subjects = subjectsArray.compactMap { $0["name"] as? String }
        }
        let genre = extractGenre(from: subjects)
        
        let summary = dict["excerpts"] as? [[String: Any]]
        let description = summary?.first?["text"] as? String
        
        return BookData(
            title: title,
            author: author,
            publishedDate: publishDate,
            pageCount: pageCount,
            genre: genre,
            coverImageURL: coverImageURL,
            summary: description
        )
    }
}

struct BookData {
    let title: String
    let author: String
    let publishedDate: String?
    let pageCount: Int?
    let genre: String?
    let coverImageURL: String?
    let summary: String?
}

// MARK: - Search Result Model

struct BookSearchResult: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let author: String
    let isbn: String?
    let coverURL: String?
    let publishYear: String?
    let matchScore: Float  // How well it matches the search query

    static func == (lhs: BookSearchResult, rhs: BookSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Title/Author Search Extension

extension OpenLibraryService {

    /// Search for books by title and optional author
    /// - Parameters:
    ///   - title: Book title to search for
    ///   - author: Optional author name
    /// - Returns: Array of search results ranked by relevance
    func searchByTitleAuthor(title: String, author: String?) async throws -> [BookSearchResult] {
        print("🔍 [OpenLibrary] Searching for title: '\(title)' author: '\(author ?? "any")'")

        // Build search query
        var queryComponents = ["title=\(title.urlEncoded)"]
        if let author = author {
            queryComponents.append("author=\(author.urlEncoded)")
        }

        let queryString = queryComponents.joined(separator: "&")
        let urlString = "https://openlibrary.org/search.json?\(queryString)&limit=10"

        guard let url = URL(string: urlString) else {
            throw OpenLibraryError.invalidURL
        }

        print("🔍 [OpenLibrary] Request URL: \(urlString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenLibraryError.networkError
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let docs = json?["docs"] as? [[String: Any]] else {
            throw OpenLibraryError.noData
        }

        print("🔍 [OpenLibrary] Found \(docs.count) results")

        // Parse and rank results
        var results: [BookSearchResult] = []

        for doc in docs {
            guard let bookTitle = doc["title"] as? String else { continue }

            // Extract author
            var bookAuthor = "Unknown Author"
            if let authorNames = doc["author_name"] as? [String], let firstAuthor = authorNames.first {
                bookAuthor = firstAuthor
            }

            // Extract ISBN (prefer ISBN-13)
            var isbn: String?
            if let isbns = doc["isbn"] as? [String] {
                // Prefer ISBN-13 (13 digits)
                isbn = isbns.first { $0.count == 13 } ?? isbns.first
            }

            // Extract cover URL
            var coverURL: String?
            if let coverID = doc["cover_i"] as? Int {
                coverURL = "https://covers.openlibrary.org/b/id/\(coverID)-M.jpg"
            }

            // Extract publish year
            var publishYear: String?
            if let firstPublishYear = doc["first_publish_year"] as? Int {
                publishYear = String(firstPublishYear)
            }

            // Calculate match score
            let matchScore = calculateMatchScore(
                searchTitle: title,
                resultTitle: bookTitle,
                searchAuthor: author,
                resultAuthor: bookAuthor
            )

            let result = BookSearchResult(
                title: bookTitle,
                author: bookAuthor,
                isbn: isbn,
                coverURL: coverURL,
                publishYear: publishYear,
                matchScore: matchScore
            )

            results.append(result)
        }

        // Sort by match score (highest first)
        results.sort { $0.matchScore > $1.matchScore }

        // Log top results
        for (index, result) in results.prefix(3).enumerated() {
            print("🔍 [OpenLibrary] Result \(index + 1): '\(result.title)' by '\(result.author)' score: \(String(format: "%.2f", result.matchScore))")
        }

        return results
    }

    private func calculateMatchScore(searchTitle: String, resultTitle: String, searchAuthor: String?, resultAuthor: String) -> Float {
        var score: Float = 0.0

        // Title similarity (60% weight)
        let titleScore = stringSimilarity(searchTitle.lowercased(), resultTitle.lowercased())
        score += titleScore * 0.6

        // Author similarity (40% weight)
        if let searchAuthor = searchAuthor {
            let authorScore = stringSimilarity(searchAuthor.lowercased(), resultAuthor.lowercased())
            score += authorScore * 0.4
        } else {
            // No author provided, give 50% of author weight
            score += 0.2
        }

        return score
    }

    /// Calculate string similarity using Levenshtein distance
    private func stringSimilarity(_ s1: String, _ s2: String) -> Float {
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        guard maxLength > 0 else { return 1.0 }

        let similarity = 1.0 - (Float(distance) / Float(maxLength))
        return max(0.0, similarity)
    }

    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2Array.count + 1), count: s1Array.count + 1)

        for i in 0...s1Array.count {
            matrix[i][0] = i
        }
        for j in 0...s2Array.count {
            matrix[0][j] = j
        }

        for i in 1...s1Array.count {
            for j in 1...s2Array.count {
                if s1Array[i - 1] == s2Array[j - 1] {
                    matrix[i][j] = matrix[i - 1][j - 1]
                } else {
                    matrix[i][j] = min(
                        matrix[i - 1][j] + 1,      // deletion
                        matrix[i][j - 1] + 1,      // insertion
                        matrix[i - 1][j - 1] + 1   // substitution
                    )
                }
            }
        }

        return matrix[s1Array.count][s2Array.count]
    }
}

// MARK: - String Extension for URL Encoding

private extension String {
    var urlEncoded: String {
        self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}

enum OpenLibraryError: Error, LocalizedError {
    case invalidURL
    case networkError
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid ISBN format. Please check and try again."
        case .networkError:
            return "Unable to connect to the book database. Please check your internet connection and try again."
        case .noData:
            return "Book not found in the database. Try manual entry or check the ISBN."
        }
    }
}