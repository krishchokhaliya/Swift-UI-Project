import Foundation

struct AIReadingResponse: Identifiable { let id = UUID(); let text: String; let isVerifiedMetadata: Bool }
protocol AIReadingService { func answer(_ prompt: String, library: LibraryDocument) async throws -> AIReadingResponse }
enum AIServiceError: LocalizedError { case unavailable; var errorDescription: String? { "AI is not configured. Connect a secure server-side provider to enable live answers." } }
/// Local, deterministic fallback. It never claims to be a live AI provider.
struct LocalReadingAssistant: AIReadingService {
    func answer(_ prompt: String, library: LibraryDocument) async throws -> AIReadingResponse {
        let titles = library.books.prefix(3).map(\.title).joined(separator: ", ")
        let text = titles.isEmpty ? "Local assistant: add and rate books to receive library-based suggestions. Live AI is not configured." : "Local assistant: based on your saved library, consider continuing with: \(titles). This is a local rule-based suggestion, not verified external information."
        return AIReadingResponse(text: text, isVerifiedMetadata: false)
    }
}
