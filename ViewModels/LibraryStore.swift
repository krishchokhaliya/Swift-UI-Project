import Foundation
import Combine

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var document = LibraryDocument.empty {
        didSet {
            guard !isLoading else { return }
            saveDocument()
            if let activeUserID {
                Task {
                    do { try await cloud.save(document, uid: activeUserID) }
                    catch { persistenceWarning = "Your changes are saved on this device but could not be synced to your account." }
                }
            }
        }
    }
    @Published private(set) var persistenceWarning: String?

    private let persistence: LibraryPersistenceService
    private var isLoading = true
    private var activeUserID: String?
    private let cloud = CloudLibraryService()
    @Published private(set) var isCloudLoading = false

    init(persistence: LibraryPersistenceService = LibraryPersistenceService()) {
        self.persistence = persistence
        let result = persistence.load()
        document = result.document
        persistenceWarning = result.warning
        isLoading = false
        if result.warning?.contains("safely migrated") == true { saveDocument() }
    }

    func activateUser(_ uid: String) async {
        guard activeUserID != uid else { return }
        document = .empty
        activeUserID = uid
        isCloudLoading = true
        defer { isCloudLoading = false }
        do {
            let remote = try await cloud.load(uid: uid)
            guard activeUserID == uid else { return }
            document = remote ?? .empty
        } catch {
            guard activeUserID == uid else { return }
            persistenceWarning = "Your cloud library could not be loaded. Check your connection and try again."
        }
    }

    func clearActiveUser() { activeUserID = nil; document = .empty }

    var books: [LibraryBook] { document.books }
    var totalBooks: Int { books.count }
    var booksRead: Int { books.filter { $0.status == .read }.count }
    var currentlyReading: Int { books.filter { $0.status == .currentlyReading }.count }
    var unreadBooks: Int { books.filter { $0.status == .wantToRead }.count }
    var wishlist: [LibraryBook] { books.filter(\.isWishlisted) }

    func book(withID id: String) -> LibraryBook? { books.first { $0.id == id } }

    func add(_ googleBook: GoogleBook, status: ReadingStatus = .wantToRead) {
        if let index = document.books.firstIndex(where: { $0.id == googleBook.id }) {
            let oldStatus = document.books[index].status
            document.books[index].refreshMetadata(from: googleBook)
            setStatus(at: index, to: status)
            if oldStatus == status { touchDocument() }
        } else {
            var book = LibraryBook(book: googleBook, status: status)
            if status == .read { book.dateCompleted = Date() }
            document.books.insert(book, at: 0)
            document.statusHistory.append(StatusHistoryEntry(bookID: book.id, status: status))
            touchDocument()
        }
    }

    func update(_ id: String, status: ReadingStatus) {
        guard let index = document.books.firstIndex(where: { $0.id == id }) else { return }
        setStatus(at: index, to: status)
    }

    func toggleWishlist(_ googleBook: GoogleBook) {
        if let index = document.books.firstIndex(where: { $0.id == googleBook.id }) {
            document.books[index].isWishlisted.toggle()
            touchDocument()
        } else {
            var saved = LibraryBook(book: googleBook)
            saved.isWishlisted = true
            document.books.insert(saved, at: 0)
            document.statusHistory.append(StatusHistoryEntry(bookID: saved.id, status: saved.status))
            touchDocument()
        }
    }

    /// Retained temporarily for the existing percentage slider. Phase 3 replaces
    /// its callers with validated current-page updates and session creation.
    func updateProgress(_ id: String, progress: Double) {
        guard let index = document.books.firstIndex(where: { $0.id == id }) else { return }
        let clampedProgress = min(max(progress, 0), 1)
        document.books[index].progress = clampedProgress
        if let pageCount = document.books[index].pageCount, pageCount > 0 {
            document.books[index].currentPage = Int((Double(pageCount) * clampedProgress).rounded())
        }
        if clampedProgress >= 1 { setStatus(at: index, to: .read) } else { touchDocument() }
    }

    func delete(_ book: LibraryBook) {
        document.books.removeAll { $0.id == book.id }
        document.shelves = document.shelves.map { shelf in
            var copy = shelf
            copy.bookIDs.removeAll { $0 == book.id }
            return copy
        }
        touchDocument()
    }

    func replaceGoals(_ goals: ReadingGoals) {
        document.goals = goals
        touchDocument()
    }

    func replacePreferences(_ preferences: AppPreferences) {
        document.preferences = preferences
        touchDocument()
    }

    func createShelf(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !document.shelves.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        document.shelves.append(Bookshelf(name: trimmed)); touchDocument()
    }
    func renameShelf(_ shelf: Bookshelf, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = document.shelves.firstIndex(where: { $0.id == shelf.id }) else { return }
        document.shelves[index].name = trimmed; touchDocument()
    }
    func deleteShelf(_ shelf: Bookshelf) { document.shelves.removeAll { $0.id == shelf.id }; touchDocument() }
    func toggleBook(_ bookID: String, on shelfID: UUID) {
        guard let index = document.shelves.firstIndex(where: { $0.id == shelfID }) else { return }
        if document.shelves[index].bookIDs.contains(bookID) { document.shelves[index].bookIDs.removeAll { $0 == bookID } } else { document.shelves[index].bookIDs.append(bookID) }
        touchDocument()
    }

    // MARK: - Reading management

    @discardableResult
    func updateCurrentPage(_ id: String, page: Int) -> String? {
        guard let index = document.books.firstIndex(where: { $0.id == id }) else { return "This book is no longer in your library." }
        guard let total = document.books[index].pageCount, total > 0 else { return "This book has no page count. You can still use percentage progress." }
        guard (0...total).contains(page) else { return "Enter a page from 0 to \(total)." }
        document.books[index].currentPage = page
        document.books[index].progress = Double(page) / Double(total)
        document.books[index].lastReadAt = Date()
        if page == total, document.preferences.markReadOnCompletion {
            setStatus(at: index, to: .read)
        } else if page > 0, document.books[index].status == .wantToRead {
            setStatus(at: index, to: .currentlyReading)
        } else {
            touchDocument()
        }
        return nil
    }

    @discardableResult
    func addSession(bookID: String, startedAt: Date, duration: TimeInterval, startingPage: Int?, endingPage: Int?, note: String?) -> String? {
        guard book(withID: bookID) != nil else { return "This book is no longer in your library." }
        guard duration > 0 else { return "Reading duration must be greater than zero." }
        if let startingPage, let endingPage, endingPage < startingPage { return "Ending page cannot be before the starting page." }
        let session = ReadingSession(bookID: bookID, startedAt: startedAt, duration: duration, startingPage: startingPage, endingPage: endingPage, note: note)
        let duplicate = document.readingSessions.contains {
            $0.bookID == session.bookID && abs($0.startedAt.timeIntervalSince(session.startedAt)) < 1 && $0.duration == session.duration && $0.startingPage == session.startingPage && $0.endingPage == session.endingPage && $0.note == session.note
        }
        guard !duplicate else { return "That reading session has already been recorded." }
        document.readingSessions.append(session)
        if let endingPage, let error = updateCurrentPage(bookID, page: endingPage) { return error }
        touchDocument()
        return nil
    }

    func sessions(for bookID: String) -> [ReadingSession] { document.readingSessions.filter { $0.bookID == bookID }.sorted { $0.startedAt > $1.startedAt } }
    func notes(for bookID: String) -> [ReadingNote] { document.notes.filter { $0.bookID == bookID }.sorted { $0.modifiedAt > $1.modifiedAt } }

    @discardableResult
    func addNote(bookID: String, content: String, pageNumber: Int?, kind: ReadingNoteKind) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Write a note or quote before saving." }
        document.notes.append(ReadingNote(bookID: bookID, content: trimmed, pageNumber: pageNumber, kind: kind))
        touchDocument(); return nil
    }

    func updateNote(_ note: ReadingNote, content: String, pageNumber: Int?) {
        guard let index = document.notes.firstIndex(where: { $0.id == note.id }) else { return }
        document.notes[index].content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        document.notes[index].pageNumber = pageNumber
        document.notes[index].modifiedAt = Date(); touchDocument()
    }

    func deleteNote(_ note: ReadingNote) { document.notes.removeAll { $0.id == note.id }; touchDocument() }

    func setReview(bookID: String, rating: Int?, review: String?) {
        guard let index = document.books.firstIndex(where: { $0.id == bookID }) else { return }
        document.books[index].rating = rating.flatMap { (1...5).contains($0) ? $0 : nil }
        document.books[index].review = review?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? review?.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        touchDocument()
    }

    private func setStatus(at index: Int, to status: ReadingStatus) {
        let previousStatus = document.books[index].status
        document.books[index].status = status
        if status == .read {
            document.books[index].progress = 1
            if let pageCount = document.books[index].pageCount { document.books[index].currentPage = pageCount }
            document.books[index].dateCompleted = document.books[index].dateCompleted ?? Date()
        } else if previousStatus == .read {
            document.books[index].dateCompleted = nil
        }
        if previousStatus != status {
            document.statusHistory.append(StatusHistoryEntry(bookID: document.books[index].id, status: status))
        }
        touchDocument()
    }

    private func touchDocument() { document.lastModifiedAt = Date() }

    private func saveDocument() {
        do {
            try persistence.save(document)
            persistenceWarning = nil
        } catch {
            persistenceWarning = "Your latest library change could not be saved locally. Please check available storage and try again."
        }
    }
}
