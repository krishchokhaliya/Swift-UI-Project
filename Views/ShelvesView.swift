import SwiftUI
struct ShelvesView: View {
 @EnvironmentObject private var library: LibraryStore
 @State private var name = ""
 var body: some View { VStack(alignment: .leading) { Text("Bookshelves").font(.headline); HStack { TextField("New shelf", text: $name).textFieldStyle(.roundedBorder); Button("Add") { library.createShelf(name: name); name = "" } }; ForEach(library.document.shelves) { shelf in VStack(alignment: .leading) { HStack { Text(shelf.name).bold(); Spacer(); Button(role: .destructive) { library.deleteShelf(shelf) } label: { Image(systemName: "trash") } }; Text("\(shelf.bookIDs.count) books").font(.caption).foregroundStyle(.secondary) } } }.padding() }
}
