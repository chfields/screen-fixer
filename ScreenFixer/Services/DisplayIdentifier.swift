import Foundation
import IOKit
import CoreGraphics

/// Service for identifying displays using IOKit PortID
final class DisplayIdentifier {
    static let shared = DisplayIdentifier()

    private init() {}

    /// Get the PortID for a display from IOKit
    /// Returns nil if PortID cannot be determined
    func getPortID(for displayID: CGDirectDisplayID) -> UInt32? {
        // Try Apple Silicon path first (IOMobileFramebufferShim)
        if let portID = getPortIDAppleSilicon(for: displayID) {
            return portID
        }

        // Fallback to Intel path (IODisplayConnect)
        return getPortIDIntel(for: displayID)
    }

    /// Get display info dictionary from IOKit
    func getDisplayInfo(for displayID: CGDirectDisplayID) -> [String: Any]? {
        var iterator: io_iterator_t = 0

        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iterator
        )

        guard result == kIOReturnSuccess else { return nil }
        defer { IOObjectRelease(iterator) }

        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }

            if let info = IODisplayCreateInfoDictionary(service, IOOptionBits(kIODisplayOnlyPreferredName))?.takeRetainedValue() as? [String: Any] {
                if let vendorID = info[kDisplayVendorID] as? UInt32,
                   let productID = info[kDisplayProductID] as? UInt32 {
                    let expectedVendor = CGDisplayVendorNumber(displayID)
                    let expectedModel = CGDisplayModelNumber(displayID)

                    if vendorID == expectedVendor && productID == expectedModel {
                        return info
                    }
                }
            }
        }
        return nil
    }

    /// Get display name from IOKit
    func getDisplayName(for displayID: CGDirectDisplayID) -> String? {
        guard let info = getDisplayInfo(for: displayID) else { return nil }

        if let names = info[kDisplayProductName] as? [String: String] {
            // Return the first available localized name
            return names.values.first
        }
        return nil
    }

    // MARK: - Private Methods

    /// Apple Silicon path using IOMobileFramebufferShim
    private func getPortIDAppleSilicon(for displayID: CGDirectDisplayID) -> UInt32? {
        var iterator: io_iterator_t = 0

        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOMobileFramebufferShim"),
            &iterator
        )

        guard result == kIOReturnSuccess else { return nil }
        defer { IOObjectRelease(iterator) }

        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }

            // Get DisplayAttributes dictionary
            var properties: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess,
                  let props = properties?.takeRetainedValue() as? [String: Any] else {
                continue
            }

            // Look for DisplayAttributes containing PortID
            if let displayAttrs = props["DisplayAttributes"] as? [String: Any],
               let portID = displayAttrs["PortID"] as? UInt32 {
                // Match by checking if this service corresponds to our displayID
                if let productAttrs = displayAttrs["ProductAttributes"] as? [String: Any],
                   let vendorID = productAttrs["LegacyManufacturerID"] as? UInt32,
                   let productID = productAttrs["LegacyProductID"] as? UInt32 {
                    if vendorID == CGDisplayVendorNumber(displayID) &&
                       productID == CGDisplayModelNumber(displayID) {
                        return portID
                    }
                }
            }
        }
        return nil
    }

    /// Intel Mac path using IODisplayConnect
    private func getPortIDIntel(for displayID: CGDirectDisplayID) -> UInt32? {
        var iterator: io_iterator_t = 0

        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iterator
        )

        guard result == kIOReturnSuccess else { return nil }
        defer { IOObjectRelease(iterator) }

        var portIndex: UInt32 = 0

        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }

            if let info = IODisplayCreateInfoDictionary(service, IOOptionBits(kIODisplayOnlyPreferredName))?.takeRetainedValue() as? [String: Any] {
                if let vendorID = info[kDisplayVendorID] as? UInt32,
                   let productID = info[kDisplayProductID] as? UInt32 {
                    if vendorID == CGDisplayVendorNumber(displayID) &&
                       productID == CGDisplayModelNumber(displayID) {
                        // Use the iteration index as a pseudo-port ID
                        // This provides some differentiation even without true PortID
                        return portIndex
                    }
                }
            }
            portIndex += 1
        }
        return nil
    }

    /// Build mapping of all current displays to their PortIDs
    func buildPortIDMapping() -> [CGDirectDisplayID: UInt32] {
        var mapping: [CGDirectDisplayID: UInt32] = [:]

        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &displayCount)

        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetActiveDisplayList(displayCount, &displays, &displayCount)

        // First pass: try to get PortIDs from IOMobileFramebufferShim (Apple Silicon)
        var iterator: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOMobileFramebufferShim"), &iterator) == kIOReturnSuccess {
            defer { IOObjectRelease(iterator) }

            var framebufferInfos: [(vendorID: UInt32, modelID: UInt32, portID: UInt32)] = []

            while case let service = IOIteratorNext(iterator), service != 0 {
                defer { IOObjectRelease(service) }

                var properties: Unmanaged<CFMutableDictionary>?
                guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess,
                      let props = properties?.takeRetainedValue() as? [String: Any] else {
                    continue
                }

                if let displayAttrs = props["DisplayAttributes"] as? [String: Any],
                   let portID = displayAttrs["PortID"] as? UInt32,
                   let productAttrs = displayAttrs["ProductAttributes"] as? [String: Any],
                   let vendorID = productAttrs["LegacyManufacturerID"] as? UInt32,
                   let productID = productAttrs["LegacyProductID"] as? UInt32 {
                    framebufferInfos.append((vendorID, productID, portID))
                }
            }

            // Match displays to framebuffer info
            for displayID in displays {
                let vendor = CGDisplayVendorNumber(displayID)
                let model = CGDisplayModelNumber(displayID)

                // Find matching framebuffer info
                if let match = framebufferInfos.first(where: { $0.vendorID == vendor && $0.modelID == model }) {
                    mapping[displayID] = match.portID
                    // Remove to handle multiple identical displays
                    framebufferInfos.removeAll { $0.portID == match.portID }
                }
            }
        }

        return mapping
    }
}
