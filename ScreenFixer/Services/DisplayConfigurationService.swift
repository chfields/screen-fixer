import Foundation
import CoreGraphics

/// Error types for display configuration
enum DisplayConfigurationError: LocalizedError {
    case beginConfigurationFailed(CGError)
    case configureOriginFailed(CGError)
    case completeConfigurationFailed(CGError)
    case displayNotFound(String)
    case noDisplaysToArrange

    var errorDescription: String? {
        switch self {
        case .beginConfigurationFailed(let error):
            return "Failed to begin display configuration: \(error)"
        case .configureOriginFailed(let error):
            return "Failed to configure display origin: \(error)"
        case .completeConfigurationFailed(let error):
            return "Failed to complete display configuration: \(error)"
        case .displayNotFound(let identifier):
            return "Display not found: \(identifier)"
        case .noDisplaysToArrange:
            return "No displays to arrange"
        }
    }
}

/// Service for applying display configurations
final class DisplayConfigurationService {
    static let shared = DisplayConfigurationService()

    private let displayManager = DisplayManager.shared

    private init() {}

    /// Create a profile from the current display arrangement
    func createProfile(named name: String) -> DisplayProfile {
        let displays = displayManager.getConnectedDisplays()
        var arrangements: [String: DisplayPosition] = [:]

        for display in displays {
            arrangements[display.uniqueIdentifier] = display.position
        }

        return DisplayProfile(name: name, arrangements: arrangements)
    }

    /// Apply a saved profile to the current displays
    func applyProfile(_ profile: DisplayProfile) throws {
        let currentDisplays = displayManager.getConnectedDisplays()

        guard !currentDisplays.isEmpty else {
            throw DisplayConfigurationError.noDisplaysToArrange
        }

        // Build mapping from unique identifier to display ID
        var displayIDMapping: [String: CGDirectDisplayID] = [:]
        for display in currentDisplays {
            displayIDMapping[display.uniqueIdentifier] = display.displayID
        }

        // Prepare configuration changes
        var configChanges: [(displayID: CGDirectDisplayID, x: Int32, y: Int32)] = []

        for (identifier, position) in profile.displayArrangements {
            guard let displayID = displayIDMapping[identifier] else {
                // Display from profile not currently connected - skip it
                continue
            }
            configChanges.append((displayID, Int32(position.x), Int32(position.y)))
        }

        guard !configChanges.isEmpty else {
            throw DisplayConfigurationError.noDisplaysToArrange
        }

        // Apply configuration
        try applyConfiguration(configChanges)
    }

    /// Apply specific position changes to displays
    func applyPositions(_ positions: [(displayID: CGDirectDisplayID, x: Int, y: Int)]) throws {
        let changes = positions.map { (displayID: $0.displayID, x: Int32($0.x), y: Int32($0.y)) }
        try applyConfiguration(changes)
    }

    /// Swap the positions of two displays
    func swapDisplayPositions(_ display1: Display, _ display2: Display) throws {
        let changes: [(displayID: CGDirectDisplayID, x: Int32, y: Int32)] = [
            (display1.displayID, Int32(display2.position.x), Int32(display2.position.y)),
            (display2.displayID, Int32(display1.position.x), Int32(display1.position.y))
        ]
        try applyConfiguration(changes)
    }

    // MARK: - Private Methods

    private func applyConfiguration(_ changes: [(displayID: CGDirectDisplayID, x: Int32, y: Int32)]) throws {
        var configRef: CGDisplayConfigRef?

        // Begin configuration
        let beginResult = CGBeginDisplayConfiguration(&configRef)
        guard beginResult == .success, let config = configRef else {
            throw DisplayConfigurationError.beginConfigurationFailed(beginResult)
        }

        // Apply each position change
        for change in changes {
            let configResult = CGConfigureDisplayOrigin(config, change.displayID, change.x, change.y)
            guard configResult == .success else {
                CGCancelDisplayConfiguration(config)
                throw DisplayConfigurationError.configureOriginFailed(configResult)
            }
        }

        // Complete configuration
        let completeResult = CGCompleteDisplayConfiguration(config, .permanently)
        guard completeResult == .success else {
            throw DisplayConfigurationError.completeConfigurationFailed(completeResult)
        }
    }
}
