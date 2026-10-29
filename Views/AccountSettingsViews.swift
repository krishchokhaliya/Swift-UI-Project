import SwiftUI
import FirebaseAuth

struct EditProfileView: View {
    @EnvironmentObject private var authentication: AuthenticationStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var currentPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoad = false

    private var isChangingEmail: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(authentication.user?.email ?? "") != .orderedSame
    }

    var body: some View {
        Form {
            Section("Profile information") {
                TextField("Full name", text: $name).textContentType(.name)
                TextField("Email address", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            if isChangingEmail {
                Section("Confirm it’s you") {
                    SecureField("Current password", text: $currentPassword)
                        .textContentType(.password)
                    Text("We’ll send a verification link to the new email address. Your sign-in email changes after you verify it.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
            if let successMessage { Section { Label(successMessage, systemImage: "checkmark.circle.fill").foregroundStyle(.green) } }
            Section {
                Button {
                    Task { await saveProfile() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving { ProgressView().padding(.trailing, 8) }
                        Text(isChangingEmail ? "Save and verify email" : "Save changes")
                        Spacer()
                    }
                }
                .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !email.contains("@"))
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoad else { return }
            name = authentication.user?.displayName ?? ""
            email = authentication.user?.email ?? ""
            didLoad = true
        }
    }

    @MainActor
    private func saveProfile() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }
        do {
            let verificationSent = try await authentication.updateProfile(name: name, newEmail: email, currentPassword: currentPassword)
            if verificationSent {
                successMessage = "Profile saved. Check the new email inbox and verify the address to complete the change."
                currentPassword = ""
            } else {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject private var authentication: AuthenticationStore
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmation = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var resetMessage: String?

    var body: some View {
        Form {
            Section("Update password") {
                SecureField("Current password", text: $currentPassword).textContentType(.password)
                SecureField("New password", text: $newPassword).textContentType(.newPassword)
                SecureField("Confirm new password", text: $confirmation).textContentType(.newPassword)
                Text("Use at least 6 characters.").font(.footnote).foregroundStyle(.secondary)
            }
            if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
            if let successMessage { Section { Label(successMessage, systemImage: "checkmark.circle.fill").foregroundStyle(.green) } }
            if let resetMessage { Section { Text(resetMessage).foregroundStyle(.secondary) } }
            Section {
                Button {
                    Task { await savePassword() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving { ProgressView().padding(.trailing, 8) }
                        Text("Update password")
                        Spacer()
                    }
                }
                .disabled(isSaving || currentPassword.isEmpty || newPassword.isEmpty || confirmation.isEmpty)
                Button("Forgot current password? Send a reset email") {
                    Task { await sendResetEmail() }
                }
                .font(.footnote)
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func savePassword() async {
        errorMessage = nil
        successMessage = nil
        resetMessage = nil
        guard newPassword.count >= 6 else { errorMessage = "Choose a password with at least 6 characters."; return }
        guard newPassword == confirmation else { errorMessage = "The new passwords do not match."; return }
        guard newPassword != currentPassword else { errorMessage = "Choose a password different from your current one."; return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await authentication.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            currentPassword = ""
            newPassword = ""
            confirmation = ""
            successMessage = "Your password has been updated."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func sendResetEmail() async {
        errorMessage = nil
        guard let email = authentication.user?.email else { errorMessage = "This account has no email address for password reset."; return }
        do {
            try await authentication.sendPasswordReset(to: email)
            resetMessage = "Password reset email sent to \(email)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var library: LibraryStore
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? .now
    @State private var message: String?

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: themeBinding) {
                    Text("System").tag(AppTheme.system)
                    Text("Light").tag(AppTheme.light)
                    Text("Dark").tag(AppTheme.dark)
                }
            }
            Section("Reading") {
                Toggle("Mark books as read when complete", isOn: markReadBinding)
            }
            Section("Daily reminder") {
                Toggle("Reading reminder", isOn: reminderBinding)
                if library.document.preferences.remindersEnabled {
                    DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { _, newValue in Task { await saveReminderTime(newValue) } }
                }
                if let message { Text(message).font(.footnote).foregroundStyle(.red) }
            }
            Section("Your data") {
                DataManagementView()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadReminderTime() }
    }

    private var themeBinding: Binding<AppTheme> {
        Binding(get: { library.document.preferences.preferredTheme }, set: { value in
            var preferences = library.document.preferences
            preferences.preferredTheme = value
            library.replacePreferences(preferences)
        })
    }

    private var markReadBinding: Binding<Bool> {
        Binding(get: { library.document.preferences.markReadOnCompletion }, set: { value in
            var preferences = library.document.preferences
            preferences.markReadOnCompletion = value
            library.replacePreferences(preferences)
        })
    }

    private var reminderBinding: Binding<Bool> {
        Binding(get: { library.document.preferences.remindersEnabled }, set: { value in Task { await setRemindersEnabled(value) } })
    }

    private func loadReminderTime() {
        var components = DateComponents()
        components.hour = library.document.preferences.reminderHour ?? 20
        components.minute = library.document.preferences.reminderMinute ?? 0
        reminderTime = Calendar.current.date(from: components) ?? .now
    }

    @MainActor
    private func setRemindersEnabled(_ enabled: Bool) async {
        message = nil
        var preferences = library.document.preferences
        if enabled {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            do {
                try await ReadingReminderService().schedule(hour: parts.hour ?? 20, minute: parts.minute ?? 0)
                preferences.reminderHour = parts.hour ?? 20
                preferences.reminderMinute = parts.minute ?? 0
                preferences.remindersEnabled = true
            } catch { message = error.localizedDescription; return }
        } else {
            ReadingReminderService().cancel()
            preferences.remindersEnabled = false
        }
        library.replacePreferences(preferences)
    }

    @MainActor
    private func saveReminderTime(_ time: Date) async {
        guard library.document.preferences.remindersEnabled else { return }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        do {
            try await ReadingReminderService().schedule(hour: parts.hour ?? 20, minute: parts.minute ?? 0)
            var preferences = library.document.preferences
            preferences.reminderHour = parts.hour ?? 20
            preferences.reminderMinute = parts.minute ?? 0
            library.replacePreferences(preferences)
            message = nil
        } catch { message = error.localizedDescription }
    }
}

struct HelpSupportView: View {
    private let helpItems: [(String, String)] = [
        ("How do I add a book?", "Open Discover, search by title, author, or ISBN, then open the result and choose a reading status."),
        ("Where are my books saved?", "Your reading library is linked to your signed-in Firebase account and is kept separate by account."),
        ("How do I record reading progress?", "Open a book from My Books or Home, then use its reading tools to update pages, add a note, or log a reading session."),
        ("How do I change my password?", "Go to Profile → Change Password. You can also request a password reset email from that screen."),
        ("Why did a reminder not appear?", "Allow notifications for Chapter & Co. in iOS Settings, then enable Reading reminder in your Profile or Settings.")
    ]

    var body: some View {
        List {
            Section {
                Text("Quick answers for your reading tracker.").foregroundStyle(.secondary)
            }
            Section("Frequently asked questions") {
                ForEach(Array(helpItems.enumerated()), id: \.offset) { _, item in
                    DisclosureGroup(item.0) { Text(item.1).font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 4) }
                }
            }
            Section("Still need help?") {
                Text("Check that you’re signed in and have an internet connection. If an issue persists, include the screen name and the message shown so it can be diagnosed.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutBookTrackerView: View {
    private var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
    private var build: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1" }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical.fill").font(.system(size: 54)).foregroundStyle(.indigo)
                    Text("Chapter & Co.").font(.title2.bold())
                    Text("A thoughtful home for your reading life.").font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .listRowBackground(Color.clear)
            }
            Section("About") {
                LabeledContent("Version", value: "\(version) (\(build))")
                LabeledContent("Features", value: "Books, goals, notes, and reading history")
                LabeledContent("Account data", value: "Synced to your Firebase account")
            }
            Section {
                Text("Book information is provided by Google Books. Your personal library and reading activity are stored separately for each signed-in account.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About Book Tracker")
        .navigationBarTitleDisplayMode(.inline)
    }
}
