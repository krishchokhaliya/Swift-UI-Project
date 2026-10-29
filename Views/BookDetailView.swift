import SwiftUI
import SafariServices

struct BookDetailView: View {
    @EnvironmentObject private var library: LibraryStore
    let bookID: String
    @State private var book: GoogleBook
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isShowingReader = false

    init(bookID: String, initialBook: GoogleBook) {
        self.bookID = bookID
        _book = State(initialValue: initialBook)
    }

    init(libraryBook: LibraryBook) {
        self.bookID = libraryBook.id
        _book = State(initialValue: GoogleBook(id: libraryBook.id, volumeInfo: VolumeInfo(title: libraryBook.title, authors: libraryBook.authors, description: libraryBook.summary, pageCount: libraryBook.pageCount, publishedDate: libraryBook.publishedDate, categories: libraryBook.categories, imageLinks: libraryBook.coverURL.map { ImageLinks(thumbnail: $0) }), accessInfo: libraryBook.previewURL.map { AccessInfo(webReaderLink: $0, previewLink: $0, viewability: nil) }))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 18) {
                    CoverImage(url: book.volumeInfo.imageLinks?.thumbnail?.secureURLString).frame(width: 130, height: 195)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(book.volumeInfo.title).font(.title2.bold())
                        Text(book.volumeInfo.authors?.joined(separator: ", ") ?? "Unknown author").foregroundStyle(.secondary)
                        if let pages = book.volumeInfo.pageCount { Label("\(pages) pages", systemImage: "book.pages").font(.caption) }
                        if let date = book.volumeInfo.publishedDate { Label(date, systemImage: "calendar").font(.caption) }
                    }
                    Spacer(minLength: 0)
                }
                if isLoading { ProgressView("Loading book details…") }
                if let errorMessage { Label(errorMessage, systemImage: "exclamationmark.triangle").foregroundStyle(.orange).font(.caption) }
                Text("About this book").font(.title3.bold())
                Text(book.volumeInfo.description ?? "No description is available for this book.").foregroundStyle(.secondary)
                if let savedBook = library.book(withID: book.id) {
                    ReadingManagementSection(book: savedBook)
                }
                VStack(spacing: 12) {
                    Button { isShowingReader = true } label: { Label("Read / Open Book", systemImage: "book.fill") }
                        .buttonStyle(.borderedProminent).frame(maxWidth: .infinity).disabled(previewURL == nil)
                    Button { library.toggleWishlist(book) } label: {
                        Label(library.book(withID: book.id)?.isWishlisted == true ? "Remove from Wishlist" : "Add to Wishlist", systemImage: "heart")
                    }.buttonStyle(.bordered).frame(maxWidth: .infinity)
                    Menu { ForEach(ReadingStatus.allCases) { status in Button("Mark as \(status.rawValue)") { library.add(book, status: status) } } } label: { Label("Update Reading Status", systemImage: "checklist") }
                        .buttonStyle(.bordered).frame(maxWidth: .infinity)
                }
            }.padding()
        }
        .navigationTitle("Book Details").navigationBarTitleDisplayMode(.inline)
        .task { await loadDetails() }
        .sheet(isPresented: $isShowingReader) { if let previewURL { SafariView(url: previewURL) } }
    }

    private var previewURL: URL? { (book.accessInfo?.webReaderLink ?? book.accessInfo?.previewLink).flatMap(URL.init(string:)) }
    private func loadDetails() async { defer { isLoading = false }; do { book = try await GoogleBooksService().bookDetails(id: bookID) } catch { errorMessage = error.localizedDescription } }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) { }
}

struct CoverImage: View {
    let url: String?
    var body: some View {
        AsyncImage(url: url.flatMap(URL.init(string:))) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            default: Image(systemName: "book.closed.fill").font(.title).foregroundStyle(.indigo).frame(maxWidth: .infinity, maxHeight: .infinity).background(.indigo.opacity(0.12))
            }
        }.clipShape(RoundedRectangle(cornerRadius: 12)).accessibilityLabel("Book cover")
    }
}
