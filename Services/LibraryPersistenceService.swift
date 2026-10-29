import Foundation

struct LibraryLoadResult {
    let document: LibraryDocument
    let warning: String?
}

/// Owns the on-disk document and one-time import of the original UserDefaults library.
/// It intentionally never deletes the legacy value.
struct LibraryPersistenceService {
    private let fileManager: FileManager
    private let legacyStorageKey = "book-tracker-library-v1"

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func load() -> LibraryLoadResult {
        let url = documentURL
        if fileManager.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                var document = try documentDecoder.decode(LibraryDocument.self, from: data)
                document.schemaVersion = LibraryDocument.currentSchemaVersion
                return LibraryLoadResult(document: document, warning: nil)
            } catch {
                let legacyResult = loadLegacyLibrary()
                if !legacyResult.document.books.isEmpty {
                    return LibraryLoadResult(document: legacyResult.document, warning: "The current library file could not be read. Your previous library was recovered from its legacy copy.")
                }
                return LibraryLoadResult(document: .empty, warning: "Your existing library file could not be read. It has not been deleted.")
            }
        }
        return loadLegacyLibrary()
    }

    func save(_ document: LibraryDocument) throws {
        let url = documentURL
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(document).write(to: url, options: .atomic)
    }

    private func loadLegacyLibrary() -> LibraryLoadResult {
        guard let data = UserDefaults.standard.data(forKey: legacyStorageKey) else {
            return LibraryLoadResult(document: .empty, warning: nil)
        }
        do {
            // The v1 store used JSONEncoder's default numeric Date encoding.
            let books = try JSONDecoder().decode([LibraryBook].self, from: data)
            var document = LibraryDocument.empty
            document.books = books
            document.statusHistory = books.map { StatusHistoryEntry(bookID: $0.id, status: $0.status, changedAt: $0.dateAdded) }
            document.lastModifiedAt = Date()
            return LibraryLoadResult(document: document, warning: "Your existing library was safely migrated to the new local format.")
        } catch {
            return LibraryLoadResult(document: .empty, warning: "The previous library data could not be read. It has not been deleted.")
        }
    }

    private var documentURL: URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("BookTracker", isDirectory: true).appendingPathComponent("library-document-v2.json", isDirectory: false)
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private var documentDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
