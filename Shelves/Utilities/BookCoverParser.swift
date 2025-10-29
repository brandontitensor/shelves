import Foundation
import Vision

/// Candidate book information extracted from cover/spine
struct BookCoverCandidate {
    let title: String
    let author: String?
    let confidence: Float

    init(title: String, author: String? = nil, confidence: Float) {
        self.title = title
        self.author = author
        self.confidence = confidence
    }
}

/// Analyzes Vision text observations to extract book title and author
class BookCoverParser {

    /// Parse text observations from a book cover or spine
    /// - Parameter observations: Vision text recognition results
    /// - Returns: Ranked list of potential title/author combinations
    func parseTextObservations(_ observations: [VNRecognizedTextObservation]) -> [BookCoverCandidate] {
        guard !observations.isEmpty else {
            print("📖 [Parser] No text observations to parse")
            return []
        }

        print("📖 [Parser] Parsing \(observations.count) text observations")

        // Extract all text with metadata
        var textElements: [(text: String, bounds: CGRect, confidence: Float)] = []

        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            let confidence = topCandidate.confidence
            let bounds = observation.boundingBox

            // Filter out very short text (decorative elements)
            guard text.count > 2 else { continue }

            // Filter out noise (publishers, ISBNs, barcodes, prices)
            if shouldFilterOutText(text) {
                print("📖 [Parser] Filtering out noise: '\(text)'")
                continue
            }

            textElements.append((text: text, bounds: bounds, confidence: confidence))
        }

        guard !textElements.isEmpty else {
            print("📖 [Parser] No valid text elements found")
            return []
        }

        // Sort by vertical position (top to bottom) and size
        textElements.sort { first, second in
            // Y coordinate in Vision is inverted (0 = bottom, 1 = top)
            // So higher Y value = higher on page
            first.bounds.midY > second.bounds.midY
        }

        // Combine text elements that are on the same line (same Y coordinate)
        let combinedElements = combineTextOnSameLines(textElements)

        print("📖 [Parser] Found \(combinedElements.count) text elements (after combining same-line text)")
        for (index, element) in combinedElements.enumerated() {
            print("📖 [Parser]   [\(index)] '\(element.text)' (height: \(String(format: "%.3f", element.bounds.height)), y: \(String(format: "%.3f", element.bounds.midY)))")
        }

        var candidates: [BookCoverCandidate] = []

        // Strategy 1: Find the largest text that's NOT an author name
        if let largestText = findLargestTextExcludingAuthors(combinedElements) {
            let titleText = largestText.text
            let author = findAuthorNear(largestText, in: combinedElements)
            let confidence = calculateConfidence(titleSize: largestText.bounds.height, hasAuthor: author != nil) + 0.1

            print("📖 [Parser] Strategy 1 - Largest non-author text: '\(titleText)' author: '\(author ?? "none")' confidence: \(String(format: "%.2f", confidence))")
            candidates.append(BookCoverCandidate(title: titleText, author: author, confidence: confidence))
        }

        // Strategy 2: Look for "by [Author]" pattern
        if let titleAuthorPair = findByPattern(in: combinedElements) {
            let confidence: Float = 0.90 // Very high confidence when we find "by" pattern
            print("📖 [Parser] Strategy 2 - Found 'by' pattern: '\(titleAuthorPair.title)' by '\(titleAuthorPair.author ?? "unknown")'")
            candidates.append(BookCoverCandidate(title: titleAuthorPair.title, author: titleAuthorPair.author, confidence: confidence))
        }

        // Strategy 3: Combine multiple large text elements in the top half (for split titles)
        if let combinedTitle = findCombinedTitle(combinedElements) {
            let author = findAuthorInElements(combinedElements)
            let confidence: Float = 0.85  // High confidence for combined titles

            print("📖 [Parser] Strategy 3 - Combined title elements: '\(combinedTitle)' author: '\(author ?? "none")'")
            candidates.append(BookCoverCandidate(title: combinedTitle, author: author, confidence: confidence))
        }

        // Remove duplicates and sort by confidence
        candidates = candidates.uniqued(by: { $0.title.lowercased() })
        candidates.sort { $0.confidence > $1.confidence }

        print("📖 [Parser] Generated \(candidates.count) candidates")
        return Array(candidates.prefix(3)) // Return top 3 candidates
    }

    // MARK: - Helper Methods

    /// Combines text elements that appear on the same horizontal line
    private func combineTextOnSameLines(_ elements: [(text: String, bounds: CGRect, confidence: Float)]) -> [(text: String, bounds: CGRect, confidence: Float)] {
        var combined: [(text: String, bounds: CGRect, confidence: Float)] = []
        var used = Set<Int>()

        for (index, element) in elements.enumerated() {
            guard !used.contains(index) else { continue }

            // Find all elements on the same line (within 0.02 Y tolerance)
            var sameLine: [(text: String, bounds: CGRect, confidence: Float)] = [element]
            used.insert(index)

            for (otherIndex, otherElement) in elements.enumerated() {
                guard otherIndex != index && !used.contains(otherIndex) else { continue }

                let yDifference = abs(element.bounds.midY - otherElement.bounds.midY)
                if yDifference < 0.06 {  // Same line threshold (widened to catch slightly offset text)
                    sameLine.append(otherElement)
                    used.insert(otherIndex)
                }
            }

            // Sort by X position (left to right) and combine
            sameLine.sort { $0.bounds.minX < $1.bounds.minX }
            let combinedText = sameLine.map { $0.text }.joined(separator: " ")

            // Use the largest bounds and average confidence
            let largestBounds = sameLine.max(by: { $0.bounds.height < $1.bounds.height })!.bounds
            let avgConfidence = sameLine.map { $0.confidence }.reduce(0, +) / Float(sameLine.count)

            combined.append((text: combinedText, bounds: largestBounds, confidence: avgConfidence))
        }

        return combined
    }

    /// Finds the absolute largest text element by font size
    private func findLargestText(_ elements: [(text: String, bounds: CGRect, confidence: Float)]) -> (text: String, bounds: CGRect, confidence: Float)? {
        return elements.max(by: { $0.bounds.height < $1.bounds.height })
    }

    /// Finds the largest text that doesn't look like an author name
    private func findLargestTextExcludingAuthors(_ elements: [(text: String, bounds: CGRect, confidence: Float)]) -> (text: String, bounds: CGRect, confidence: Float)? {
        // Filter out elements that look like author names
        let nonAuthorElements = elements.filter { element in
            let couldBeAuthor = isLikelyAuthorName(element.text)
            if couldBeAuthor {
                print("📖 [Parser] Excluding potential author from title search: '\(element.text)'")
            }
            return !couldBeAuthor
        }

        // Return the largest non-author element
        return nonAuthorElements.max(by: { $0.bounds.height < $1.bounds.height })
    }

    /// Combines adjacent large text elements that might form a title
    private func findCombinedTitle(_ elements: [(text: String, bounds: CGRect, confidence: Float)]) -> String? {
        // Find large elements in the top half
        let titleCandidates = elements.filter { element in
            element.bounds.midY > 0.6 &&  // Top 40% only
            element.bounds.height > 0.015 &&  // Must be reasonably large
            !isLikelyAuthorName(element.text)  // Not an author name
        }

        guard titleCandidates.count >= 2 else { return nil }

        // Only combine elements that are very similar in size (within 70% of largest)
        let largestHeight = titleCandidates.map { $0.bounds.height }.max() ?? 0
        let similarSized = titleCandidates.filter { $0.bounds.height >= largestHeight * 0.7 }

        guard similarSized.count >= 2 else { return nil }

        // Take up to 3 elements to avoid including junk
        let titleParts = similarSized.prefix(3).map { $0.text }
        let combined = titleParts.joined(separator: " ")

        // Don't return if it contains obvious non-title text
        let lowercased = combined.lowercased()
        if lowercased.contains("river") || lowercased.contains("freedom") || lowercased.contains("way to") {
            return nil
        }

        return combined
    }

    /// Attempts to add spaces to concatenated words using general pattern detection
    private func correctWordSpacing(_ text: String) -> String {
        // For now, just return the text as-is
        // OCR concatenation is hard to fix generically without a dictionary
        // The search API should handle minor variations
        return text
    }

    /// Finds an author name in the list of text elements
    private func findAuthorInElements(_ elements: [(text: String, bounds: CGRect, confidence: Float)]) -> String? {
        // Filter for likely author names that aren't at the very top/bottom edges (avoid quote attributions)
        let authorCandidates = elements.filter { element in
            let isName = isLikelyAuthorName(element.text)
            // Avoid very top (y > 0.75) where quotes often appear
            // Avoid very bottom (y < 0.25) where publisher info appears
            let isInGoodPosition = element.bounds.midY >= 0.25 && element.bounds.midY <= 0.75

            if isName && !isInGoodPosition {
                print("📖 [Parser] Rejecting author candidate '\(element.text)' - bad position (y: \(String(format: "%.2f", element.bounds.midY)))")
            }

            return isName && isInGoodPosition
        }

        return authorCandidates.first?.text
    }

    /// Filters out common noise text found on book covers
    private func shouldFilterOutText(_ text: String) -> Bool {
        let lowercased = text.lowercased()

        // Common publishers
        let publishers = [
            "scholastic", "penguin", "random house", "harpercollins", "simon & schuster",
            "macmillan", "hachette", "oxford", "cambridge", "vintage", "bantam",
            "ballantine", "dell", "tor", "daw", "ace", "berkley", "signet"
        ]

        for publisher in publishers {
            if lowercased.contains(publisher) {
                return true
            }
        }

        // Series/edition markers (check if text contains these)
        let seriesMarkers = [
            "classics", "classic", "edition", "series", "collection", "library",
            "anniversary", "special edition", "illustrated", "apple classics"
        ]

        for marker in seriesMarkers {
            if lowercased.contains(marker) {  // Check if contains the marker
                return true
            }
        }

        // ISBN patterns (digits with dashes/colons)
        let isbnPattern = "[0-9IlO:]{1,3}[-:\\s][0-9IlO:]{1,5}[-:\\s][0-9IlO:]{1,7}"
        if let regex = try? NSRegularExpression(pattern: isbnPattern),
           regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
            return true
        }

        // Barcodes (long sequences of digits)
        let digitsOnly = text.filter { $0.isNumber }
        if digitsOnly.count >= 8 {
            return true
        }

        // Price patterns
        let pricePattern = "[$£€¥]\\s*[0-9]+\\.?[0-9]*"
        if let regex = try? NSRegularExpression(pattern: pricePattern),
           regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
            return true
        }

        return false
    }

    private func findLargestTextAtTop(_ elements: [(text: String, bounds: CGRect, confidence: Float)]) -> (text: String, bounds: CGRect, confidence: Float)? {
        // Get elements in top 40% of image
        let topElements = elements.filter { $0.bounds.midY > 0.6 }

        // Find largest by height (font size indicator)
        return topElements.max(by: { $0.bounds.height < $1.bounds.height })
    }

    private func findAuthorNear(_ titleElement: (text: String, bounds: CGRect, confidence: Float), in elements: [(text: String, bounds: CGRect, confidence: Float)]) -> String? {
        // Look for medium-sized text below the title
        let belowTitle = elements.filter { element in
            element.bounds.midY < titleElement.bounds.midY - 0.05 && // Below with gap
            element.text != titleElement.text && // Not the title itself
            element.bounds.height >= 0.015 && // Not too small
            element.bounds.height < titleElement.bounds.height * 0.8 && // Smaller than title
            element.bounds.midY >= 0.25 && element.bounds.midY <= 0.75 // Valid range
        }

        // Sort by size (largest first) - author names are usually the next-largest text
        let sorted = belowTitle.sorted { $0.bounds.height > $1.bounds.height }

        // Check for "by" pattern first
        for element in sorted {
            if element.text.lowercased().hasPrefix("by ") {
                let authorName = element.text.replacingOccurrences(of: "by ", with: "", options: [.caseInsensitive, .anchored])
                print("📖 [Parser] Found author via 'by' pattern: '\(authorName)'")
                return authorName
            }
        }

        // Otherwise, take the largest text below the title that looks like a name
        for element in sorted {
            if isLikelyAuthorName(element.text) {
                print("📖 [Parser] Found author via name pattern: '\(element.text)'")
                return element.text
            }
        }

        return nil
    }

    private func findByPattern(in elements: [(text: String, bounds: CGRect, confidence: Float)]) -> (title: String, author: String?)? {
        for (index, element) in elements.enumerated() {
            let text = element.text.lowercased()

            // Look for "by [author]" pattern
            if text.hasPrefix("by ") && index > 0 {
                let title = elements[index - 1].text
                let author = element.text.replacingOccurrences(of: "by ", with: "", options: [.caseInsensitive, .anchored])
                return (title: title, author: author)
            }

            // Look for "Title by Author" in single line
            if text.contains(" by ") {
                let parts = element.text.components(separatedBy: " by ")
                if parts.count == 2 {
                    return (title: parts[0], author: parts[1])
                }
            }
        }

        return nil
    }

    private func isLikelyAuthorName(_ text: String) -> Bool {
        let words = text.components(separatedBy: " ")

        // Author names are usually 2-4 words
        guard words.count >= 2 && words.count <= 4 else { return false }

        // Check if each word is capitalized
        let allCapitalized = words.allSatisfy { word in
            guard let first = word.first else { return false }
            return first.isUppercase
        }

        // Reject obvious non-name patterns
        let excludePatterns = ["press", "books", "publishing", "edition", "series", "volume"]
        let hasExcludedWord = excludePatterns.contains { pattern in
            text.lowercased().contains(pattern)
        }

        // Author names should be mostly letters and spaces, minimal punctuation
        let letterSpaceCount = text.filter { $0.isLetter || $0.isWhitespace }.count
        let hasEnoughLetters = Double(letterSpaceCount) / Double(max(text.count, 1)) > 0.85

        // Names rarely have more than one common article/preposition
        let commonWords = ["the", "and", "of", "in", "on", "at", "to", "for", "with"]
        let lowercased = text.lowercased()
        let commonWordCount = commonWords.filter { lowercased.contains($0) }.count
        let tooManyCommonWords = commonWordCount > 1

        // Each word should be relatively short (names are typically 2-12 chars per word)
        let wordLengthsReasonable = words.allSatisfy { $0.count >= 2 && $0.count <= 15 }

        return allCapitalized && !hasExcludedWord && hasEnoughLetters && !tooManyCommonWords && wordLengthsReasonable
    }

    private func calculateConfidence(titleSize: CGFloat, hasAuthor: Bool) -> Float {
        var confidence: Float = 0.5

        // Larger text = more confident it's the title
        if titleSize > 0.15 {
            confidence += 0.3
        } else if titleSize > 0.10 {
            confidence += 0.2
        } else if titleSize > 0.05 {
            confidence += 0.1
        }

        // Having an author increases confidence
        if hasAuthor {
            confidence += 0.15
        }

        return min(confidence, 1.0)
    }
}

// MARK: - Array Extension for Unique Elements

extension Array {
    func uniqued<T: Hashable>(by keyPath: (Element) -> T) -> [Element] {
        var seen = Set<T>()
        return filter { element in
            let key = keyPath(element)
            return seen.insert(key).inserted
        }
    }
}
