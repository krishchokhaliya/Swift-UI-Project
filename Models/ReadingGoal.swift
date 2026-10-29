import Foundation

struct ReadingGoals: Codable, Equatable {
    var annualBooksTarget: Int?
    var monthlyBooksTarget: Int?
    var dailyPagesTarget: Int?
    var dailyReadingDurationTarget: TimeInterval?

    static let empty = ReadingGoals()

    init(annualBooksTarget: Int? = nil, monthlyBooksTarget: Int? = nil, dailyPagesTarget: Int? = nil, dailyReadingDurationTarget: TimeInterval? = nil) {
        self.annualBooksTarget = annualBooksTarget.flatMap { $0 > 0 ? $0 : nil }
        self.monthlyBooksTarget = monthlyBooksTarget.flatMap { $0 > 0 ? $0 : nil }
        self.dailyPagesTarget = dailyPagesTarget.flatMap { $0 > 0 ? $0 : nil }
        self.dailyReadingDurationTarget = dailyReadingDurationTarget.flatMap { $0 > 0 ? $0 : nil }
    }
}
