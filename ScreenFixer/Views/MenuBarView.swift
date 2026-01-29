import SwiftUI

/// Main menu bar view
struct MenuBarView: View {
    @StateObject private var viewModel = MenuBarViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection

            Divider()

            // Current displays
            displaysSection

            if !viewModel.profiles.isEmpty {
                Divider()
                // Saved profiles
                profilesSection
            }

            Divider()

            // Actions
            actionsSection

            Divider()

            // Footer
            footerSection
        }
        .frame(width: 280)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            Image(systemName: "display.2")
                .foregroundColor(.secondary)
            Text("ScreenFixer")
                .font(.headline)
            Spacer()
            if let status = viewModel.statusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var displaysSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Connected Displays")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ForEach(viewModel.displays) { display in
                DisplayRow(display: display)
            }

            if viewModel.displays.isEmpty {
                Text("No displays detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            }
        }
        .padding(.bottom, 8)
    }

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Saved Profiles")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ForEach(viewModel.profiles) { profile in
                ProfileRow(
                    profile: profile,
                    isMatching: viewModel.matchingProfile?.id == profile.id,
                    onApply: { viewModel.applyProfile(profile) },
                    onUpdate: { viewModel.updateProfile(profile) },
                    onDelete: { viewModel.deleteProfile(profile) }
                )
            }
        }
        .padding(.bottom, 8)
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            if viewModel.showingSaveSheet {
                // Inline save form
                VStack(alignment: .leading, spacing: 8) {
                    Text("Save Current Arrangement")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Profile name", text: $viewModel.newProfileName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            viewModel.saveFromSheet()
                        }

                    HStack {
                        Button("Cancel") {
                            viewModel.showingSaveSheet = false
                            viewModel.newProfileName = ""
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Button("Save") {
                            viewModel.saveFromSheet()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            } else {
                Button(action: { viewModel.openSaveSheet() }) {
                    Label("Save Current Arrangement...", systemImage: "plus.circle")
                }
                .buttonStyle(MenuButtonStyle())
                .disabled(!viewModel.canSaveProfile)
            }

            Toggle(isOn: $viewModel.isAutoApplyEnabled) {
                Label("Auto-Apply on Connect", systemImage: "arrow.triangle.2.circlepath")
            }
            .toggleStyle(MenuToggleStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Button(action: { viewModel.refresh() }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(MenuButtonStyle())
        }
        .padding(.vertical, 4)
    }

    private var footerSection: some View {
        HStack {
            Button(action: { openSystemDisplaySettings() }) {
                Label("Display Settings...", systemImage: "gear")
            }
            .buttonStyle(MenuButtonStyle())

            Spacer()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Text("Quit")
            }
            .buttonStyle(MenuButtonStyle())
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helper Methods

    private func openSystemDisplaySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.displays") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Display Row

struct DisplayRow: View {
    let display: Display

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                .foregroundColor(display.isMain ? .accentColor : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(display.displayName)
                    .font(.system(.body, design: .default))

                HStack(spacing: 8) {
                    Text(display.positionDescription)
                    Text("\(display.position.width)×\(display.position.height)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            if display.isMain {
                Text("Main")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let profile: DisplayProfile
    let isMatching: Bool
    let onApply: () -> Void
    let onUpdate: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "rectangle.3.group")
                .foregroundColor(isMatching ? .accentColor : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.system(.body, design: .default))

                Text("\(profile.displayCount) displays")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isHovering {
                HStack(spacing: 4) {
                    Button(action: onApply) {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.borderless)
                    .help("Apply this profile")

                    if isMatching {
                        Button(action: onUpdate) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.borderless)
                        .help("Update with current arrangement")
                    }

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Delete this profile")
                }
            } else if isMatching {
                Text("Active")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(isHovering ? Color.primary.opacity(0.05) : Color.clear)
        .cornerRadius(4)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Custom Styles

struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(configuration.isPressed ? Color.primary.opacity(0.1) : Color.clear)
            .cornerRadius(4)
    }
}

struct MenuToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack {
                configuration.label
                Spacer()
                Image(systemName: configuration.isOn ? "checkmark" : "")
                    .frame(width: 16)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MenuBarView()
        .frame(width: 280, height: 400)
}
