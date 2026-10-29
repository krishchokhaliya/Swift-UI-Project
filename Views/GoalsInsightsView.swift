import SwiftUI

struct GoalsInsightsView: View {
    @EnvironmentObject private var library: LibraryStore

    @State private var annual = ""
    @State private var monthly = ""
    @State private var dailyPages = ""
    @State private var dailyMinutes = ""

    private var analytics: ReadingAnalytics {
        ReadingAnalytics(document: library.document)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Goals & reading habits")
                .font(.title2.bold())

            HStack {
                metric(
                    "Current streak",
                    "\(analytics.currentStreak) days",
                    "flame.fill",
                    .orange
                )

                metric(
                    "Longest streak",
                    "\(analytics.longestStreak) days",
                    "trophy.fill",
                    .yellow
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Goals")
                    .font(.headline)

                TextField("Annual books", text: $annual)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Monthly books", text: $monthly)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Daily pages", text: $dailyPages)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Daily minutes", text: $dailyMinutes)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                Button("Save goals") {
                    let annualTarget = Int(annual)
                    let monthlyTarget = Int(monthly)
                    let dailyPagesTarget = Int(dailyPages)

                    let dailyDurationTarget: Double? = {
                        guard let minutes = Double(dailyMinutes) else {
                            return nil
                        }

                        return minutes * 60
                    }()

                    let goals = ReadingGoals(
                        annualBooksTarget: annualTarget,
                        monthlyBooksTarget: monthlyTarget,
                        dailyPagesTarget: dailyPagesTarget,
                        dailyReadingDurationTarget: dailyDurationTarget
                    )

                    library.replaceGoals(goals)
                }
                .buttonStyle(.borderedProminent)
            }

            if let goal = library.document.goals.annualBooksTarget {
                ProgressView(
                    "Annual goal: \(library.booksRead) of \(goal) books",
                    value: Double(library.booksRead),
                    total: Double(goal)
                )
                .tint(.indigo)
            }

            Text("Last 28 days")
                .font(.headline)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible()),
                    count: 7
                ),
                spacing: 5
            ) {
                ForEach(analytics.recentActivity) { day in
                    let opacity = min(1.0, 0.25 + Double(day.pages) / 40.0)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            day.hasActivity
                                ? Color.indigo.opacity(opacity)
                                : Color.secondary.opacity(0.12)
                        )
                        .frame(height: 20)
                        .accessibilityLabel(
                            "\(day.date.formatted(date: .abbreviated, time: .omitted)): \(day.pages) pages, \(Int(day.duration / 60)) minutes"
                        )
                }
            }

            ForEach(
                library.books.filter {
                    $0.status == .currentlyReading
                }
            ) { book in
                if let date = analytics.estimatedCompletion(for: book) {
                    Label(
                        "Estimated completion for \(book.title): " +
                        "\(date.formatted(date: .abbreviated, time: .omitted))",
                        systemImage: "calendar.badge.clock"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .onAppear {
            annual = library.document.goals.annualBooksTarget
                .map { String($0) } ?? ""

            monthly = library.document.goals.monthlyBooksTarget
                .map { String($0) } ?? ""

            dailyPages = library.document.goals.dailyPagesTarget
                .map { String($0) } ?? ""

            dailyMinutes = library.document.goals.dailyReadingDurationTarget
                .map { String(Int($0 / 60)) } ?? ""
        }
    }

    private func metric(
        _ title: String,
        _ value: String,
        _ icon: String,
        _ color: Color
    ) -> some View {
        Label {
            VStack(alignment: .leading) {
                Text(value)
                    .bold()

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
