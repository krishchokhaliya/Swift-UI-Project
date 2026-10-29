//
//  BookCard.swift
//  Book Tracker
//

import SwiftUI

struct BookCard: View {

    let title: String
    let author: String

    var body: some View {

        VStack(alignment: .leading) {

            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue.opacity(0.15))
                .frame(width: 120, height: 170)
                .overlay {

                    Image(systemName: "book.closed.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)

                }

            Text(title)
                .font(.headline)
                .lineLimit(2)

            Text(author)
                .font(.caption)
                .foregroundStyle(.secondary)

        }
        .frame(width: 120)

    }
}
