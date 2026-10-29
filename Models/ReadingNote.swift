import Foundation

enum ReadingNoteKind: String, Codable, CaseIterable, Identifiable {
    case note
    case quote
    var id: String { rawValue }
}

struct ReadingNote: Codable, Identifiable, Equatable {
    let id: UUID
    let bookID: String
    var content: String
    var pageNumber: Int?
    let kind: ReadingNoteKind
    let createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), bookID: String, content: String, pageNumber: Int? = nil, kind: ReadingNoteKind = .note, createdAt: Date = Date(), modifiedAt: Date = Date()) {
        self.id = id
        self.bookID = bookID
        self.content = content
        self.pageNumber = pageNumber
        self.kind = kind
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
