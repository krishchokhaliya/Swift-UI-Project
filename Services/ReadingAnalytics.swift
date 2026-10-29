import Foundation

struct DailyReadingActivity: Identifiable {
    let date: Date
    let pages: Int
    let duration: TimeInterval
    let completedBooks: Int
    var id: Date { date }
    var hasActivity: Bool { pages > 0 || duration > 0 || completedBooks > 0 }
}

struct ReadingAnalytics {
    let document: LibraryDocument
    private let calendar = Calendar.current

    func activity(for date: Date) -> DailyReadingActivity {
        let start = calendar.startOfDay(for: date)
        let sessions = document.readingSessions.filter { calendar.isDate($0.startedAt, inSameDayAs: start) }
        let completed = document.books.filter { $0.dateCompleted.map { calendar.isDate($0, inSameDayAs: start) } ?? false }.count
        return DailyReadingActivity(date: start, pages: sessions.compactMap(\.pagesRead).reduce(0, +), duration: sessions.reduce(0) { $0 + $1.duration }, completedBooks: completed)
    }

    var recentActivity: [DailyReadingActivity] { (0..<28).reversed().map { activity(for: calendar.date(byAdding: .day, value: -$0, to: Date())!) } }
    var currentStreak: Int { streak(ending: Date()) }
    var longestStreak: Int { recentActivity.reduce((0, 0)) { state, item in item.hasActivity ? (state.0 + 1, max(state.1, state.0 + 1)) : (0, state.1) }.1 }
    var totalDuration: TimeInterval { document.readingSessions.reduce(0) { $0 + $1.duration } }
    var totalPages: Int { document.readingSessions.compactMap(\.pagesRead).reduce(0, +) }

    func estimatedCompletion(for book: LibraryBook) -> Date? {
        guard let total = book.pageCount, total > book.currentPage else { return nil }
        let activity = recentActivity.suffix(14)
        let pages = activity.reduce(0) { $0 + $1.pages }
        guard pages > 0 else { return nil }
        let activeDays = max(1, activity.filter(\.hasActivity).count)
        let dailyPace = Double(pages) / Double(activeDays)
        return calendar.date(byAdding: .day, value: Int(ceil(Double(total - book.currentPage) / dailyPace)), to: Date())
    }

    private func streak(ending date: Date) -> Int {
        var value = 0; var cursor = date
        while activity(for: cursor).hasActivity { value += 1; cursor = calendar.date(byAdding: .day, value: -1, to: cursor)! }
        return value
    }
}
