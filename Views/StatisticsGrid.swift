//
//  StatisticsGrid.swift
//  Book Tracker
//

import SwiftUI

struct StatisticsGrid: View {

    var body: some View {

        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {

            StatCard(title: "Books", value: "24", icon: "books.vertical.fill", color: .blue)

            StatCard(title: "Pages", value: "4856", icon: "doc.text.fill", color: .orange)

            StatCard(title: "Streak", value: "142", icon: "flame.fill", color: .red)

            StatCard(title: "Goal", value: "78%", icon: "target", color: .green)

        }

    }
}

#Preview {
    StatisticsGrid()
        .padding()
}
