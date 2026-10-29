import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var library: LibraryStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {

                        // MARK: - Welcome
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your reading shelf")
                                .font(.system(size: 30, weight: .bold))

                            Text("Every book, neatly in one place.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // MARK: - Statistics
                        HStack(spacing: 12) {
                            HomeMetric(
                                title: "Books",
                                value: library.totalBooks,
                                color: .indigo
                            )

                            HomeMetric(
                                title: "Finished",
                                value: library.booksRead,
                                color: .green
                            )

                            HomeMetric(
                                title: "Reading",
                                value: library.currentlyReading,
                                color: .orange
                            )
                        }

                        if let goal = library.document.goals.annualBooksTarget {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Annual reading goal").font(.headline)
                                ProgressView(value: Double(library.booksRead), total: Double(goal)).tint(.indigo)
                                Text("\(library.booksRead) of \(goal) books completed").font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
                        }

                        // MARK: - Currently Reading
                        if let current = library.books.first(where: {
                            $0.status == .currentlyReading
                        }) {
                            NavigationLink {
                                MyBooksView(initialStatus: .currentlyReading)
                            } label: {
                                CurrentBookHomeCard(book: current)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ContentUnavailableView(
                                "Start your next chapter",
                                systemImage: "book.closed",
                                description: Text(
                                    "Search for a book, then mark it as currently reading."
                                )
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(
                                .thinMaterial,
                                in: RoundedRectangle(cornerRadius: 20)
                            )
                        }

                        // MARK: - Recently Added
                        HStack {
                            Text("Recently added")
                                .font(.title2.bold())

                            Spacer()

                            Image(systemName: "books.vertical.fill")
                                .font(.title3)
                                .foregroundStyle(.indigo)
                        }

                        if library.books.isEmpty {
                            Text("Your library is waiting for its first book.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(Array(library.books.prefix(8))) { book in
                                        NavigationLink { BookDetailView(libraryBook: book) } label: { HomeBookCard(book: book) }
                                            .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                DashboardTopBar()
            }
        }
    }
}

// MARK: - Top Navigation Bar

private struct DashboardTopBar: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)

                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Chapter & Co.")
                    .font(.headline.bold())

                Text("Your reading journey")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            NavigationLink {
                ProfileView()
            } label: {
                ZStack {
                    Circle()
                        .fill(.indigo.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.indigo)
                }
                .overlay {
                    Circle()
                        .stroke(.indigo.opacity(0.15), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.primary.opacity(0.06))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Home Metric

private struct HomeMetric: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(value)")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(color)

                Spacer()

                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 30, height: 30)
                    .overlay {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                    }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.primary.opacity(0.04), lineWidth: 1)
        }
    }
}

// MARK: - Current Book Card

private struct CurrentBookHomeCard: View {
    let book: LibraryBook

    var body: some View {
        HStack(spacing: 14) {
            CoverImage(url: book.coverURL)
                .frame(width: 70, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "book.pages.fill")
                        .font(.caption2)

                    Text("CURRENTLY READING")
                        .font(.caption2.bold())
                }
                .foregroundStyle(.orange)

                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(book.authors.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                ProgressView(value: book.progressFraction)
                    .tint(.indigo)
            }

            Spacer()
        }
        .padding(16)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.indigo.opacity(0.08), lineWidth: 1)
        }
    }
}

// MARK: - Recently Added Book Card

private struct HomeBookCard: View {
    let book: LibraryBook

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            CoverImage(url: book.coverURL)
                .frame(width: 120, height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(
                    color: .black.opacity(0.10),
                    radius: 6,
                    x: 0,
                    y: 3
                )

            Text(book.title)
                .font(.subheadline.bold())
                .lineLimit(2)

            Text(book.authors.first ?? "Unknown author")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 120, alignment: .leading)
    }
}
