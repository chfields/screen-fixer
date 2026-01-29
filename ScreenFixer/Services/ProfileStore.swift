import Foundation

/// Service for persisting display profiles
final class ProfileStore {
    static let shared = ProfileStore()

    private let userDefaults = UserDefaults.standard
    private let profilesKey = "SavedDisplayProfiles"
    private let autoApplyEnabledKey = "AutoApplyEnabled"
    private let lastAppliedProfileKey = "LastAppliedProfileID"

    private init() {}

    // MARK: - Profile Management

    /// Load all saved profiles
    func loadProfiles() -> [DisplayProfile] {
        guard let data = userDefaults.data(forKey: profilesKey) else {
            return []
        }

        do {
            let profiles = try JSONDecoder().decode([DisplayProfile].self, from: data)
            return profiles.sorted { $0.modifiedAt > $1.modifiedAt }
        } catch {
            print("Failed to decode profiles: \(error)")
            return []
        }
    }

    /// Save profiles to storage
    func saveProfiles(_ profiles: [DisplayProfile]) {
        do {
            let data = try JSONEncoder().encode(profiles)
            userDefaults.set(data, forKey: profilesKey)
        } catch {
            print("Failed to encode profiles: \(error)")
        }
    }

    /// Add a new profile
    func addProfile(_ profile: DisplayProfile) {
        var profiles = loadProfiles()
        profiles.insert(profile, at: 0)
        saveProfiles(profiles)
    }

    /// Update an existing profile
    func updateProfile(_ profile: DisplayProfile) {
        var profiles = loadProfiles()
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveProfiles(profiles)
        }
    }

    /// Delete a profile
    func deleteProfile(_ profile: DisplayProfile) {
        var profiles = loadProfiles()
        profiles.removeAll { $0.id == profile.id }
        saveProfiles(profiles)
    }

    /// Delete a profile by ID
    func deleteProfile(id: UUID) {
        var profiles = loadProfiles()
        profiles.removeAll { $0.id == id }
        saveProfiles(profiles)
    }

    /// Get a profile by ID
    func getProfile(id: UUID) -> DisplayProfile? {
        loadProfiles().first { $0.id == id }
    }

    /// Rename a profile
    func renameProfile(id: UUID, newName: String) {
        var profiles = loadProfiles()
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            profiles[index].name = newName
            profiles[index].modifiedAt = Date()
            saveProfiles(profiles)
        }
    }

    // MARK: - Auto-Apply Settings

    /// Whether auto-apply is enabled
    var isAutoApplyEnabled: Bool {
        get { userDefaults.bool(forKey: autoApplyEnabledKey) }
        set { userDefaults.set(newValue, forKey: autoApplyEnabledKey) }
    }

    /// The ID of the last applied profile
    var lastAppliedProfileID: UUID? {
        get {
            guard let string = userDefaults.string(forKey: lastAppliedProfileKey) else { return nil }
            return UUID(uuidString: string)
        }
        set {
            userDefaults.set(newValue?.uuidString, forKey: lastAppliedProfileKey)
        }
    }

    /// Record that a profile was applied
    func recordProfileApplied(_ profile: DisplayProfile) {
        lastAppliedProfileID = profile.id
    }

    // MARK: - Convenience Methods

    /// Find a profile matching the current display configuration
    func findMatchingProfile(for displays: [Display]) -> DisplayProfile? {
        let identifiers = Set(displays.map { $0.uniqueIdentifier })
        return loadProfiles().first { $0.matches(displayIdentifiers: identifiers) }
    }

    /// Check if a profile with the given name already exists
    func profileExists(named name: String) -> Bool {
        loadProfiles().contains { $0.name.lowercased() == name.lowercased() }
    }
}
