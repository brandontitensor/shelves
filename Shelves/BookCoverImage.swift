import SwiftUI

// Reusable book cover image component with consistent sizing and caching
struct BookCoverImage: View {
    let book: Book
    let width: CGFloat?
    let height: CGFloat?
    let cornerRadius: CGFloat
    let contentMode: ContentMode
    
    // Different presentation modes for various contexts
    enum CoverStyle {
        case grid           // For library grid view
        case list           // For search results and lists
        case detail         // For book detail view
        case carousel       // For home page carousel
        case thumbnail      // Small thumbnails
        
        var dimensions: (width: CGFloat?, height: CGFloat?) {
            switch self {
            case .grid:
                return (width: nil, height: 140)
            case .list:
                return (width: 40, height: 56)
            case .detail:
                return (width: 120, height: 180)
            case .carousel:
                return (width: nil, height: nil) // Uses geometry reader
            case .thumbnail:
                return (width: 30, height: 42)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .grid: return ShelvesDesign.CornerRadius.medium
            case .list: return ShelvesDesign.CornerRadius.small
            case .detail: return 12
            case .carousel: return ShelvesDesign.CornerRadius.medium
            case .thumbnail: return ShelvesDesign.CornerRadius.small
            }
        }
        
        var contentMode: ContentMode {
            switch self {
            case .grid, .detail, .carousel:
                return .fit  // Maintain aspect ratio, fit within bounds
            case .list, .thumbnail:
                return .fill // Fill the space, may crop slightly
            }
        }
    }
    
    init(book: Book, style: CoverStyle) {
        self.book = book
        let dimensions = style.dimensions
        self.width = dimensions.width
        self.height = dimensions.height
        self.cornerRadius = style.cornerRadius
        self.contentMode = style.contentMode
    }
    
    // Custom initializer for specific dimensions
    init(book: Book, width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat = ShelvesDesign.CornerRadius.medium, contentMode: ContentMode = .fit) {
        self.book = book
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.contentMode = contentMode
    }
    
    var body: some View {
        AsyncImage(url: book.coverImageURL.flatMap(URL.init)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure(_):
                // Fallback to placeholder on error
                placeholderView
            case .empty:
                // Loading state
                placeholderView
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            @unknown default:
                placeholderView
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .cornerRadius(cornerRadius)
        .bookShadow()
    }
    
    private var placeholderView: some View {
        BookSpinePlaceholder(
            title: book.title ?? "",
            author: book.author ?? "",
            color: bookSpineColor(for: book)
        )
    }
    
    private func bookSpineColor(for book: Book) -> Color {
        let colors = [
            ShelvesDesign.Colors.burgundy,
            ShelvesDesign.Colors.forestGreen,
            ShelvesDesign.Colors.navy,
            ShelvesDesign.Colors.deepMaroon,
            ShelvesDesign.Colors.chestnut
        ]
        
        let hash = book.title?.hashValue ?? 0
        return colors[abs(hash) % colors.count]
    }
}

// Enhanced AsyncImage with better caching behavior
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var imageCache = ImageCache.shared
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        if let url = url, let cachedImage = imageCache.image(for: url) {
            content(cachedImage)
        } else {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    content(image)
                        .onAppear {
                            if let url = url {
                                imageCache.setImage(image, for: url)
                            }
                        }
                case .failure(_), .empty:
                    placeholder()
                @unknown default:
                    placeholder()
                }
            }
        }
    }
}

// Simple image cache for better performance
class ImageCache: ObservableObject {
    static let shared = ImageCache()
    
    private var cache: [URL: Image] = [:]
    private let maxCacheSize = 50 // Limit cache to 50 images
    
    private init() {}
    
    func image(for url: URL) -> Image? {
        return cache[url]
    }
    
    func setImage(_ image: Image, for url: URL) {
        // Simple LRU-like behavior: remove oldest if we exceed cache size
        if cache.count >= maxCacheSize {
            let oldestKey = cache.keys.first
            if let key = oldestKey {
                cache.removeValue(forKey: key)
            }
        }
        cache[url] = image
    }
    
    func clearCache() {
        cache.removeAll()
    }
}

#Preview {
    // Create a sample book for preview
    let context = PersistenceController.preview.container.viewContext
    let sampleBook = Book(context: context)
    sampleBook.title = "Sample Book"
    sampleBook.author = "Sample Author"
    
    return VStack(spacing: 20) {
        BookCoverImage(book: sampleBook, style: .detail)
        BookCoverImage(book: sampleBook, style: .grid)
        BookCoverImage(book: sampleBook, style: .list)
        BookCoverImage(book: sampleBook, style: .thumbnail)
    }
    .padding()
}