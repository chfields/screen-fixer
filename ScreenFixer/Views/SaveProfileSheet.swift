import SwiftUI

/// Sheet for saving a new profile with a custom name
struct SaveProfileSheet: View {
    @Binding var profileName: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Save Display Arrangement")
                    .font(.headline)
            }

            // Name field
            VStack(alignment: .leading, spacing: 4) {
                Text("Profile Name")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Enter profile name", text: $profileName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFieldFocused)
                    .onSubmit {
                        if isValidName {
                            onSave()
                        }
                    }
            }

            // Buttons
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    onSave()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidName)
            }
        }
        .padding(20)
        .frame(width: 300)
        .onAppear {
            isNameFieldFocused = true
        }
    }

    private var isValidName: Bool {
        !profileName.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

#Preview {
    SaveProfileSheet(
        profileName: .constant("Work Setup"),
        onSave: {},
        onCancel: {}
    )
}
