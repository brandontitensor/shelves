import Foundation

/// Utility for validating and normalizing ISBN-10 and ISBN-13 formats
struct ISBNValidator {

    /// Validates and extracts ISBN from a string
    /// - Parameter text: The text that may contain an ISBN
    /// - Parameter requireISBNPrefix: If true, requires "ISBN" text to be present
    /// - Returns: A cleaned, valid ISBN string or nil if no valid ISBN found
    static func extractISBN(from text: String, requireISBNPrefix: Bool = false) -> String? {
        print("      🔍 [Validator] Extracting ISBN from: '\(text)' (requirePrefix: \(requireISBNPrefix))")

        // If requiring ISBN prefix, check for it first
        if requireISBNPrefix {
            let uppercased = text.uppercased()
            let hasISBNPrefix = uppercased.contains("ISBN")
            print("      🏷️ [Validator] ISBN prefix check: \(hasISBNPrefix)")

            if !hasISBNPrefix {
                print("      ❌ [Validator] Rejected: No ISBN prefix found")
                return nil
            }
        }

        // Remove common prefixes and clean the string
        let cleaned = text
            .replacingOccurrences(of: "ISBN", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "ISBN-10", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "ISBN-13", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "ISBN10", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "ISBN13", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces)

        print("      🧹 [Validator] Cleaned text: '\(cleaned)'")

        // Extract potential ISBN patterns
        let patterns = [
            // ISBN-13: 978-0-123456-78-9 or 9780123456789
            "\\d{3}[-\\s]?\\d{1,5}[-\\s]?\\d{1,7}[-\\s]?\\d{1,7}[-\\s]?\\d{1}",
            // ISBN-10: 0-123456-78-9 or 0123456789 or X ending
            "\\d{1,5}[-\\s]?\\d{1,7}[-\\s]?\\d{1,7}[-\\s]?[\\dX]"
        ]

        for (index, pattern) in patterns.enumerated() {
            print("      🔎 [Validator] Trying pattern \(index + 1)")
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(cleaned.startIndex..., in: cleaned)
                if let match = regex.firstMatch(in: cleaned, options: [], range: range) {
                    if let matchRange = Range(match.range, in: cleaned) {
                        let potentialISBN = String(cleaned[matchRange])
                        let normalized = normalize(potentialISBN)

                        print("      📐 [Validator] Found potential ISBN: '\(potentialISBN)' -> normalized: '\(normalized)'")

                        // Validate the extracted ISBN
                        let isValid13 = isValidISBN13(normalized)
                        let isValid10 = isValidISBN10(normalized)

                        print("      ✓ [Validator] ISBN-13 valid: \(isValid13), ISBN-10 valid: \(isValid10)")

                        // Prioritize book ISBNs (978/979 prefix)
                        if isValid13 {
                            let isBookISBN = isBookISBN13(normalized)
                            print("      📚 [Validator] Is book ISBN (978/979 prefix): \(isBookISBN)")

                            if isBookISBN {
                                print("      ✅ [Validator] Accepted book ISBN-13: \(normalized)")
                                return normalized
                            } else if !requireISBNPrefix {
                                // Accept non-book ISBN-13 only if we have ISBN context
                                print("      ⚠️ [Validator] Accepting non-book ISBN-13: \(normalized)")
                                return normalized
                            } else {
                                print("      ❌ [Validator] Rejected non-book ISBN-13 without context")
                            }
                        } else if isValid10 {
                            // ISBN-10 is more prone to false positives, be cautious
                            print("      ⚠️ [Validator] Found valid ISBN-10: \(normalized)")

                            // Only accept ISBN-10 if we have strong ISBN context
                            if !requireISBNPrefix {
                                print("      ✅ [Validator] Accepted ISBN-10 with context: \(normalized)")
                                return normalized
                            } else {
                                print("      ❌ [Validator] Rejected ISBN-10 without ISBN prefix")
                            }
                        } else {
                            print("      ❌ [Validator] Rejected (invalid checksum): \(normalized)")
                        }
                    }
                }
            }
        }

        // Try direct validation after removing all non-alphanumeric except X
        let directClean = cleaned.filter { $0.isNumber || $0 == "X" || $0 == "x" }
        let normalized = normalize(directClean)

        if !normalized.isEmpty {
            print("      🧪 [Validator] Trying direct clean: '\(normalized)'")

            let isValid13 = isValidISBN13(normalized)
            let isValid10 = isValidISBN10(normalized)

            print("      ✓ [Validator] Direct clean - ISBN-13 valid: \(isValid13), ISBN-10 valid: \(isValid10)")

            if isValid13 {
                let isBookISBN = isBookISBN13(normalized)
                print("      📚 [Validator] Direct clean - Is book ISBN: \(isBookISBN)")

                if isBookISBN {
                    print("      ✅ [Validator] Accepted direct clean book ISBN-13: \(normalized)")
                    return normalized
                } else if !requireISBNPrefix {
                    print("      ⚠️ [Validator] Accepting direct clean non-book ISBN-13: \(normalized)")
                    return normalized
                } else {
                    print("      ❌ [Validator] Rejected direct clean non-book ISBN-13 without context")
                }
            } else if isValid10 && !requireISBNPrefix {
                print("      ✅ [Validator] Accepted direct clean ISBN-10 with context: \(normalized)")
                return normalized
            } else if isValid10 {
                print("      ❌ [Validator] Rejected direct clean ISBN-10 without ISBN prefix")
            }
        }

        print("      ❌ [Validator] No valid ISBN found in text")
        return nil
    }

    /// Normalizes an ISBN by removing spaces, hyphens, and converting to uppercase
    static func normalize(_ isbn: String) -> String {
        return isbn
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
    }

    /// Validates an ISBN-13 using checksum algorithm
    static func isValidISBN13(_ isbn: String) -> Bool {
        let digits = isbn.filter { $0.isNumber }
        guard digits.count == 13 else { return false }

        var sum = 0
        for (index, char) in digits.enumerated() {
            guard let digit = Int(String(char)) else { return false }
            sum += digit * (index % 2 == 0 ? 1 : 3)
        }

        return sum % 10 == 0
    }

    /// Checks if an ISBN-13 is specifically for books (starts with 978 or 979 Bookland prefix)
    static func isBookISBN13(_ isbn: String) -> Bool {
        let normalized = normalize(isbn)
        guard normalized.count == 13 else { return false }
        guard isValidISBN13(normalized) else { return false }

        // Book ISBNs must start with 978 or 979 (Bookland prefix)
        return normalized.hasPrefix("978") || normalized.hasPrefix("979")
    }

    /// Validates an ISBN-10 using checksum algorithm
    static func isValidISBN10(_ isbn: String) -> Bool {
        guard isbn.count == 10 else { return false }

        var sum = 0
        for (index, char) in isbn.enumerated() {
            let multiplier = 10 - index

            if index == 9 && char == "X" {
                sum += 10 * multiplier
            } else if let digit = Int(String(char)) {
                sum += digit * multiplier
            } else {
                return false
            }
        }

        return sum % 11 == 0
    }

    /// Converts ISBN-10 to ISBN-13 by adding 978 prefix
    static func convertISBN10ToISBN13(_ isbn10: String) -> String? {
        guard isValidISBN10(isbn10) else { return nil }

        // Remove check digit and add 978 prefix
        let base = "978" + isbn10.dropLast()

        // Calculate new check digit for ISBN-13
        var sum = 0
        for (index, char) in base.enumerated() {
            guard let digit = Int(String(char)) else { return nil }
            sum += digit * (index % 2 == 0 ? 1 : 3)
        }

        let checkDigit = (10 - (sum % 10)) % 10
        return base + String(checkDigit)
    }

    /// Formats an ISBN with hyphens for readability
    static func format(_ isbn: String) -> String {
        let normalized = normalize(isbn)

        if normalized.count == 13 {
            // Format ISBN-13: 978-0-123456-78-9
            let prefix = normalized.prefix(3)
            let group = normalized.dropFirst(3).prefix(1)
            let publisher = normalized.dropFirst(4).prefix(6)
            let title = normalized.dropFirst(10).prefix(2)
            let check = normalized.suffix(1)
            return "\(prefix)-\(group)-\(publisher)-\(title)-\(check)"
        } else if normalized.count == 10 {
            // Format ISBN-10: 0-123456-78-9
            let group = normalized.prefix(1)
            let publisher = normalized.dropFirst(1).prefix(6)
            let title = normalized.dropFirst(7).prefix(2)
            let check = normalized.suffix(1)
            return "\(group)-\(publisher)-\(title)-\(check)"
        }

        return normalized
    }
}
