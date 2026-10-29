//
//  ReadingGoalCard.swift
//  Book Tracker
//

import SwiftUI

struct ReadingGoalCard: View {

    var progress: Double = 0.7

    var body: some View {

        VStack(alignment: .leading, spacing: 15) {

            Text("Monthly Reading Goal")
                .font(.headline)

            ProgressView(value: progress)
                .tint(.green)

            HStack {

                Text("7 / 10 Books")

                Spacer()

                Text("70%")

            }

        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 3)

    }
}

#Preview {
    ReadingGoalCard()
        .padding()
}
