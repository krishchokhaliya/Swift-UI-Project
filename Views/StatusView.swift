import SwiftUI

struct MyBooksView: View {
    @EnvironmentObject private var library: LibraryStore
    @State private var selectedStatus: ReadingStatus
    @State private var sortBy = 0

    init(initialStatus: ReadingStatus = .wantToRead) { _selectedStatus = State(initialValue: initialStatus) }
    private var displayedBooks: [LibraryBook] { library.books.filter { $0.status == selectedStatus }.sorted { sortBy == 0 ? $0.dateAdded > $1.dateAdded : (sortBy == 1 ? $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending : ($0.rating ?? 0) > ($1.rating ?? 0)) } }

    var body: some View {
        NavigationStack {
            Group {
                if displayedBooks.isEmpty {
                    ContentUnavailableView("No \(selectedStatus.rawValue.lowercased()) books", systemImage: selectedStatus.icon, description: Text("Use Discover to add a book to your library."))
                } else {
                    List {
                        ForEach(displayedBooks) { book in
                            NavigationLink { BookDetailView(libraryBook: book) } label: { LibraryBookRow(book: book) }
                                .buttonStyle(.plain)
                        }
                            .onDelete { offsets in offsets.map { displayedBooks[$0] }.forEach(library.delete) }
                    }.listStyle(.plain)
                }
            }
            .navigationTitle("My Books")
            .toolbar { EditButton() }
            .safeAreaInset(edge: .bottom) { ShelvesView().background(.bar) }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 10) {
                    Picker("Reading status", selection: $selectedStatus) {
                        ForEach(ReadingStatus.allCases) { status in
                            Text(status.rawValue)
                                .tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

//                    Picker("Sort", selection: $sortBy) {
//                        Text("Recent").tag(0)
//                        Text("Title").tag(1)
//                        Text("Rating").tag(2)
//                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                .padding(.vertical, 10)
                .background(.bar)
            }
        }
    }
}

private struct LibraryBookRow: View {
    @EnvironmentObject private var library: LibraryStore
    let book: LibraryBook
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            CoverImage(url: book.coverURL).frame(width: 60, height: 88)
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title).font(.headline).lineLimit(2)
                Text(book.authors.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                if book.status == .currentlyReading {
                    ProgressView(value: book.progressFraction).tint(.indigo)
                    Text(book.pageCount.map { "Page \(book.currentPage) of \($0) · \(book.progressPercentage)%" } ?? "\(book.progressPercentage)% complete").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Menu { ForEach(ReadingStatus.allCases) { status in Button(status.rawValue) { library.update(book.id, status: status) } } } label: { Image(systemName: "ellipsis.circle").font(.title3) }
        }
        .padding(.vertical, 5)
        .contextMenu {
            ForEach(ReadingStatus.allCases) { status in Button("Mark as \(status.rawValue)") { library.update(book.id, status: status) } }
            Button("Remove from library", role: .destructive) { library.delete(book) }
        }
    }
}
