import Foundation
import CoreData

struct RecommendationService {
    static func getWeeklyRecommendation(from books: [Book]) -> Book? {
        let unreadBooks = books.filter { !$0.isRead && !$0.currentlyReading }
        
        if unreadBooks.isEmpty {
            let finishedBooks = books.filter { $0.isRead }
            let oldBooks = finishedBooks.filter { book in
                guard let dateAdded = book.dateAdded else { return false }
                let daysSinceAdded = Calendar.current.dateComponents([.day], from: dateAdded, to: Date()).day ?? 0
                return daysSinceAdded > 30
            }
            return oldBooks.randomElement()
        }
        
        let recentlyAddedBooks = unreadBooks.filter { book in
            guard let dateAdded = book.dateAdded else { return false }
            let daysSinceAdded = Calendar.current.dateComponents([.day], from: dateAdded, to: Date()).day ?? 0
            return daysSinceAdded <= 7
        }
        
        if !recentlyAddedBooks.isEmpty {
            return recentlyAddedBooks.randomElement()
        }
        
        return unreadBooks.randomElement()
    }
    
    static func getRecommendationText(for book: Book?) -> (title: String, subtitle: String) {
        guard let book = book else {
            return ("Start Your Collection", "Add your first book to get personalized recommendations.")
        }
        
        if book.isRead {
            return ("Revisit a Classic", "How about re-reading \"\(book.title ?? "this book")\"?")
        } else {
            return ("This Week's Pick", "\"\(book.title ?? "Unknown Title")\" is waiting for you.")
        }
    }
}