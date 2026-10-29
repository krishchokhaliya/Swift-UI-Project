import SwiftUI
import FirebaseAuth
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var authentication: AuthenticationStore
    @State private var notificationMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    profileHeader
                    readingSummary

                    ProfileSection(title: "Account") {
                        NavigationLink { EditProfileView() } label: {
                            ProfileRow(icon: "person.fill", title: "Edit Profile", color: .blue)
                        }
                        Divider()
                        NavigationLink { ChangePasswordView() } label: {
                            ProfileRow(icon: "lock.fill", title: "Change Password", color: .orange)
                        }

                    }

                    ProfileSection(title: "Preferences") {
                        Picker("Appearance", selection: themeBinding) {
                            Text("System").tag(AppTheme.system)
                            Text("Light").tag(AppTheme.light)
                            Text("Dark").tag(AppTheme.dark)
                        }
                        .tint(.indigo)
                        Divider()
                        NavigationLink { SettingsView() } label: {
                            ProfileRow(icon: "gearshape.fill", title: "Settings", color: .gray)
                        }
                    }

                    ProfileSection(title: "Support") {
                        NavigationLink { HelpSupportView() } label: {
                            ProfileRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .green)
                        }
                        Divider()
                        NavigationLink { AboutBookTrackerView() } label: {
                            ProfileRow(icon: "info.circle.fill", title: "About Book Tracker", color: .blue)
                        }
                    }



                    Button {
                        authentication.signOut()
                        library.clearActiveUser()
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                            .fontWeight(.semibold).foregroundStyle(.red)
                            .frame(maxWidth: .infinity).padding()
                            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 15))
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task { await authentication.refreshUser() }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 78)).foregroundStyle(.indigo)
            Text((authentication.user?.displayName?.isEmpty == false ? authentication.user?.displayName : nil) ?? "Reader")
                .font(.title2.bold())
            Text(authentication.user?.email ?? "Your private reading space")
                .font(.subheadline).foregroundStyle(.secondary)
            if let created = authentication.user?.metadata.creationDate {
                Text("Reading since \(created.formatted(.dateTime.year()))")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
    }

    private var readingSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Statistics").font(.headline)
            HStack(spacing: 12) {
                ProfileMetric(title: "Books", value: library.totalBooks, color: .indigo)
                ProfileMetric(title: "Finished", value: library.booksRead, color: .green)
                ProfileMetric(title: "Reading", value: library.currentlyReading, color: .orange)
            }
            if let target = library.document.goals.annualBooksTarget {
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("\(Calendar.current.component(.year, from: .now)) Reading Goal").font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(library.booksRead) / \(target)").font(.subheadline.weight(.semibold)).foregroundStyle(.indigo)
                    }
                    ProgressView(value: min(Double(library.booksRead), Double(target)), total: Double(target)).tint(.indigo)
                    Text("\(max(0, target - library.booksRead)) more to reach your goal")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(15).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var themeBinding: Binding<AppTheme> {
        Binding(get: { library.document.preferences.preferredTheme }, set: { value in
            var preferences = library.document.preferences
            preferences.preferredTheme = value
            library.replacePreferences(preferences)
        })
    }

    private var reminderBinding: Binding<Bool> {
        Binding(get: { library.document.preferences.remindersEnabled }, set: { enabled in
            Task { await setRemindersEnabled(enabled) }
        })
    }

    @MainActor
    private func setRemindersEnabled(_ enabled: Bool) async {
        notificationMessage = nil
        var preferences = library.document.preferences
        if enabled {
            let hour = preferences.reminderHour ?? 20
            let minute = preferences.reminderMinute ?? 0
            do {
                try await ReadingReminderService().schedule(hour: hour, minute: minute)
                preferences.remindersEnabled = true
                preferences.reminderHour = hour
                preferences.reminderMinute = minute
            } catch {
                notificationMessage = error.localizedDescription
                return
            }
        } else {
            ReadingReminderService().cancel()
            preferences.remindersEnabled = false
        }
        library.replacePreferences(preferences)
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            VStack(spacing: 0) { content }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let color: Color
    var showsChevron = true

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundStyle(.white).frame(width: 35, height: 35)
                .background(color, in: RoundedRectangle(cornerRadius: 9))
            Text(title).font(.body).foregroundStyle(.primary)
            Spacer()
            if showsChevron { Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary) }
        }
        .contentShape(Rectangle()).padding(.vertical, 3)
    }
}

private struct ProfileMetric: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)").font(.title3.bold()).foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
