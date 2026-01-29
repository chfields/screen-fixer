# ScreenFixer

A macOS menu bar app that automatically manages external monitor arrangements, solving the problem of identical monitors getting swapped when reconnecting to a docking station.

## The Problem

When two identical monitors are connected via a docking station, macOS sometimes confuses their left/right positions because they have the same vendor ID, model ID, and often serial number (0). This means you have to manually rearrange your displays in System Settings every time you reconnect.

## The Solution

ScreenFixer uniquely identifies each monitor using IOKit's PortID, which is stable per physical port on your dock. This allows the app to:

1. **Save** your current display arrangement as a profile
2. **Auto-apply** the correct arrangement when monitors reconnect
3. **Restore** your preferred setup with one click

## Requirements

- macOS 13.0 or later
- Apple Silicon or Intel Mac

## Installation

1. Clone this repository
2. Open `ScreenFixer.xcodeproj` in Xcode
3. Build and run (⌘R)
4. The app appears in your menu bar with a display icon

## Usage

1. **Arrange your displays** correctly in System Settings > Displays
2. **Click the ScreenFixer icon** in the menu bar
3. **Save Current Arrangement** and give it a name
4. **Enable Auto-Apply on Connect** to automatically restore your arrangement

When you disconnect and reconnect your monitors, ScreenFixer will automatically apply your saved profile.

## How It Works

### Unique Monitor Identification

On Apple Silicon Macs, ScreenFixer queries IOKit's `IOMobileFramebufferShim` to get a `PortID` from `DisplayAttributes`. This ID is:
- Unique per physical connection port on your dock
- Stable across reconnections to the same port

The unique identifier format is: `{vendorID}-{modelID}-{portID}`

### Display Configuration

- Positions are captured via `CGDisplayBounds()`
- Arrangements are applied using `CGBeginDisplayConfiguration`, `CGConfigureDisplayOrigin`, and `CGCompleteDisplayConfiguration`

### Change Detection

The app registers a `CGDisplayReconfigurationCallback` to detect when displays are added or removed, with debouncing to ensure stable detection.

## Project Structure

```
ScreenFixer/
├── App/
│   └── ScreenFixerApp.swift          # MenuBarExtra entry point
├── Models/
│   ├── Display.swift                 # Display model with unique ID
│   ├── DisplayProfile.swift          # Saved arrangement profile
│   └── DisplayPosition.swift         # Position data structure
├── Services/
│   ├── DisplayManager.swift          # Display enumeration
│   ├── DisplayIdentifier.swift       # IOKit PortID resolution
│   ├── DisplayConfigurationService.swift  # Apply positions
│   └── ProfileStore.swift            # UserDefaults persistence
├── ViewModels/
│   └── MenuBarViewModel.swift        # UI state management
├── Views/
│   ├── MenuBarView.swift             # Main menu content
│   └── SaveProfileSheet.swift        # Profile naming dialog
└── Utilities/
    └── DisplayChangeObserver.swift   # Display change detection
```

## License

MIT
