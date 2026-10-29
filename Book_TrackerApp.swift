import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct Book_TrackerApp: App {
    @StateObject private var library = LibraryStore()
    @StateObject private var authentication = AuthenticationStore()
    @State private var showSplash = true

    init() { FirebaseApp.configure() }

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashScreen().transition(.opacity)
                } else if let user = authentication.user {
                    MainTabView()
                        .environmentObject(library)
                        .environmentObject(authentication)
                        .task(id: user.uid) { await library.activateUser(user.uid) }
                } else {
                    LoginView()
                        .environmentObject(authentication)
                        .environmentObject(library)
                }
            }
            .animation(.easeInOut(duration: 0.45), value: showSplash)
            .task {
                try? await Task.sleep(for: .milliseconds(1500))
                showSplash = false
            }
            .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch library.document.preferences.preferredTheme {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct AppBrand: View {
    var light = false
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(light ? .white : .indigo)
                .frame(width: 48, height: 48)
                .background(light ? .white.opacity(0.18) : .indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 15))
            Text("Chapter & Co.")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(light ? .white : .primary)
        }
    }
}

private struct SplashScreen: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "books.vertical.fill").font(.system(size: 70, weight: .medium)).foregroundStyle(.white)
                Text("Chapter & Co.").font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text("Your reading journey, beautifully kept").font(.subheadline).foregroundStyle(.white.opacity(0.85))
            }
        }
    }
}
