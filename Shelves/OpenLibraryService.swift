import Foundation

struct OpenLibraryService {
    static let shared = OpenLibraryService()
    private let baseURL = "https://openlibrary.org"
    
    private init() {}
    
    func fetchBookData(isbn: String) async throws -> BookData? {
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
            return nil
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

enum OpenLibraryError: Error, LocalizedError {
    case invalidURL
    case networkError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error occurred"
        case .noData:
            return "No book data found"
        }
    }
}