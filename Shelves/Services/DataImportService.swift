import Foundation
import CoreData
import SwiftUI
import UniformTypeIdentifiers

enum ImportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    case txt = "Text"
    
    var description: String {
        switch self {
        case .csv: return "Spreadsheet format (Excel, Numbers)"
        case .json: return "Data interchange format"
        case .txt: return "Plain text, one book per line"
        }
    }
    
    var supportedTypes: [UTType] {
        switch self {
        case .csv: return [.commaSeparatedText, .plainText]
        case .json: return [.json, .plainText]
        case .txt: return [.plainText, .text]
        }
    }
}

struct ImportedBook {
    let title: String
    let author: String?
    let isbn: String?
    let library: String?
    let genre: String?
    let publishedDate: String?
    let pageCount: Int?
    let rating: Double?
    let isRead: Bool
    let personalNotes: String?
    let summary: String?
    
    // Status fields
    let isOwned: Bool
    let isWantToBuy: Bool
    let currentlyReading: Bool
}

struct ImportResult {
    let successCount: Int
    let failedCount: Int
    let duplicateCount: Int
    let errors: [String]
    let importedBooks: [ImportedBook]
}

class DataImportService {
    static let shared = DataImportService()
    
    private init() {}
    
    func importBooks(from url: URL, format: ImportFormat, context: NSManagedObjectContext) async -> ImportResult {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            
            switch format {
            case .csv:
                return await importFromCSV(content: content, context: context)
            case .json:
                return await importFromJSON(content: content, context: context)
            case .txt:
                return await importFromText(content: content, context: context)
            }
        } catch {
            return ImportResult(
                successCount: 0,
                failedCount: 0,
                duplicateCount: 0,
                errors: ["Failed to read file: \(error.localizedDescription)"],
                importedBooks: []
            )
        }
    }
    
    private func importFromCSV(content: String, context: NSManagedObjectContext) async -> ImportResult {
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            return ImportResult(
                successCount: 0,
                failedCount: 0,
                duplicateCount: 0,
                errors: ["CSV file is empty or has no data rows"],
                importedBooks: []
            )
        }
        
        let headerLine = lines[0]
        let headers = parseCSVLine(headerLine).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        
        var importedBooks: [ImportedBook] = []
        var errors: [String] = []
        var successCount = 0
        var failedCount = 0
        var duplicateCount = 0
        
        for (index, line) in lines.dropFirst().enumerated() {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            
            let values = parseCSVLine(line)
            
            do {
                if let book = try parseBookFromCSV(headers: headers, values: values) {
                    // Check for duplicates
                    if await isDuplicate(book: book, context: context) {
                        duplicateCount += 1
                    } else {
                        importedBooks.append(book)
                        successCount += 1
                    }
                } else {
                    failedCount += 1
                    errors.append("Row \(index + 2): Could not parse book data")
                }
            } catch {
                failedCount += 1
                errors.append("Row \(index + 2): \(error.localizedDescription)")
            }
        }

        // Save books to Core Data
        do {
            try await saveBooksToContext(importedBooks, context: context)
        } catch {
            errors.append("Failed to save books to database: \(error.localizedDescription)")
            return ImportResult(
                successCount: 0,
                failedCount: importedBooks.count,
                duplicateCount: duplicateCount,
                errors: errors,
                importedBooks: []
            )
        }

        return ImportResult(
            successCount: successCount,
            failedCount: failedCount,
            duplicateCount: duplicateCount,
            errors: errors,
            importedBooks: importedBooks
        )
    }
    
    private func importFromJSON(content: String, context: NSManagedObjectContext) async -> ImportResult {
        guard let data = content.data(using: .utf8) else {
            return ImportResult(
                successCount: 0,
                failedCount: 0,
                duplicateCount: 0,
                errors: ["Invalid JSON content"],
                importedBooks: []
            )
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            var booksData: [[String: Any]] = []
            
            // Handle different JSON structures
            if let json = jsonObject as? [String: Any],
               let books = json["books"] as? [[String: Any]] {
                // Shelves export format
                booksData = books
            } else if let books = jsonObject as? [[String: Any]] {
                // Array of books directly
                booksData = books
            } else {
                return ImportResult(
                    successCount: 0,
                    failedCount: 0,
                    duplicateCount: 0,
                    errors: ["Unsupported JSON format"],
                    importedBooks: []
                )
            }
            
            var importedBooks: [ImportedBook] = []
            var errors: [String] = []
            var successCount = 0
            var failedCount = 0
            var duplicateCount = 0
            
            for (index, bookData) in booksData.enumerated() {
                do {
                    let book = try parseBookFromJSON(bookData)
                    
                    if await isDuplicate(book: book, context: context) {
                        duplicateCount += 1
                    } else {
                        importedBooks.append(book)
                        successCount += 1
                    }
                } catch {
                    failedCount += 1
                    errors.append("Book \(index + 1): \(error.localizedDescription)")
                }
            }

            // Save books to Core Data
            do {
                try await saveBooksToContext(importedBooks, context: context)
            } catch {
                var finalErrors = errors
                finalErrors.append("Failed to save books to database: \(error.localizedDescription)")
                return ImportResult(
                    successCount: 0,
                    failedCount: importedBooks.count,
                    duplicateCount: duplicateCount,
                    errors: finalErrors,
                    importedBooks: []
                )
            }

            return ImportResult(
                successCount: successCount,
                failedCount: failedCount,
                duplicateCount: duplicateCount,
                errors: errors,
                importedBooks: importedBooks
            )

        } catch {
            return ImportResult(
                successCount: 0,
                failedCount: 0,
                duplicateCount: 0,
                errors: ["JSON parsing error: \(error.localizedDescription)"],
                importedBooks: []
            )
        }
    }
    
    private func importFromText(content: String, context: NSManagedObjectContext) async -> ImportResult {
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var importedBooks: [ImportedBook] = []
        let errors: [String] = []
        var successCount = 0
        let failedCount = 0
        var duplicateCount = 0
        
        for (_, line) in lines.enumerated() {
            let book = parseBookFromText(line)
            
            if await isDuplicate(book: book, context: context) {
                duplicateCount += 1
            } else {
                importedBooks.append(book)
                successCount += 1
            }
        }

        // Save books to Core Data
        do {
            try await saveBooksToContext(importedBooks, context: context)
        } catch {
            var finalErrors = errors
            finalErrors.append("Failed to save books to database: \(error.localizedDescription)")
            return ImportResult(
                successCount: 0,
                failedCount: importedBooks.count,
                duplicateCount: duplicateCount,
                errors: finalErrors,
                importedBooks: []
            )
        }

        return ImportResult(
            successCount: successCount,
            failedCount: failedCount,
            duplicateCount: duplicateCount,
            errors: errors,
            importedBooks: importedBooks
        )
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
            
            i = line.index(after: i)
        }
        
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }
    
    private func parseBookFromCSV(headers: [String], values: [String]) throws -> ImportedBook? {
        guard !values.isEmpty else { return nil }
        
        var title = ""
        var author: String?
        var isbn: String?
        var library: String?
        var genre: String?
        var publishedDate: String?
        var pageCount: Int?
        var rating: Double?
        var isRead = false
        var personalNotes: String?
        var summary: String?
        var isOwned = true
        var isWantToBuy = false
        var currentlyReading = false
        
        for (index, header) in headers.enumerated() {
            guard index < values.count else { continue }
            let value = values[index].trimmingCharacters(in: .whitespaces)
            
            switch header {
            case "title", "book title", "name":
                title = value
            case "author", "author name", "writers":
                author = value.isEmpty ? nil : value
            case "isbn", "isbn-10", "isbn-13", "isbn13", "isbn10":
                isbn = value.isEmpty ? nil : value
            case "library", "library name", "location":
                library = value.isEmpty ? nil : value
            case "genre", "category", "subject":
                genre = value.isEmpty ? nil : value
            case "published date", "publication date", "date published", "published", "year":
                publishedDate = value.isEmpty ? nil : value
            case "page count", "pages", "page number", "number of pages":
                pageCount = Int(value)
            case "rating", "score", "stars":
                rating = Double(value)
            case "is read", "read", "finished", "completed":
                isRead = ["yes", "true", "1", "completed", "finished"].contains(value.lowercased())
            case "personal notes", "notes", "comments", "review":
                personalNotes = value.isEmpty ? nil : value
            case "summary", "description", "synopsis":
                summary = value.isEmpty ? nil : value
            case "owned", "is owned", "ownership":
                isOwned = ["yes", "true", "1", "owned"].contains(value.lowercased())
            case "want to buy", "wishlist", "want":
                isWantToBuy = ["yes", "true", "1"].contains(value.lowercased())
            case "currently reading", "reading", "current":
                currentlyReading = ["yes", "true", "1"].contains(value.lowercased())
            default:
                break
            }
        }
        
        guard !title.isEmpty else { return nil }
        
        return ImportedBook(
            title: title,
            author: author,
            isbn: isbn,
            library: library,
            genre: genre,
            publishedDate: publishedDate,
            pageCount: pageCount,
            rating: rating,
            isRead: isRead,
            personalNotes: personalNotes,
            summary: summary,
            isOwned: isOwned,
            isWantToBuy: isWantToBuy,
            currentlyReading: currentlyReading
        )
    }
    
    private func parseBookFromJSON(_ data: [String: Any]) throws -> ImportedBook {
        guard let title = data["title"] as? String, !title.isEmpty else {
            throw ImportError.missingTitle
        }
        
        return ImportedBook(
            title: title,
            author: data["author"] as? String,
            isbn: data["isbn"] as? String,
            library: data["library"] as? String,
            genre: data["genre"] as? String,
            publishedDate: data["publishedDate"] as? String,
            pageCount: data["pageCount"] as? Int,
            rating: data["rating"] as? Double,
            isRead: data["isRead"] as? Bool ?? false,
            personalNotes: data["personalNotes"] as? String,
            summary: data["summary"] as? String,
            isOwned: data["isOwned"] as? Bool ?? true,
            isWantToBuy: data["isWantToBuy"] as? Bool ?? false,
            currentlyReading: data["currentlyReading"] as? Bool ?? false
        )
    }
    
    private func parseBookFromText(_ line: String) -> ImportedBook {
        // Try to parse "Title by Author" format
        let components = line.components(separatedBy: " by ")
        let title = components[0].trimmingCharacters(in: .whitespaces)
        let author = components.count > 1 ? components[1].trimmingCharacters(in: .whitespaces) : nil
        
        return ImportedBook(
            title: title,
            author: author,
            isbn: nil,
            library: nil,
            genre: nil,
            publishedDate: nil,
            pageCount: nil,
            rating: nil,
            isRead: false,
            personalNotes: nil,
            summary: nil,
            isOwned: true,
            isWantToBuy: false,
            currentlyReading: false
        )
    }
    
    private func isDuplicate(book: ImportedBook, context: NSManagedObjectContext) async -> Bool {
        return await context.perform {
            let request: NSFetchRequest<Book> = Book.fetchRequest()
            
            // Check by ISBN first
            if let isbn = book.isbn, !isbn.isEmpty {
                request.predicate = NSPredicate(format: "isbn == %@", isbn)
                if let count = try? context.count(for: request), count > 0 {
                    return true
                }
            }
            
            // Check by title and author
            if let author = book.author, !author.isEmpty {
                request.predicate = NSPredicate(format: "title == %@ AND author == %@", book.title, author)
            } else {
                request.predicate = NSPredicate(format: "title == %@", book.title)
            }
            
            if let count = try? context.count(for: request), count > 0 {
                return true
            }
            
            return false
        }
    }
    
    private func saveBooksToContext(_ books: [ImportedBook], context: NSManagedObjectContext) async throws {
        try await context.perform {
            for importedBook in books {
                let book = Book(context: context)
                book.id = UUID()
                book.title = importedBook.title
                book.author = importedBook.author
                book.isbn = importedBook.isbn
                book.libraryName = importedBook.library ?? "Imported Library"
                book.genre = importedBook.genre
                book.publishedDate = importedBook.publishedDate
                book.pageCount = Int32(importedBook.pageCount ?? 0)
                book.rating = Float(importedBook.rating ?? 0.0)
                book.isRead = importedBook.isRead
                book.personalNotes = importedBook.personalNotes
                book.summary = importedBook.summary
                book.dateAdded = Date()
                book.isOwned = importedBook.isOwned
                book.isWantToBuy = importedBook.isWantToBuy
                book.currentlyReading = importedBook.currentlyReading

                // Set image URL placeholder
                book.coverImageURL = nil
            }

            try context.save()
        }
    }
}

enum ImportError: LocalizedError {
    case missingTitle
    case invalidFormat
    case fileNotReadable
    
    var errorDescription: String? {
        switch self {
        case .missingTitle:
            return "Book title is required"
        case .invalidFormat:
            return "Unsupported file format"
        case .fileNotReadable:
            return "Could not read the selected file"
        }
    }
}