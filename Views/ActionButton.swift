//
//  ActionButton.swift
//  Book Tracker
//

import SwiftUI

struct ActionButton: View {

    let icon: String
    let title: String

    var body: some View {

        VStack(spacing: 10) {

            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 55, height: 55)
                .background(.blue)
                .clipShape(Circle())

            Text(title)
                .font(.caption)

        }
        .frame(maxWidth: .infinity)

    }
}
