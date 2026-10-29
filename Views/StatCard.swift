//
//  StatCard.swift
//  Book Tracker
//

import SwiftUI

struct StatCard: View {

    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {

        VStack(spacing: 12) {

            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 3)

    }
}
