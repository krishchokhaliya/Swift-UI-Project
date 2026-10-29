import SwiftUI

struct FloatingAddButton: View {

    var body: some View {

        Button {

            // Navigate to Add Book

        } label: {

            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 6)

        }

    }
}

#Preview {
    FloatingAddButton()
}
