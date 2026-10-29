import SwiftUI

struct ReadingManagementSection: View {
    @EnvironmentObject private var library: LibraryStore
    let book: LibraryBook
    @State private var pageText = ""
    @State private var rating = 0
    @State private var review = ""
    @State private var error: String?
    @State private var showSession = false
    @State private var showNote = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("My reading").font(.title3.bold())
            if let total = book.pageCount, total > 0 {
                ProgressView(value: book.progressFraction).tint(.indigo)
                HStack { Text("Page \(book.currentPage) of \(total)"); Spacer(); Text("\(book.progressPercentage)%") }.font(.caption).foregroundStyle(.secondary)
                HStack {
                    TextField("Current page", text: $pageText).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    Button("Update") { error = Int(pageText).flatMap { library.updateCurrentPage(book.id, page: $0) } ?? (Int(pageText) == nil ? "Enter a valid page number." : nil) }.buttonStyle(.borderedProminent)
                }
            } else {
                Text("No verified page count is available for this edition. Percentage progress remains available in Statistics.").font(.caption).foregroundStyle(.secondary)
            }
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
            HStack { Button("Log session") { showSession = true }.buttonStyle(.bordered); Button("Add note") { showNote = true }.buttonStyle(.bordered) }
            Divider()
            HStack(spacing: 4) { ForEach(1...5, id: \.self) { value in Button { rating = value; library.setReview(bookID: book.id, rating: value, review: review) } label: { Image(systemName: value <= rating ? "star.fill" : "star").foregroundStyle(.yellow) } }.accessibilityLabel("Rate \(rating) stars") }
            TextEditor(text: $review).frame(minHeight: 80).overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            Button("Save review") { library.setReview(bookID: book.id, rating: rating == 0 ? nil : rating, review: review) }.buttonStyle(.bordered)
            let notes = library.notes(for: book.id)
            if !notes.isEmpty { Text("Notes & quotes").font(.headline); ForEach(notes) { note in HStack(alignment: .top) { VStack(alignment: .leading) { Text(note.kind == .quote ? "Quote" : "Note").font(.caption.bold()); Text(note.content); if let page = note.pageNumber { Text("Page \(page)").font(.caption).foregroundStyle(.secondary) } }; Spacer(); Button(role: .destructive) { library.deleteNote(note) } label: { Image(systemName: "trash") } } } }
            let sessions = library.sessions(for: book.id)
            if !sessions.isEmpty { Text("Reading history").font(.headline); ForEach(sessions.prefix(5)) { session in Text("\(session.startedAt.formatted(date: .abbreviated, time: .shortened)) · \(Int(session.duration / 60)) min\(session.pagesRead.map { " · \($0) pages" } ?? "")").font(.caption) } }
        }
        .onAppear { pageText = "\(book.currentPage)"; rating = book.rating ?? 0; review = book.review ?? "" }
        .sheet(isPresented: $showSession) { SessionEditor(book: book) }
        .sheet(isPresented: $showNote) { NoteEditor(book: book) }
    }
}

private struct SessionEditor: View {
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let book: LibraryBook
    @State private var minutes = "20"; @State private var start = ""; @State private var end = ""; @State private var note = ""; @State private var error: String?
    var body: some View { NavigationStack { Form { TextField("Minutes", text: $minutes).keyboardType(.numberPad); TextField("Starting page (optional)", text: $start).keyboardType(.numberPad); TextField("Ending page (optional)", text: $end).keyboardType(.numberPad); TextField("Session note (optional)", text: $note); if let error { Text(error).foregroundStyle(.red) } }.navigationTitle("Log Reading").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { error = library.addSession(bookID: book.id, startedAt: Date(), duration: (Double(minutes) ?? 0) * 60, startingPage: Int(start), endingPage: Int(end), note: note); if error == nil { dismiss() } } }; ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } } } }
}

private struct NoteEditor: View {
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let book: LibraryBook
    @State private var content = ""; @State private var page = ""; @State private var kind: ReadingNoteKind = .note; @State private var error: String?
    var body: some View { NavigationStack { Form { Picker("Type", selection: $kind) { Text("Note").tag(ReadingNoteKind.note); Text("Quote").tag(ReadingNoteKind.quote) }; TextField("Page (optional)", text: $page).keyboardType(.numberPad); TextEditor(text: $content).frame(minHeight: 140); if let error { Text(error).foregroundStyle(.red) } }.navigationTitle("Add \(kind == .quote ? "Quote" : "Note")").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { error = library.addNote(bookID: book.id, content: content, pageNumber: Int(page), kind: kind); if error == nil { dismiss() } } }; ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } } } }
}
