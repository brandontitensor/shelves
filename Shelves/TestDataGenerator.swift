import Foundation
import CoreData

class TestDataGenerator {
    static let shared = TestDataGenerator()
    
    private init() {}
    
    // Sample book data for testing
    private let testBooks: [(title: String, author: String, genre: String, isbn: String?, publishedDate: String?, pageCount: Int32?, rating: Float, isRead: Bool, library: String)] = [
        // Fiction - Classic Literature
        ("To Kill a Mockingbird", "Harper Lee", "Classic Literature", "9780061120084", "1960", 376, 4.8, true, "Home Library"),
        ("1984", "George Orwell", "Classic Literature", "9780451524935", "1949", 328, 4.7, true, "Home Library"),
        ("Pride and Prejudice", "Jane Austen", "Classic Literature", "9780141439518", "1813", 432, 4.5, true, "Home Library"),
        ("The Great Gatsby", "F. Scott Fitzgerald", "Classic Literature", "9780743273565", "1925", 180, 4.2, true, "Home Library"),
        ("Lord of the Flies", "William Golding", "Classic Literature", "9780571056866", "1954", 224, 4.1, true, "Home Library"),
        ("The Catcher in the Rye", "J.D. Salinger", "Classic Literature", "9780316769174", "1951", 277, 4.0, true, "Home Library"),
        ("Of Mice and Men", "John Steinbeck", "Classic Literature", "9780140177398", "1937", 112, 4.3, true, "Home Library"),
        ("Jane Eyre", "Charlotte Brontë", "Classic Literature", "9780141441146", "1847", 507, 4.4, true, "Home Library"),
        ("Wuthering Heights", "Emily Brontë", "Classic Literature", "9780141439556", "1847", 464, 4.1, false, "Home Library"),
        ("The Picture of Dorian Gray", "Oscar Wilde", "Classic Literature", "9780141439570", "1890", 304, 4.3, false, "Home Library"),
        
        // Science Fiction
        ("Dune", "Frank Herbert", "Science Fiction", "9780441172719", "1965", 688, 4.8, true, "Study Room"),
        ("Foundation", "Isaac Asimov", "Science Fiction", "9780553293357", "1951", 244, 4.6, true, "Study Room"),
        ("Ender's Game", "Orson Scott Card", "Science Fiction", "9780812550702", "1985", 324, 4.7, true, "Study Room"),
        ("The Hitchhiker's Guide to the Galaxy", "Douglas Adams", "Science Fiction", "9780345391803", "1979", 224, 4.5, true, "Study Room"),
        ("Neuromancer", "William Gibson", "Science Fiction", "9780441569595", "1984", 271, 4.2, false, "Study Room"),
        ("The Martian", "Andy Weir", "Science Fiction", "9780553418026", "2011", 369, 4.6, true, "Study Room"),
        ("Ready Player One", "Ernest Cline", "Science Fiction", "9780307887443", "2011", 374, 4.3, true, "Study Room"),
        ("The Left Hand of Darkness", "Ursula K. Le Guin", "Science Fiction", "9780441478125", "1969", 304, 4.4, false, "Study Room"),
        ("Fahrenheit 451", "Ray Bradbury", "Science Fiction", "9781451673319", "1953", 194, 4.5, true, "Study Room"),
        ("I, Robot", "Isaac Asimov", "Science Fiction", "9780553294385", "1950", 253, 4.3, false, "Study Room"),
        
        // Fantasy
        ("The Lord of the Rings: The Fellowship of the Ring", "J.R.R. Tolkien", "Fantasy", "9780547928210", "1954", 423, 4.9, true, "Study Room"),
        ("The Hobbit", "J.R.R. Tolkien", "Fantasy", "9780547928227", "1937", 366, 4.8, true, "Study Room"),
        ("A Game of Thrones", "George R.R. Martin", "Fantasy", "9780553103540", "1996", 694, 4.7, true, "Study Room"),
        ("Harry Potter and the Philosopher's Stone", "J.K. Rowling", "Fantasy", "9780747532699", "1997", 223, 4.8, true, "Kids Room"),
        ("The Name of the Wind", "Patrick Rothfuss", "Fantasy", "9780756404741", "2007", 662, 4.6, true, "Study Room"),
        ("The Way of Kings", "Brandon Sanderson", "Fantasy", "9780765326355", "2010", 1007, 4.7, false, "Study Room"),
        ("The Lies of Locke Lamora", "Scott Lynch", "Fantasy", "9780553804676", "2006", 499, 4.5, false, "Study Room"),
        ("The Blade Itself", "Joe Abercrombie", "Fantasy", "9780316077866", "2006", 531, 4.2, false, "Study Room"),
        ("The Eye of the World", "Robert Jordan", "Fantasy", "9780812511819", "1990", 782, 4.4, false, "Study Room"),
        ("Mistborn: The Final Empire", "Brandon Sanderson", "Fantasy", "9780765311788", "2006", 541, 4.6, true, "Study Room"),
        
        // Mystery/Thriller
        ("Gone Girl", "Gillian Flynn", "Mystery", "9780307588364", "2012", 419, 4.2, true, "Bedroom"),
        ("The Girl with the Dragon Tattoo", "Stieg Larsson", "Mystery", "9780307454546", "2005", 590, 4.3, true, "Bedroom"),
        ("In the Woods", "Tana French", "Mystery", "9780143113492", "2007", 429, 4.1, false, "Bedroom"),
        ("The Big Sleep", "Raymond Chandler", "Mystery", "9780394758282", "1939", 231, 4.4, true, "Bedroom"),
        ("And Then There Were None", "Agatha Christie", "Mystery", "9780062073488", "1939", 264, 4.5, true, "Bedroom"),
        ("The Maltese Falcon", "Dashiell Hammett", "Mystery", "9780679722649", "1930", 217, 4.2, false, "Bedroom"),
        ("The Silence of the Lambs", "Thomas Harris", "Thriller", "9780312924584", "1988", 352, 4.4, true, "Bedroom"),
        ("The Da Vinci Code", "Dan Brown", "Thriller", "9780307474278", "2003", 454, 3.8, true, "Bedroom"),
        ("The Girl on the Train", "Paula Hawkins", "Thriller", "9781594633669", "2015", 336, 3.9, false, "Bedroom"),
        ("Shutter Island", "Dennis Lehane", "Thriller", "9780380731862", "2003", 369, 4.3, true, "Bedroom"),
        
        // Romance
        ("Pride and Prejudice", "Jane Austen", "Romance", "9780141439518", "1813", 432, 4.7, true, "Bedroom"),
        ("Jane Eyre", "Charlotte Brontë", "Romance", "9780141441146", "1847", 507, 4.6, true, "Bedroom"),
        ("Outlander", "Diana Gabaldon", "Romance", "9780440212560", "1991", 627, 4.5, false, "Bedroom"),
        ("Me Before You", "Jojo Moyes", "Romance", "9780670026609", "2012", 369, 4.2, true, "Bedroom"),
        ("The Notebook", "Nicholas Sparks", "Romance", "9780446676090", "1996", 214, 4.1, true, "Bedroom"),
        ("It Ends with Us", "Colleen Hoover", "Romance", "9781501110368", "2016", 367, 4.3, false, "Bedroom"),
        ("The Hating Game", "Sally Thorne", "Romance", "9780062439598", "2016", 384, 4.2, false, "Bedroom"),
        ("Beach Read", "Emily Henry", "Romance", "9781984806734", "2020", 352, 4.4, false, "Bedroom"),
        ("Red, White & Royal Blue", "Casey McQuiston", "Romance", "9781250316776", "2019", 421, 4.5, false, "Bedroom"),
        ("The Seven Husbands of Evelyn Hugo", "Taylor Jenkins Reid", "Romance", "9781501161933", "2017", 400, 4.6, true, "Bedroom"),
        
        // Non-Fiction - History
        ("Sapiens", "Yuval Noah Harari", "History", "9780062316097", "2014", 443, 4.6, true, "Office"),
        ("The Guns of August", "Barbara Tuchman", "History", "9780345476098", "1962", 511, 4.5, false, "Office"),
        ("A People's History of the United States", "Howard Zinn", "History", "9780062397348", "1980", 729, 4.4, false, "Office"),
        ("The Diary of a Young Girl", "Anne Frank", "History", "9780553296983", "1947", 283, 4.7, true, "Office"),
        ("Band of Brothers", "Stephen Ambrose", "History", "9780743464451", "1992", 333, 4.6, true, "Office"),
        ("The Devil in the White City", "Erik Larson", "History", "9780375725609", "2003", 447, 4.3, false, "Office"),
        ("John Adams", "David McCullough", "Biography", "9780743223133", "2001", 751, 4.5, false, "Office"),
        ("Team of Rivals", "Doris Kearns Goodwin", "Biography", "9780684824901", "2005", 916, 4.4, false, "Office"),
        ("The Immortal Life of Henrietta Lacks", "Rebecca Skloot", "Science", "9781400052189", "2010", 381, 4.5, true, "Office"),
        ("Educated", "Tara Westover", "Memoir", "9780399590504", "2018", 334, 4.7, true, "Office"),
        
        // Self-Help/Business
        ("Think and Grow Rich", "Napoleon Hill", "Self-Help", "9781585424337", "1937", 238, 4.2, false, "Office"),
        ("How to Win Friends and Influence People", "Dale Carnegie", "Self-Help", "9780671027032", "1936", 291, 4.3, true, "Office"),
        ("The 7 Habits of Highly Effective People", "Stephen Covey", "Self-Help", "9781451639612", "1989", 372, 4.4, false, "Office"),
        ("Atomic Habits", "James Clear", "Self-Help", "9780735211292", "2018", 319, 4.6, true, "Office"),
        ("The Lean Startup", "Eric Ries", "Business", "9780307887894", "2011", 336, 4.2, false, "Office"),
        ("Good to Great", "Jim Collins", "Business", "9780066620992", "2001", 300, 4.3, false, "Office"),
        ("The Millionaire Next Door", "Thomas Stanley", "Finance", "9781563523302", "1996", 258, 4.1, false, "Office"),
        ("Rich Dad Poor Dad", "Robert Kiyosaki", "Finance", "9781612680194", "1997", 336, 4.0, true, "Office"),
        ("The Power of Now", "Eckhart Tolle", "Spirituality", "9781577314806", "1997", 236, 4.2, false, "Office"),
        ("Man's Search for Meaning", "Viktor Frankl", "Psychology", "9780807014295", "1946", 165, 4.7, true, "Office"),
        
        // Children's Books
        ("Where the Crawdads Sing", "Delia Owens", "Fiction", "9780735219090", "2018", 370, 4.4, true, "Kids Room"),
        ("The Lion, the Witch and the Wardrobe", "C.S. Lewis", "Children's Fantasy", "9780064404990", "1950", 206, 4.6, true, "Kids Room"),
        ("Charlotte's Web", "E.B. White", "Children's Fiction", "9780064400558", "1952", 184, 4.7, true, "Kids Room"),
        ("Matilda", "Roald Dahl", "Children's Fiction", "9780142410370", "1988", 240, 4.5, true, "Kids Room"),
        ("The Giving Tree", "Shel Silverstein", "Children's Picture Book", "9780060256654", "1964", 64, 4.3, true, "Kids Room"),
        ("Where the Wild Things Are", "Maurice Sendak", "Children's Picture Book", "9780060254926", "1963", 48, 4.4, true, "Kids Room"),
        ("The Cat in the Hat", "Dr. Seuss", "Children's Picture Book", "9780394800011", "1957", 61, 4.5, true, "Kids Room"),
        ("Green Eggs and Ham", "Dr. Seuss", "Children's Picture Book", "9780394800165", "1960", 62, 4.4, true, "Kids Room"),
        ("Goodnight Moon", "Margaret Wise Brown", "Children's Picture Book", "9780064430173", "1947", 32, 4.2, true, "Kids Room"),
        ("The Very Hungry Caterpillar", "Eric Carle", "Children's Picture Book", "9780399226908", "1969", 26, 4.3, true, "Kids Room"),
        
        // Horror
        ("The Shining", "Stephen King", "Horror", "9780307743657", "1977", 447, 4.3, false, "Basement"),
        ("Dracula", "Bram Stoker", "Horror", "9780486411095", "1897", 418, 4.2, false, "Basement"),
        ("Frankenstein", "Mary Shelley", "Horror", "9780486282114", "1818", 166, 4.1, true, "Basement"),
        ("The Exorcist", "William Peter Blatty", "Horror", "9780060523282", "1971", 340, 4.0, false, "Basement"),
        ("Pet Sematary", "Stephen King", "Horror", "9780307743671", "1983", 374, 4.1, false, "Basement"),
        ("The Haunting of Hill House", "Shirley Jackson", "Horror", "9780143039983", "1959", 246, 4.4, false, "Basement"),
        ("Something Wicked This Way Comes", "Ray Bradbury", "Horror", "9780380729401", "1962", 293, 4.2, false, "Basement"),
        ("The Strange Case of Dr. Jekyll and Mr. Hyde", "Robert Louis Stevenson", "Horror", "9780486266886", "1886", 64, 4.0, true, "Basement"),
        ("Interview with the Vampire", "Anne Rice", "Horror", "9780345337665", "1976", 371, 4.1, false, "Basement"),
        ("World War Z", "Max Brooks", "Horror", "9780307346612", "2006", 342, 4.2, false, "Basement"),
        
        // Poetry & Drama
        ("The Complete Works of William Shakespeare", "William Shakespeare", "Drama", "9780517053614", "1623", 1263, 4.8, false, "Study Room"),
        ("Leaves of Grass", "Walt Whitman", "Poetry", "9780486456768", "1855", 147, 4.3, false, "Study Room"),
        ("The Waste Land and Other Poems", "T.S. Eliot", "Poetry", "9780486400617", "1922", 64, 4.2, false, "Study Room"),
        ("Death of a Salesman", "Arthur Miller", "Drama", "9780140481341", "1949", 139, 4.4, true, "Study Room"),
        ("A Streetcar Named Desire", "Tennessee Williams", "Drama", "9780811216029", "1947", 142, 4.3, false, "Study Room"),
        
        // Additional diverse titles to reach 100
        ("The Alchemist", "Paulo Coelho", "Philosophy", "9780061122415", "1988", 163, 4.3, true, "Bedroom"),
        ("Life of Pi", "Yann Martel", "Adventure", "9780156027328", "2001", 319, 4.2, true, "Home Library"),
        ("The Kite Runner", "Khaled Hosseini", "Literary Fiction", "9781594631931", "2003", 371, 4.5, true, "Home Library"),
        ("Eat, Pray, Love", "Elizabeth Gilbert", "Memoir", "9780143038412", "2006", 349, 3.9, false, "Bedroom"),
        ("The Time Traveler's Wife", "Audrey Niffenegger", "Romance", "9780156029438", "2003", 546, 4.2, false, "Bedroom"),
        ("Into the Wild", "Jon Krakauer", "Biography", "9780307387172", "1996", 207, 4.1, true, "Office"),
        ("The Book Thief", "Markus Zusak", "Historical Fiction", "9780375842207", "2005", 552, 4.6, true, "Kids Room"),
        ("A Thousand Splendid Suns", "Khaled Hosseini", "Literary Fiction", "9781594489501", "2007", 372, 4.4, false, "Home Library"),
        ("The Help", "Kathryn Stockett", "Historical Fiction", "9780425232200", "2009", 451, 4.3, true, "Home Library"),
        ("Water for Elephants", "Sara Gruen", "Historical Fiction", "9781565125605", "2006", 335, 4.1, false, "Home Library")
    ]
    
    func populateTestLibrary(context: NSManagedObjectContext) {
        // Clear existing books first
        clearAllBooks(context: context)
        
        // Add all test books
        for bookData in testBooks {
            let book = Book(context: context)
            book.id = UUID()
            book.title = bookData.title
            book.author = bookData.author
            book.genre = bookData.genre
            book.isbn = bookData.isbn
            book.publishedDate = bookData.publishedDate
            book.pageCount = bookData.pageCount ?? 0
            book.rating = bookData.rating
            book.isRead = bookData.isRead
            book.libraryName = bookData.library
            book.dateAdded = Date().addingTimeInterval(TimeInterval.random(in: -31536000...0)) // Random date within last year
            book.size = ["Pocket", "Mass Market", "Trade Paperback", "Hardcover", "Large Print"].randomElement() ?? "Trade Paperback"
            
            // Add some random personal notes for read books
            if bookData.isRead && Bool.random() {
                let notes = [
                    "Really enjoyed this one!",
                    "Great character development",
                    "Couldn't put it down",
                    "Beautiful writing style",
                    "Will definitely re-read",
                    "Highly recommend",
                    "Made me think differently",
                    "Perfect beach read",
                    "A classic for a reason",
                    "Life-changing book"
                ]
                book.personalNotes = notes.randomElement()
            }
            
            // Set some books as currently reading
            if !bookData.isRead && Int.random(in: 1...10) <= 2 {
                book.currentlyReading = true
            }
        }
        
        // Save the context
        do {
            try context.save()
            print("Successfully populated test library with \(testBooks.count) books")
        } catch {
            print("Failed to save test books: \(error)")
        }
    }
    
    private func clearAllBooks(context: NSManagedObjectContext) {
        let request: NSFetchRequest<NSFetchRequestResult> = Book.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("Cleared existing books from library")
        } catch {
            print("Failed to clear existing books: \(error)")
        }
    }
    
    func getBookCount(context: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<Book> = Book.fetchRequest()
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
}