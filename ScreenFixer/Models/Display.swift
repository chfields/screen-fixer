import Foundation
import CoreGraphics

/// Represents a connected display with a unique identifier
struct Display: Identifiable, Equatable, Hashable {
    /// The CGDirectDisplayID from the system
    let displayID: CGDirectDisplayID

    /// Vendor ID from IOKit
    let vendorID: UInt32

    /// Model ID from IOKit
    let modelID: UInt32

    /// Serial number (often 0 for identical monitors)
    let serialNumber: UInt32

    /// Port ID from IOKit - unique per physical port
    let portID: UInt32?

    /// Current position and size
    let position: DisplayPosition

    /// Whether this is the main display
    let isMain: Bool

    /// Whether this is a built-in display
    let isBuiltIn: Bool

    /// Human-readable name if available
    let name: String?

    /// Unique identifier combining vendor, model, and port
    var uniqueIdentifier: String {
        if let portID = portID {
            return "\(vendorID)-\(modelID)-\(portID)"
        }
        // Fallback for displays without port ID
        return "\(vendorID)-\(modelID)-\(serialNumber)-\(displayID)"
    }

    var id: String {
        uniqueIdentifier
    }

    /// Display description for UI
    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        if isBuiltIn {
            return "Built-in Display"
        }
        return "Display \(displayID)"
    }

    /// Short description showing position
    var positionDescription: String {
        "(\(position.x), \(position.y))"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueIdentifier)
    }

    static func == (lhs: Display, rhs: Display) -> Bool {
        lhs.uniqueIdentifier == rhs.uniqueIdentifier
    }
}
