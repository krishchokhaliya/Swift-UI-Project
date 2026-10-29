import SwiftUI

struct CurrentReadingCard: View {

    var body: some View {

        VStack(alignment: .leading, spacing: 15) {

            Text("Currently Reading")
                .font(.headline)

            HStack {

                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 90, height: 130)
                    .overlay(
                        Image(systemName: "book.closed.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                    )

                VStack(alignment: .leading, spacing: 8) {

                    Text("The Psychology of Money")
                        .font(.headline)

                    Text("Morgan Housel")
                        .foregroundColor(.gray)

                    ProgressView(value: 0.62)
                        .tint(.green)

                    Text("186 / 300 Pages")

                    Button("Continue Reading") {

                    }
                    .buttonStyle(.borderedProminent)

                }

                Spacer()

            }

        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
        .padding(.horizontal)

    }

}
