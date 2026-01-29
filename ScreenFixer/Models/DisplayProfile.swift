import Foundation

/// A saved display arrangement profile
struct DisplayProfile: Codable, Identifiable, Equatable {
    /// Unique identifier for the profile
    let id: UUID

    /// User-defined name for the profile
    var name: String

    /// When the profile was created
    let createdAt: Date

    /// When the profile was last modified
    var modifiedAt: Date

    /// Display arrangements keyed by unique identifier
    var displayArrangements: [String: DisplayPosition]

    /// The unique identifiers of displays in this profile (for matching)
    var displayIdentifiers: Set<String> {
        Set(displayArrangements.keys)
    }

    /// Number of displays in this profile
    var displayCount: Int {
        displayArrangements.count
    }

    init(name: String, arrangements: [String: DisplayPosition]) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.displayArrangements = arrangements
    }

    /// Check if this profile matches the given set of display identifiers
    func matches(displayIdentifiers: Set<String>) -> Bool {
        self.displayIdentifiers == displayIdentifiers
    }

    /// Get the position for a display by its unique identifier
    func position(for identifier: String) -> DisplayPosition? {
        displayArrangements[identifier]
    }

    mutating func updateArrangements(_ arrangements: [String: DisplayPosition]) {
        self.displayArrangements = arrangements
        self.modifiedAt = Date()
    }
}
