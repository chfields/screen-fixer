import Foundation
import CoreGraphics

/// Represents the position and size of a display
struct DisplayPosition: Codable, Equatable {
    let x: Int
    let y: Int
    let width: Int
    let height: Int

    init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    init(from bounds: CGRect) {
        self.x = Int(bounds.origin.x)
        self.y = Int(bounds.origin.y)
        self.width = Int(bounds.width)
        self.height = Int(bounds.height)
    }

    var origin: CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }

    var size: CGSize {
        CGSize(width: CGFloat(width), height: CGFloat(height))
    }

    var bounds: CGRect {
        CGRect(origin: origin, size: size)
    }
}
