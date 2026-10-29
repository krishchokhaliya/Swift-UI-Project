import Foundation

enum BookAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case server(message: String)
    case noResults
    case network(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The Google Books request URL is invalid."

        case .invalidResponse:
            return "The book service returned an unexpected response."

        case .unauthorized:
            return "The Google Books API key is invalid or not authorized."

        case .rateLimited:
            return "Too many requests. Please try again later."

        case .server(let message):
            return message

        case .noResults:
            return "No books matched that search. Try another title, author, or ISBN."

        case .network(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Google Books Service

struct GoogleBooksService {

    private let baseURL =
        URL(string: "https://www.googleapis.com/books/v1/volumes")!

    // Google Books API key
    private let apiKey =
        "AIzaSyArMOFUQxaPKRpgo-CCuh4UY1GGyClFQs4"

    // MARK: - Search Books

    func searchBooks(query: String) async throws -> [GoogleBook] {

        let cleanQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanQuery.isEmpty else {
            return []
        }

        var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        )

        // If the user enters an ISBN, Google Books
        // can search it specifically.
        let googleQuery: String

        if isISBN(cleanQuery) {
            googleQuery = "isbn:\(cleanQuery)"
        } else {
            googleQuery = cleanQuery
        }

        components?.queryItems = [
            URLQueryItem(
                name: "q",
                value: googleQuery
            ),

            URLQueryItem(
                name: "maxResults",
                value: "20"
            ),

            URLQueryItem(
                name: "printType",
                value: "books"
            ),

            URLQueryItem(
                name: "key",
                value: apiKey
            )
        ]

        guard let url = components?.url else {
            throw BookAPIError.invalidURL
        }

        let response: GoogleBooksResponse =
            try await request(url)

        guard let books = response.items,
              !books.isEmpty else {
            throw BookAPIError.noResults
        }

        return books
    }

    // MARK: - Book Details

    func bookDetails(id: String) async throws -> GoogleBook {

        let encodedID = id.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) ?? id

        var components = URLComponents(
            url: baseURL.appendingPathComponent(encodedID),
            resolvingAgainstBaseURL: false
        )

        components?.queryItems = [
            URLQueryItem(
                name: "key",
                value: apiKey
            )
        ]

        guard let url = components?.url else {
            throw BookAPIError.invalidURL
        }

        return try await request(url)
    }

    // MARK: - Network Request

    private func request<T: Decodable>(
        _ url: URL
    ) async throws -> T {

        do {

            let (data, response) =
                try await URLSession.shared.data(
                    from: url
                )

            guard let httpResponse =
                    response as? HTTPURLResponse else {

                throw BookAPIError.invalidResponse
            }

            switch httpResponse.statusCode {

            case 200...299:
                break

            case 400:
                throw BookAPIError.server(
                    message: "Google Books rejected the request."
                )

            case 401, 403:
                throw BookAPIError.unauthorized

            case 429:
                throw BookAPIError.rateLimited

            case 500...599:
                throw BookAPIError.server(
                    message:
                        "Google Books server error. Please try again later."
                )

            default:
                throw BookAPIError.server(
                    message:
                        "Google Books returned status code \(httpResponse.statusCode)."
                )
            }

            do {

                return try JSONDecoder().decode(
                    T.self,
                    from: data
                )

            } catch {

                print(
                    "Google Books decoding error:",
                    error
                )

                throw BookAPIError.invalidResponse
            }

        } catch let error as BookAPIError {

            throw error

        } catch {

            throw BookAPIError.network(
                message: error.localizedDescription
            )
        }
    }

    // MARK: - ISBN Check

    private func isISBN(
        _ value: String
    ) -> Bool {

        let cleaned = value
            .replacingOccurrences(
                of: "-",
                with: ""
            )
            .replacingOccurrences(
                of: " ",
                with: ""
            )

        // ISBN-10
        if cleaned.count == 10 {
            return true
        }

        // ISBN-13
        if cleaned.count == 13 {
            return true
        }

        return false
    }
}
