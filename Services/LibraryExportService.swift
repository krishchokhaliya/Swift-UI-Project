import Foundation
struct LibraryExportService {
    func export(_ document: LibraryDocument) throws -> URL {
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BookTracker-Export-\(UUID().uuidString).json")
        try encoder.encode(document).write(to: url, options: .atomic)
        return url
    }
}
