import Foundation

struct StatusHistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let bookID: String
    let status: ReadingStatus
    let changedAt: Date

    init(id: UUID = UUID(), bookID: String, status: ReadingStatus, changedAt: Date = Date()) {
        self.id = id
        self.bookID = bookID
        self.status = status
        self.changedAt = changedAt
    }
}

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
}

struct AppPreferences: Codable, Equatable {
    var preferredTheme: AppTheme
    var remindersEnabled: Bool
    var reminderHour: Int?
    var reminderMinute: Int?
    var markReadOnCompletion: Bool

    static let `default` = AppPreferences()

    init(preferredTheme: AppTheme = .system, remindersEnabled: Bool = false, reminderHour: Int? = nil, reminderMinute: Int? = nil, markReadOnCompletion: Bool = true) {
        self.preferredTheme = preferredTheme
        self.remindersEnabled = remindersEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.markReadOnCompletion = markReadOnCompletion
    }
}

struct LibraryDocument: Codable, Equatable {
    static let currentSchemaVersion = 2

    var schemaVersion: Int
    var books: [LibraryBook]
    var readingSessions: [ReadingSession]
    var notes: [ReadingNote]
    var shelves: [Bookshelf]
    var goals: ReadingGoals
    var statusHistory: [StatusHistoryEntry]
    var preferences: AppPreferences
    var lastModifiedAt: Date

    static let empty = LibraryDocument(
        schemaVersion: currentSchemaVersion,
        books: [],
        readingSessions: [],
        notes: [],
        shelves: [],
        goals: .empty,
        statusHistory: [],
        preferences: .default,
        lastModifiedAt: Date()
    )
}
