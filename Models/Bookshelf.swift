import Foundation

struct Bookshelf: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    let createdAt: Date
    /// Only stable library-book IDs are stored here; books are never copied.
    var bookIDs: [String]

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), bookIDs: [String] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.bookIDs = Array(Set(bookIDs)).sorted()
    }
}
