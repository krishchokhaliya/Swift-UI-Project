import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthenticationStore: ObservableObject {
    @Published private(set) var user: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    private var listener: AuthStateDidChangeListenerHandle?

    init() {
        user = Auth.auth().currentUser
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.user = user }
        }
    }

    deinit { if let listener { Auth.auth().removeStateDidChangeListener(listener) } }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = FirebaseErrorDiagnostics.message(for: error, stage: "sign in")
        }
    }

    func register(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let newUser: User
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            newUser = result.user
        } catch {
            errorMessage = FirebaseErrorDiagnostics.message(for: error, stage: "create Firebase Authentication account")
            return
        }

        // Account creation is complete at this point. Profile metadata and the
        // Firestore profile are follow-up steps; their failure must not pretend
        // the account itself failed to register.
        do {
            let change = newUser.createProfileChangeRequest()
            change.displayName = cleanName
            try await change.commitChanges()
        } catch {
            print(FirebaseErrorDiagnostics.details(for: error, stage: "update Firebase Auth display name"))
        }

        do {
            try await Firestore.firestore().collection("users").document(newUser.uid).setData([
                "uid": newUser.uid,
                "email": newUser.email ?? email,
                "displayName": cleanName,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)
        } catch {
            errorMessage = "Your account was created, but its profile could not be saved. Check the Xcode console and Firebase Firestore setup."
            print(FirebaseErrorDiagnostics.details(for: error, stage: "save new user profile in Cloud Firestore"))
        }
    }

    func updateProfile(name: String, newEmail: String, currentPassword: String) async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else { throw AuthenticationActionError.signedOut }
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { throw AuthenticationActionError.invalidName }

        let emailChanged = cleanEmail.caseInsensitiveCompare(currentUser.email ?? "") != .orderedSame
        if emailChanged {
            guard let currentEmail = currentUser.email, !currentPassword.isEmpty else {
                throw AuthenticationActionError.passwordRequired
            }
            let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: currentPassword)
            _ = try await currentUser.reauthenticate(with: credential)
            try await currentUser.sendEmailVerification(beforeUpdatingEmail: cleanEmail)
        }

        let change = currentUser.createProfileChangeRequest()
        change.displayName = cleanName
        try await change.commitChanges()
        try await Firestore.firestore().collection("users").document(currentUser.uid).setData([
            "uid": currentUser.uid,
            "email": currentUser.email ?? "",
            "displayName": cleanName,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
        try await currentUser.reload()
        user = Auth.auth().currentUser
        return emailChanged
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let currentUser = Auth.auth().currentUser, let email = currentUser.email else {
            throw AuthenticationActionError.signedOut
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        _ = try await currentUser.reauthenticate(with: credential)
        try await currentUser.updatePassword(to: newPassword)
        user = Auth.auth().currentUser
    }

    func sendPasswordReset(to email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func refreshUser() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        do {
            try await currentUser.reload()
            user = Auth.auth().currentUser
            if let user {
                try await Firestore.firestore().collection("users").document(user.uid).setData([
                    "uid": user.uid,
                    "email": user.email ?? "",
                    "displayName": user.displayName ?? "",
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)
            }
        } catch {
            errorMessage = FirebaseErrorDiagnostics.message(for: error, stage: "refresh account profile")
        }
    }

    func signOut() {
        do { try Auth.auth().signOut(); errorMessage = nil }
        catch { errorMessage = FirebaseErrorDiagnostics.message(for: error, stage: "sign out") }
    }
}

private enum FirebaseErrorDiagnostics {
    static func message(for error: Error, stage: String) -> String {
        details(for: error, stage: stage)
    }

    static func details(for error: Error, stage: String) -> String {
        var visited = Set<ObjectIdentifier>()
        let errorDetails = describe(error as NSError, label: "Firebase error", visited: &visited, depth: 0)
        return "[Firebase] Failure during: \(stage)\n\(errorDetails)"
    }

    private static func describe(_ error: NSError, label: String, visited: inout Set<ObjectIdentifier>, depth: Int) -> String {
        guard depth < 8 else { return "\(label): nested error depth limit reached" }
        let identity = ObjectIdentifier(error)
        guard visited.insert(identity).inserted else { return "\(label): circular error reference omitted" }

        var lines = [
            "\(label): \(error.domain) (\(error.code))",
            "Description: \(error.localizedDescription)"
        ]
        if let reason = error.localizedFailureReason { lines.append("Failure reason: \(reason)") }
        if let recovery = error.localizedRecoverySuggestion { lines.append("Recovery suggestion: \(recovery)") }

        for (key, value) in error.userInfo {
            let normalizedKey = key.lowercased()
            guard !["email", "password", "token", "credential", "authorization"].contains(where: normalizedKey.contains),
                  key != NSLocalizedDescriptionKey,
                  key != NSLocalizedFailureReasonErrorKey,
                  key != NSLocalizedRecoverySuggestionErrorKey,
                  key != NSUnderlyingErrorKey else { continue }
            lines.append("\(key): \(safeDescription(value, key: key, visited: &visited, depth: depth + 1))")
        }

        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            lines.append(describe(underlying, label: "Underlying error", visited: &visited, depth: depth + 1))
        }
        return lines.joined(separator: "\n")
    }

    private static func safeDescription(_ value: Any, key: String, visited: inout Set<ObjectIdentifier>, depth: Int) -> String {
        guard depth < 8 else { return "<nested value omitted>" }
        let normalizedKey = key.lowercased()
        if ["email", "password", "token", "credential", "authorization"].contains(where: normalizedKey.contains) {
            return "<redacted>"
        }
        if let nestedError = value as? NSError {
            return describe(nestedError, label: "Nested error", visited: &visited, depth: depth + 1)
        }
        if let dictionary = value as? [String: Any] {
            return "{" + dictionary.map { itemKey, itemValue in
                "\(itemKey): \(safeDescription(itemValue, key: itemKey, visited: &visited, depth: depth + 1))"
            }.joined(separator: ", ") + "}"
        }
        if let array = value as? [Any] {
            return "[" + array.map { safeDescription($0, key: key, visited: &visited, depth: depth + 1) }.joined(separator: ", ") + "]"
        }
        return String(describing: value)
    }
}

struct CloudLibraryService {
    private let db = Firestore.firestore()
    func load(uid: String) async throws -> LibraryDocument? {
        let snapshot = try await db.collection("users").document(uid).collection("private").document("library").getDocument()
        guard let data = snapshot.data()?["payload"] as? Data else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(LibraryDocument.self, from: data)
    }
    func save(_ document: LibraryDocument, uid: String) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let payload = try encoder.encode(document)
        try await db.collection("users").document(uid).collection("private").document("library").setData([
            "payload": payload,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
}

private enum AuthenticationActionError: LocalizedError {
    case signedOut
    case invalidName
    case passwordRequired

    var errorDescription: String? {
        switch self {
        case .signedOut: "You are signed out. Sign in again and retry."
        case .invalidName: "Enter a name before saving your profile."
        case .passwordRequired: "Enter your current password to request an email change."
        }
    }
}
