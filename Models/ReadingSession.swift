import Foundation

struct ReadingSession: Codable, Identifiable, Equatable {
    let id: UUID
    let bookID: String
    let startedAt: Date
    let duration: TimeInterval
    let startingPage: Int?
    let endingPage: Int?
    let note: String?

    init(id: UUID = UUID(), bookID: String, startedAt: Date = Date(), duration: TimeInterval, startingPage: Int? = nil, endingPage: Int? = nil, note: String? = nil) {
        self.id = id
        self.bookID = bookID
        self.startedAt = startedAt
        self.duration = max(0, duration)
        self.startingPage = startingPage
        self.endingPage = endingPage
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.note = trimmed?.isEmpty == false ? trimmed : nil
    }

    var pagesRead: Int? {
        guard let startingPage, let endingPage else { return nil }
        return max(0, endingPage - startingPage)
    }
}
