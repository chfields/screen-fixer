import Foundation
import SwiftUI
import Combine

/// View model for the menu bar UI
@MainActor
final class MenuBarViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var displays: [Display] = []
    @Published private(set) var profiles: [DisplayProfile] = []
    @Published private(set) var statusMessage: String?
    @Published var isAutoApplyEnabled: Bool {
        didSet {
            profileStore.isAutoApplyEnabled = isAutoApplyEnabled
        }
    }
    @Published var showingSaveSheet = false
    @Published var newProfileName = ""

    // MARK: - Private Properties

    private let displayManager = DisplayManager.shared
    private let configService = DisplayConfigurationService.shared
    private let profileStore = ProfileStore.shared
    private let displayNotifier = DisplayChangeNotifier.shared

    private var callbackID: UUID?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Whether a profile matches the current display configuration
    var hasMatchingProfile: Bool {
        let identifiers = Set(displays.map { $0.uniqueIdentifier })
        return profiles.contains { $0.matches(displayIdentifiers: identifiers) }
    }

    /// The profile matching current displays, if any
    var matchingProfile: DisplayProfile? {
        let identifiers = Set(displays.map { $0.uniqueIdentifier })
        return profiles.first { $0.matches(displayIdentifiers: identifiers) }
    }

    /// Whether we can save a profile (need at least one display)
    var canSaveProfile: Bool {
        !displays.isEmpty
    }

    /// External displays only (excluding built-in)
    var externalDisplays: [Display] {
        displays.filter { !$0.isBuiltIn }
    }

    // MARK: - Initialization

    init() {
        self.isAutoApplyEnabled = profileStore.isAutoApplyEnabled
        refresh()
        setupDisplayChangeObserver()
    }

    deinit {
        if let id = callbackID {
            displayNotifier.removeCallback(id)
        }
    }

    // MARK: - Public Methods

    /// Refresh display and profile data
    func refresh() {
        displays = displayManager.getConnectedDisplays()
        profiles = profileStore.loadProfiles()
        clearStatus()
    }

    /// Save current arrangement as a new profile
    func saveCurrentArrangement(named name: String) {
        let profile = configService.createProfile(named: name)
        profileStore.addProfile(profile)
        profiles = profileStore.loadProfiles()
        setStatus("Saved profile: \(name)")
    }

    /// Apply a saved profile
    func applyProfile(_ profile: DisplayProfile) {
        do {
            try configService.applyProfile(profile)
            profileStore.recordProfileApplied(profile)
            setStatus("Applied: \(profile.name)")
            // Refresh after a short delay to show new positions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.refresh()
            }
        } catch {
            setStatus("Error: \(error.localizedDescription)")
        }
    }

    /// Delete a profile
    func deleteProfile(_ profile: DisplayProfile) {
        profileStore.deleteProfile(profile)
        profiles = profileStore.loadProfiles()
        setStatus("Deleted: \(profile.name)")
    }

    /// Update an existing profile with current arrangement
    func updateProfile(_ profile: DisplayProfile) {
        let currentArrangements = displays.reduce(into: [String: DisplayPosition]()) { result, display in
            result[display.uniqueIdentifier] = display.position
        }
        var updatedProfile = profile
        updatedProfile.updateArrangements(currentArrangements)
        profileStore.updateProfile(updatedProfile)
        profiles = profileStore.loadProfiles()
        setStatus("Updated: \(profile.name)")
    }

    /// Swap positions of two displays
    func swapDisplays(_ display1: Display, _ display2: Display) {
        do {
            try configService.swapDisplayPositions(display1, display2)
            setStatus("Swapped displays")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.refresh()
            }
        } catch {
            setStatus("Error: \(error.localizedDescription)")
        }
    }

    /// Open the save profile sheet
    func openSaveSheet() {
        newProfileName = ""
        showingSaveSheet = true
    }

    /// Save from the sheet
    func saveFromSheet() {
        guard !newProfileName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        saveCurrentArrangement(named: newProfileName.trimmingCharacters(in: .whitespaces))
        showingSaveSheet = false
        newProfileName = ""
    }

    // MARK: - Private Methods

    private func setupDisplayChangeObserver() {
        displayNotifier.register()

        callbackID = displayNotifier.addCallback { [weak self] in
            Task { @MainActor in
                self?.handleDisplayChange()
            }
        }
    }

    private func handleDisplayChange() {
        refresh()

        guard isAutoApplyEnabled else { return }

        // Try to find and apply a matching profile
        if let matchingProfile = matchingProfile {
            // Check if arrangement already matches
            let needsApply = displays.contains { display in
                guard let savedPosition = matchingProfile.position(for: display.uniqueIdentifier) else {
                    return false
                }
                return display.position != savedPosition
            }

            if needsApply {
                applyProfile(matchingProfile)
            }
        }
    }

    private func setStatus(_ message: String) {
        statusMessage = message
        // Clear status after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if self?.statusMessage == message {
                self?.statusMessage = nil
            }
        }
    }

    private func clearStatus() {
        statusMessage = nil
    }
}
