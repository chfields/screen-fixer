import Foundation
import CoreGraphics

/// Observer for display configuration changes
final class DisplayChangeObserver {
    static let shared = DisplayChangeObserver()

    /// Callback when display configuration changes
    var onDisplaysChanged: (() -> Void)?

    /// Debounce interval in seconds
    var debounceInterval: TimeInterval = 1.0

    private var isObserving = false
    private var debounceWorkItem: DispatchWorkItem?
    private let callbackQueue = DispatchQueue.main

    private init() {}

    /// Start observing display changes
    func startObserving() {
        guard !isObserving else { return }

        let callback: CGDisplayReconfigurationCallBack = { displayID, flags, userInfo in
            guard let observer = userInfo?.assumingMemoryBound(to: DisplayChangeObserver.self).pointee else {
                return
            }

            // Only respond to display add/remove events
            let isRelevantChange = flags.contains(.addFlag) ||
                                   flags.contains(.removeFlag) ||
                                   flags.contains(.movedFlag)

            if isRelevantChange {
                observer.scheduleCallback()
            }
        }

        // Create a pointer to self for the callback
        var observer = self
        let pointer = withUnsafeMutablePointer(to: &observer) { $0 }

        CGDisplayRegisterReconfigurationCallback(callback, pointer)
        isObserving = true
    }

    /// Stop observing display changes
    func stopObserving() {
        guard isObserving else { return }

        let callback: CGDisplayReconfigurationCallBack = { _, _, _ in }
        CGDisplayRemoveReconfigurationCallback(callback, nil)

        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        isObserving = false
    }

    // MARK: - Private Methods

    private func scheduleCallback() {
        // Cancel any pending callback
        debounceWorkItem?.cancel()

        // Schedule new debounced callback
        let workItem = DispatchWorkItem { [weak self] in
            self?.onDisplaysChanged?()
        }

        debounceWorkItem = workItem
        callbackQueue.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
}

/// A more robust display change observer using a singleton callback
final class DisplayChangeNotifier: ObservableObject {
    static let shared = DisplayChangeNotifier()

    @Published private(set) var changeCount: Int = 0

    private var isRegistered = false
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 1.5

    /// Callbacks registered for display changes
    private var callbacks: [UUID: () -> Void] = [:]

    private init() {}

    /// Register for display change notifications
    func register() {
        guard !isRegistered else { return }

        // Use a static function as the callback
        CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
        isRegistered = true
    }

    /// Unregister from display change notifications
    func unregister() {
        guard isRegistered else { return }

        CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
        isRegistered = false
    }

    /// Add a callback for display changes
    func addCallback(_ callback: @escaping () -> Void) -> UUID {
        let id = UUID()
        callbacks[id] = callback
        return id
    }

    /// Remove a callback
    func removeCallback(_ id: UUID) {
        callbacks.removeValue(forKey: id)
    }

    /// Called when displays change (debounced)
    fileprivate func notifyDisplaysChanged() {
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.changeCount += 1
                for callback in self.callbacks.values {
                    callback()
                }
            }
        }

        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
}

/// Static callback function for CGDisplayRegisterReconfigurationCallback
private func displayReconfigurationCallback(
    displayID: CGDirectDisplayID,
    flags: CGDisplayChangeSummaryFlags,
    userInfo: UnsafeMutableRawPointer?
) {
    guard let userInfo = userInfo else { return }

    let isRelevantChange = flags.contains(.addFlag) ||
                           flags.contains(.removeFlag) ||
                           flags.contains(.movedFlag)

    guard isRelevantChange else { return }

    let notifier = Unmanaged<DisplayChangeNotifier>.fromOpaque(userInfo).takeUnretainedValue()
    notifier.notifyDisplaysChanged()
}
