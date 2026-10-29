import SwiftUI

struct DataManagementView: View {
    @EnvironmentObject private var library: LibraryStore
    @State private var exportURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                do {
                    exportURL = try LibraryExportService().export(library.document)
                    errorMessage = nil
                } catch {
                    errorMessage = "Could not prepare the export: \(error.localizedDescription)"
                }
            } label: {
                Label("Prepare library export", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            if let exportURL {
                ShareLink(item: exportURL) { Label("Share JSON export", systemImage: "doc.text") }
            }
            if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(.red) }
            Text("The export contains your books, reading sessions, notes, shelves, goals, and preferences.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
