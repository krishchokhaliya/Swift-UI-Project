import Foundation

struct GoogleBooksResponse: Decodable { let items: [GoogleBook]? }

struct GoogleBook: Decodable, Identifiable {
    let id: String
    let volumeInfo: VolumeInfo
    let accessInfo: AccessInfo?
}

struct VolumeInfo: Decodable {
    let title: String
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let publishedDate: String?
    let categories: [String]?
    let imageLinks: ImageLinks?
}

struct ImageLinks: Decodable { let thumbnail: String? }

struct AccessInfo: Decodable {
    let webReaderLink: String?
    let previewLink: String?
    let viewability: String?
}

enum ReadingStatus: String, Codable, CaseIterable, Identifiable {
    case wantToRead = "Want to Read"
    case currentlyReading = "Currently Reading"
    case read = "Read"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .wantToRead: "bookmark.fill"
        case .currentlyReading: "book.fill"
        case .read: "checkmark.circle.fill"
        }
    }
}

/// A locally saved Google Books volume and the user's personal reading data.
/// Defaults in its custom decoder preserve the original v1 UserDefaults payload.
struct LibraryBook: Codable, Identifiable, Equatable {
    let id: String
    var title: String
    var authors: [String]
    var summary: String
    var coverURL: String?
    var previewURL: String?
    var pageCount: Int?
    var categories: [String]
    var publishedDate: String?
    var status: ReadingStatus
    var isWishlisted: Bool
    /// Retains legacy percentage progress for books with no reliable page count.
    var progress: Double
    var currentPage: Int
    var dateAdded: Date
    var dateCompleted: Date?
    var lastReadAt: Date?
    var rating: Int?
    var review: String?

    init(book: GoogleBook, status: ReadingStatus = .wantToRead) {
        id = book.id
        title = book.volumeInfo.title
        authors = book.volumeInfo.authors ?? ["Unknown author"]
        summary = book.volumeInfo.description ?? "No description is available for this book."
        coverURL = book.volumeInfo.imageLinks?.thumbnail?.secureURLString
        previewURL = book.accessInfo?.webReaderLink ?? book.accessInfo?.previewLink
        pageCount = book.volumeInfo.pageCount
        categories = book.volumeInfo.categories ?? []
        publishedDate = book.volumeInfo.publishedDate
        self.status = status
        isWishlisted = false
        progress = status == .read ? 1 : 0
        currentPage = status == .read ? (book.volumeInfo.pageCount ?? 0) : 0
        dateAdded = Date()
        dateCompleted = status == .read ? Date() : nil
        lastReadAt = nil
        rating = nil
        review = nil
    }

    var progressFraction: Double {
        guard let pageCount, pageCount > 0 else { return progress.clamped(to: 0...1) }
        return Double(currentPage.clamped(to: 0...pageCount)) / Double(pageCount)
    }

    var progressPercentage: Int { Int((progressFraction * 100).rounded()) }

    mutating func refreshMetadata(from book: GoogleBook) {
        title = book.volumeInfo.title
        authors = book.volumeInfo.authors ?? authors
        summary = book.volumeInfo.description ?? summary
        coverURL = book.volumeInfo.imageLinks?.thumbnail?.secureURLString ?? coverURL
        previewURL = book.accessInfo?.webReaderLink ?? book.accessInfo?.previewLink ?? previewURL
        pageCount = book.volumeInfo.pageCount ?? pageCount
        categories = book.volumeInfo.categories ?? categories
        publishedDate = book.volumeInfo.publishedDate ?? publishedDate
        if let pageCount { currentPage = currentPage.clamped(to: 0...pageCount) }
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, authors, summary, coverURL, previewURL, pageCount, categories
        case publishedDate, status, isWishlisted, progress, currentPage, dateAdded
        case dateCompleted, lastReadAt, rating, review
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        authors = try values.decodeIfPresent([String].self, forKey: .authors) ?? ["Unknown author"]
        summary = try values.decodeIfPresent(String.self, forKey: .summary) ?? "No description is available for this book."
        coverURL = try values.decodeIfPresent(String.self, forKey: .coverURL)
        previewURL = try values.decodeIfPresent(String.self, forKey: .previewURL)
        pageCount = try values.decodeIfPresent(Int.self, forKey: .pageCount)
        categories = try values.decodeIfPresent([String].self, forKey: .categories) ?? []
        publishedDate = try values.decodeIfPresent(String.self, forKey: .publishedDate)
        status = try values.decodeIfPresent(ReadingStatus.self, forKey: .status) ?? .wantToRead
        isWishlisted = try values.decodeIfPresent(Bool.self, forKey: .isWishlisted) ?? false
        progress = (try values.decodeIfPresent(Double.self, forKey: .progress) ?? 0).clamped(to: 0...1)
        dateAdded = try values.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()
        dateCompleted = try values.decodeIfPresent(Date.self, forKey: .dateCompleted)
        lastReadAt = try values.decodeIfPresent(Date.self, forKey: .lastReadAt)
        rating = try values.decodeIfPresent(Int.self, forKey: .rating)?.clamped(to: 1...5)
        review = try values.decodeIfPresent(String.self, forKey: .review)
        let migratedPage = Int((progress * Double(pageCount ?? 0)).rounded())
        currentPage = try values.decodeIfPresent(Int.self, forKey: .currentPage)
            ?? (status == .read ? (pageCount ?? 0) : migratedPage)
        if let pageCount { currentPage = currentPage.clamped(to: 0...pageCount) }
    }
}

extension String {
    var secureURLString: String { replacingOccurrences(of: "http://", with: "https://") }
}

extension Comparable {
    fileprivate func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
