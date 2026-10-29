
import SwiftUI

struct SearchBookView: View {

    // MARK: - State

    @State private var query = ""

    @StateObject private var viewModel =
        BookViewModel()

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                Group {

                    if viewModel.isLoading {

                        loadingView

                    } else if let error =
                        viewModel.errorMessage {

                        errorView(
                            message: error
                        )

                    } else if viewModel.books.isEmpty {

                        emptyView

                    } else {

                        searchResults
                    }
                }
            }

            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)

            .searchable(
                text: $query,
                prompt: "Title, author, or ISBN"
            )

            .onSubmit(of: .search) {
                search()
            }

            .toolbar {

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button {
                        search()
                    } label: {

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Color.accentColor,
                                in: Circle()
                            )
                    }

                    .disabled(
                        query
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {

        VStack(spacing: 18) {

            ZStack {

                Circle()
                    .fill(
                        Color.accentColor.opacity(0.12)
                    )
                    .frame(
                        width: 78,
                        height: 78
                    )

                ProgressView()
                    .scaleEffect(1.25)
                    .tint(.accentColor)
            }

            Text("Searching Google Books...")
                .font(.headline)

            Text("Finding books for you")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Empty View

    private var emptyView: some View {

        VStack(spacing: 22) {

            ZStack {

                Circle()
                    .fill(
                        Color.accentColor.opacity(0.12)
                    )
                    .frame(
                        width: 110,
                        height: 110
                    )

                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 8) {

                Text("Find Your Next Book")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(
                    "Search by title, author, or ISBN and discover your next great read."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            }

            HStack(spacing: 8) {

                Image(systemName: "magnifyingglass")

                Text("Start searching above")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Color.accentColor.opacity(0.10),
                in: Capsule()
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding()
    }

    // MARK: - Error View

    private func errorView(
        message: String
    ) -> some View {

        VStack(spacing: 20) {

            ZStack {

                Circle()
                    .fill(
                        Color.red.opacity(0.10)
                    )
                    .frame(
                        width: 82,
                        height: 82
                    )

                Image(
                    systemName:
                        "exclamationmark.triangle.fill"
                )
                .font(.system(size: 32))
                .foregroundStyle(.red)
            }

            VStack(spacing: 8) {

                Text("Search Unavailable")
                    .font(.title3)
                    .fontWeight(.bold)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                search()
            } label: {

                Label(
                    "Try Again",
                    systemImage: "arrow.clockwise"
                )
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Capsule())
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding()
    }

    // MARK: - Results

    private var searchResults: some View {

        List(
            viewModel.books
        ) { book in

            NavigationLink {

                BookDetailView(
                    bookID: book.id,
                    initialBook: book
                )

            } label: {

                SearchResultRow(
                    book: book
                )
            }

            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(
                EdgeInsets(
                    top: 7,
                    leading: 16,
                    bottom: 7,
                    trailing: 16
                )
            )
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Search

    private func search() {

        let text = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !text.isEmpty else {
            return
        }

        Task {

            await viewModel.search(
                text
            )
        }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {

    let book: GoogleBook

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 15
        ) {

            // Book Cover

            CoverImage(
                url: book
                    .volumeInfo
                    .imageLinks?
                    .thumbnail?
                    .secureURLString
            )
            .frame(
                width: 82,
                height: 118
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
            .shadow(
                color: .black.opacity(0.12),
                radius: 5,
                x: 0,
                y: 3
            )

            // Book Information

            VStack(
                alignment: .leading,
                spacing: 7
            ) {

                Text(
                    book.volumeInfo.title
                )
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(2)

                Text(
                    book.volumeInfo.authors?
                        .joined(separator: ", ")
                    ?? "Unknown author"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

                Spacer(minLength: 2)

                if let date =
                    book.volumeInfo.publishedDate {

                    Label(
                        date,
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if let pages =
                    book.volumeInfo.pageCount {

                    Label(
                        "\(pages) pages",
                        systemImage: "book.pages"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            Color(.systemBackground),
            in: RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(
                Color.primary.opacity(0.05),
                lineWidth: 1
            )
        )
        .shadow(
            color: .black.opacity(0.06),
            radius: 8,
            x: 0,
            y: 3
        )
    }
}

