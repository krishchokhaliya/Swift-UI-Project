//
//  DashboardHeader.swift
//  Book Tracker
//

import SwiftUI

struct DashboardHeader: View {

    var userName: String = "Krish"

    var body: some View {

        HStack {

            VStack(alignment: .leading, spacing: 4) {

                Text("Good Morning 👋")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(userName)
                    .font(.title3)
                    .foregroundStyle(.primary)

                Text("Let's continue your reading journey")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            }

            Spacer()

            Button {

            } label: {

                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }

            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 45))
                .foregroundStyle(.blue)

        }
    }
}

#Preview {
    DashboardHeader()
}
