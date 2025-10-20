import Foundation
import CoreData
import SwiftUI

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    case pdf = "PDF"
    
    var description: String {
        switch self {
        case .csv: return "Spreadsheet format"
        case .json: return "Data interchange format"
        case .pdf: return "Printable document"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .pdf: return "pdf"
        }
    }
}

class DataExportService {
    static let shared = DataExportService()
    
    private init() {}
    
    func exportLibrary(books: [Book], format: ExportFormat) -> URL? {
        switch format {
        case .csv:
            return exportToCSV(books: books)
        case .json:
            return exportToJSON(books: books)
        case .pdf:
            return exportToPDF(books: books)
        }
    }
    
    private func exportToCSV(books: [Book]) -> URL? {
        let header = "Title,Author,ISBN,Library,Genre,Published Date,Page Count,Rating,Is Read,Date Added,Personal Notes\n"
        
        let csvContent = books.reduce(header) { result, book in
            let title = book.title?.replacingOccurrences(of: ",", with: ";") ?? ""
            let author = book.author?.replacingOccurrences(of: ",", with: ";") ?? ""
            let isbn = book.isbn ?? ""
            let library = book.libraryName?.replacingOccurrences(of: ",", with: ";") ?? ""
            let genre = book.genre?.replacingOccurrences(of: ",", with: ";") ?? ""
            let publishedDate = book.publishedDate ?? ""
            let pageCount = book.pageCount > 0 ? String(book.pageCount) : ""
            let rating = book.rating > 0 ? String(book.rating) : ""
            let isRead = book.isRead ? "Yes" : "No"
            let dateAdded = book.dateAdded?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let notes = book.personalNotes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            return result + "\(title),\(author),\(isbn),\(library),\(genre),\(publishedDate),\(pageCount),\(rating),\(isRead),\(dateAdded),\(notes)\n"
        }
        
        return saveToFile(content: csvContent, fileName: "library_export.csv")
    }
    
    private func exportToJSON(books: [Book]) -> URL? {
        let bookData = books.map { book in
            return [
                "title": book.title ?? "",
                "author": book.author ?? "",
                "isbn": book.isbn ?? "",
                "library": book.libraryName ?? "",
                "genre": book.genre ?? "",
                "publishedDate": book.publishedDate ?? "",
                "pageCount": book.pageCount,
                "rating": book.rating,
                "isRead": book.isRead,
                "dateAdded": book.dateAdded?.timeIntervalSince1970 ?? 0,
                "personalNotes": book.personalNotes ?? "",
                "summary": book.summary ?? ""
            ] as [String: Any]
        }
        
        let exportData = [
            "exportDate": Date().timeIntervalSince1970,
            "version": "1.0",
            "totalBooks": books.count,
            "books": bookData
        ] as [String: Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return saveToFile(content: jsonString, fileName: "library_export.json")
            }
        } catch {
            return nil
        }

        return nil
    }
    
    private func exportToPDF(books: [Book]) -> URL? {
        // For now, create a simple text-based PDF export
        var pdfContent = "LIBRARY EXPORT\n"
        pdfContent += "Generated on \(Date().formatted(date: .complete, time: .shortened))\n"
        pdfContent += "Total Books: \(books.count)\n\n"
        
        for book in books.sorted(by: { ($0.title ?? "") < ($1.title ?? "") }) {
            pdfContent += "TITLE: \(book.title ?? "Unknown")\n"
            pdfContent += "AUTHOR: \(book.author ?? "Unknown")\n"
            if let isbn = book.isbn, !isbn.isEmpty {
                pdfContent += "ISBN: \(isbn)\n"
            }
            pdfContent += "LIBRARY: \(book.libraryName ?? "Home Library")\n"
            if let genre = book.genre, !genre.isEmpty {
                pdfContent += "GENRE: \(genre)\n"
            }
            if book.pageCount > 0 {
                pdfContent += "PAGES: \(book.pageCount)\n"
            }
            pdfContent += "STATUS: \(book.isRead ? "Read" : "Unread")\n"
            if book.isRead && book.rating > 0 {
                pdfContent += "RATING: \(String(format: "%.1f", book.rating))/5\n"
            }
            if let notes = book.personalNotes, !notes.isEmpty {
                pdfContent += "NOTES: \(notes)\n"
            }
            pdfContent += "\n" + String(repeating: "-", count: 50) + "\n\n"
        }
        
        return saveToFile(content: pdfContent, fileName: "library_export.pdf")
    }
    
    private func saveToFile(content: String, fileName: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
    
    func backupToiCloud() {
        // Export to JSON and save to iCloud Drive (if available)
        let request: NSFetchRequest<Book> = Book.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)]

        guard let context = PersistenceController.shared.container.viewContext as NSManagedObjectContext? else {
            return
        }

        do {
            let books = try context.fetch(request)
            guard let fileURL = exportLibrary(books: books, format: .json) else {
                return
            }

            // Move to iCloud Drive if available
            if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
                .appendingPathComponent("Documents")
                .appendingPathComponent("Shelves-Backup-\(Date().formatted(date: .abbreviated, time: .omitted)).json") {

                // Create directory if needed
                try? FileManager.default.createDirectory(at: iCloudURL.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true)

                // Copy file to iCloud
                try? FileManager.default.copyItem(at: fileURL, to: iCloudURL)
                print("✅ Backup saved to iCloud Drive: \(iCloudURL.lastPathComponent)")
            } else {
                print("⚠️ iCloud Drive not available, backup saved locally only")
            }
        } catch {
            print("❌ Backup failed: \(error.localizedDescription)")
        }
    }
}

class DuplicateDetectionService {
    static let shared = DuplicateDetectionService()
    
    private init() {}
    
    func findDuplicates(in books: [Book]) -> [[Book]] {
        var duplicateGroups: [[Book]] = []
        var processedBooks: Set<Book> = []
        
        for book in books {
            if processedBooks.contains(book) { continue }
            
            var duplicates: [Book] = [book]
            processedBooks.insert(book)
            
            for otherBook in books {
                if book == otherBook || processedBooks.contains(otherBook) { continue }
                
                if isDuplicate(book1: book, book2: otherBook) {
                    duplicates.append(otherBook)
                    processedBooks.insert(otherBook)
                }
            }
            
            if duplicates.count > 1 {
                duplicateGroups.append(duplicates)
            }
        }
        
        return duplicateGroups
    }
    
    private func isDuplicate(book1: Book, book2: Book) -> Bool {
        // Check ISBN first (most reliable)
        if let isbn1 = book1.isbn, let isbn2 = book2.isbn,
           !isbn1.isEmpty && !isbn2.isEmpty && isbn1 == isbn2 {
            return true
        }
        
        // Check title and author similarity
        let title1 = book1.title?.lowercased() ?? ""
        let title2 = book2.title?.lowercased() ?? ""
        let author1 = book1.author?.lowercased() ?? ""
        let author2 = book2.author?.lowercased() ?? ""
        
        let titleSimilarity = calculateSimilarity(title1, title2)
        let authorSimilarity = calculateSimilarity(author1, author2)
        
        // Consider duplicates if both title and author are 80% similar
        return titleSimilarity > 0.8 && authorSimilarity > 0.8
    }
    
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        if str1.isEmpty && str2.isEmpty { return 1.0 }
        if str1.isEmpty || str2.isEmpty { return 0.0 }
        
        let longer = str1.count > str2.count ? str1 : str2
        let shorter = str1.count > str2.count ? str2 : str1

        if longer.isEmpty { return 1.0 }
        
        let editDistance = levenshteinDistance(longer, shorter)
        return Double(longer.count - editDistance) / Double(longer.count)
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let arr1 = Array(str1)
        let arr2 = Array(str2)
        let m = arr1.count
        let n = arr2.count
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }
        
        for i in 1...m {
            for j in 1...n {
                if arr1[i - 1] == arr2[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    dp[i][j] = 1 + min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1])
                }
            }
        }
        
        return dp[m][n]
    }
}