//
//  RecentBooksSection.swift
//  Book Tracker
//

import SwiftUI

struct RecentBooksSection: View {

    var body: some View {

        VStack(alignment: .leading, spacing: 15) {

            Text("Recently Added")
                .font(.title3.bold())

            ScrollView(.horizontal, showsIndicators: false) {

                HStack(spacing: 15) {

                    BookCard(title: "Atomic Habits", author: "James Clear")

                    BookCard(title: "Deep Work", author: "Cal Newport")

                    BookCard(title: "The Alchemist", author: "Paulo Coelho")

                }

            }

        }

    }
}

#Preview {
    RecentBooksSection()
        .padding()
}
