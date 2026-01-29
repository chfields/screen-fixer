import Foundation
import CoreGraphics

/// Service for enumerating and managing displays
final class DisplayManager {
    static let shared = DisplayManager()

    private let identifier = DisplayIdentifier.shared

    private init() {}

    /// Get all currently connected displays
    func getConnectedDisplays() -> [Display] {
        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &displayCount)

        guard displayCount > 0 else { return [] }

        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetActiveDisplayList(displayCount, &displayIDs, &displayCount)

        // Build port ID mapping for all displays at once
        let portIDMapping = identifier.buildPortIDMapping()

        return displayIDs.compactMap { displayID -> Display? in
            createDisplay(from: displayID, portIDMapping: portIDMapping)
        }
    }

    /// Get the main display
    func getMainDisplay() -> Display? {
        let mainID = CGMainDisplayID()
        let portIDMapping = identifier.buildPortIDMapping()
        return createDisplay(from: mainID, portIDMapping: portIDMapping)
    }

    /// Get a display by its CGDirectDisplayID
    func getDisplay(by displayID: CGDirectDisplayID) -> Display? {
        let portIDMapping = identifier.buildPortIDMapping()
        return createDisplay(from: displayID, portIDMapping: portIDMapping)
    }

    /// Get displays matching a set of unique identifiers
    func getDisplays(matching identifiers: Set<String>) -> [Display] {
        getConnectedDisplays().filter { identifiers.contains($0.uniqueIdentifier) }
    }

    /// Check if the current display configuration matches a profile
    func configurationMatches(profile: DisplayProfile) -> Bool {
        let currentDisplays = getConnectedDisplays()
        let currentIdentifiers = Set(currentDisplays.map { $0.uniqueIdentifier })
        return profile.matches(displayIdentifiers: currentIdentifiers)
    }

    /// Find a profile that matches the current display configuration
    func findMatchingProfile(from profiles: [DisplayProfile]) -> DisplayProfile? {
        let currentDisplays = getConnectedDisplays()
        let currentIdentifiers = Set(currentDisplays.map { $0.uniqueIdentifier })

        return profiles.first { $0.matches(displayIdentifiers: currentIdentifiers) }
    }

    // MARK: - Private Methods

    private func createDisplay(from displayID: CGDirectDisplayID, portIDMapping: [CGDirectDisplayID: UInt32]) -> Display? {
        let bounds = CGDisplayBounds(displayID)
        let vendorID = CGDisplayVendorNumber(displayID)
        let modelID = CGDisplayModelNumber(displayID)
        let serialNumber = CGDisplaySerialNumber(displayID)
        let isMain = CGDisplayIsMain(displayID) != 0
        let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0

        // Get port ID from mapping or try individual lookup
        let portID = portIDMapping[displayID] ?? identifier.getPortID(for: displayID)

        // Get display name
        let name = identifier.getDisplayName(for: displayID)

        return Display(
            displayID: displayID,
            vendorID: vendorID,
            modelID: modelID,
            serialNumber: serialNumber,
            portID: portID,
            position: DisplayPosition(from: bounds),
            isMain: isMain,
            isBuiltIn: isBuiltIn,
            name: name
        )
    }
}
