import SwiftUI
import Charts

struct StatisticsDashboardView: View {
@EnvironmentObject private var library: LibraryStore
@State private var selectedStatus: String?


private var chartData: [StatusStatistic] {
    [
        StatusStatistic(name: "Want to Read", count: library.unreadBooks, color: .orange),
        StatusStatistic(name: "Reading", count: library.currentlyReading, color: .indigo),
        StatusStatistic(name: "Read", count: library.booksRead, color: .green)
    ]
}

var body: some View {
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reading at a glance")
                        .font(.largeTitle.bold())

                    Text("Track your reading progress and library activity.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Statistics Cards
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ],
                    spacing: 14
                ) {
                    StatisticsTile(
                        title: "Total books",
                        value: library.totalBooks,
                        icon: "books.vertical.fill",
                        color: .indigo
                    )

                    StatisticsTile(
                        title: "Books read",
                        value: library.booksRead,
                        icon: "checkmark.seal.fill",
                        color: .green
                    )

                    StatisticsTile(
                        title: "Currently reading",
                        value: library.currentlyReading,
                        icon: "book.fill",
                        color: .blue
                    )

                    StatisticsTile(
                        title: "Unread books",
                        value: library.unreadBooks,
                        icon: "bookmark.fill",
                        color: .orange
                    )
                }

                // MARK: - Chart
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Library by status")
                                .font(.title3.bold())

                            Text("Your books grouped by reading status")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chart.bar.fill")
                            .font(.title3)
                            .foregroundStyle(.indigo)
                            .padding(10)
                            .background(
                                Color.indigo.opacity(0.1),
                                in: Circle()
                            )
                    }

                    Chart(chartData) { item in
                        BarMark(
                            x: .value("Status", item.name),
                            y: .value("Books", item.count)
                        )
                        .foregroundStyle(item.color.gradient)
                        .cornerRadius(8)
                        .annotation(position: .top) {
                            Text("\(item.count)")
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(height: 190)
                    .chartXSelection(value: $selectedStatus)
                    .animation(
                        .easeInOut,
                        value: chartData.map(\.count)
                    )

                    if let selectedStatus,
                       let selection = chartData.first(
                        where: { $0.name == selectedStatus }
                       ) {
                        Label(
                            "\(selection.count) book(s) marked \(selection.name)",
                            systemImage: "hand.tap.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(selection.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selection.color.opacity(0.1),
                            in: Capsule()
                        )
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap")
                            Text("Tap a bar to inspect that reading status.")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
                .background(
                    Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 24)
                )

                // MARK: - Current Reading
                if let current = library.books.first(
                    where: { $0.status == .currentlyReading }
                ) {
                    ProgressEditor(book: current)
                }
                GoalsInsightsView()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
    }
}


}

// MARK: - Status Statistic

private struct StatusStatistic: Identifiable {
let name: String
let count: Int
let color: Color

var id: String {
    name
}

}

// MARK: - Statistics Tile

private struct StatisticsTile: View {
let title: String
let value: Int
let icon: String
let color: Color


var body: some View {
    VStack(alignment: .leading, spacing: 14) {
        HStack {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(
                    color.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 12)
                )

            Spacer()
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(18)
    .background(
        Color(.secondarySystemBackground),
        in: RoundedRectangle(cornerRadius: 20)
    )
}

}

// MARK: - Progress Editor

private struct ProgressEditor: View {
@EnvironmentObject private var library: LibraryStore
let book: LibraryBook
@State private var progress: Double


init(book: LibraryBook) {
    self.book = book
    _progress = State(initialValue: book.progressFraction)
}

var body: some View {
    VStack(alignment: .leading, spacing: 16) {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Update reading progress")
                    .font(.title3.bold())

                Text(book.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "book.pages.fill")
                .font(.title3)
                .foregroundStyle(.indigo)
                .padding(10)
                .background(
                    Color.indigo.opacity(0.1),
                    in: Circle()
                )
        }

        Slider(
            value: $progress,
            in: 0...1,
            step: 0.05,
            onEditingChanged: { editing in
                if !editing {
                    library.updateProgress(
                        book.id,
                        progress: progress
                    )
                }
            }
        )

        HStack {
            Text("Reading progress")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(progress * 100))%")
                .font(.subheadline.bold())
                .foregroundStyle(.indigo)
        }
    }
    .padding(20)
    .background(
        Color(.secondarySystemBackground),
        in: RoundedRectangle(cornerRadius: 24)
    )
}


}
