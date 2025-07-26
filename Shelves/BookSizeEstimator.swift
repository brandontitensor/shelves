import SwiftUI
#if canImport(UIKit)
import UIKit

struct BookSizeEstimator {
    static func estimateSize(from image: UIImage) -> String {
        let width = image.size.width
        let height = image.size.height
        let aspectRatio = height / width
        
        if aspectRatio > 1.8 {
            return "Pocket"
        } else if aspectRatio > 1.5 {
            return "Mass Market"
        } else if aspectRatio > 1.2 {
            return "Trade Paperback"
        } else if aspectRatio > 1.0 {
            return "Hardcover"
        } else {
            return "Large Print"
        }
    }
}
#endif