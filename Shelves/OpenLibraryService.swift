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
        
        var subjects: [String] = []
        if let subjectsArray = dict["subjects"] as? [[String: Any]] {
            subjects = subjectsArray.compactMap { $0["name"] as? String }
        }
        let genre = subjects.first
        
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