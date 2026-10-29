//
//  QuickActionsSection.swift
//  Book Tracker
//

import SwiftUI

struct QuickActionsSection: View {

    var body: some View {

        VStack(alignment: .leading, spacing: 15) {

            Text("Quick Actions")
                .font(.title3.bold())

            HStack {

                ActionButton(icon: "plus", title: "Add")

                ActionButton(icon: "barcode.viewfinder", title: "Scan")

                ActionButton(icon: "books.vertical.fill", title: "Library")

                ActionButton(icon: "chart.bar.fill", title: "Stats")

            }

        }

    }
}

#Preview {
    QuickActionsSection()
        .padding()
}
