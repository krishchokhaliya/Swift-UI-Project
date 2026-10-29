//
//  BookViewModel.swift
//  Book Tracker
//
//  Created by Admin2 on 03/08/26.
//


import Foundation
import Combine

@MainActor
final class BookViewModel: ObservableObject {
    @Published private(set) var books: [GoogleBook] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    private let service: GoogleBooksService

    init(service: GoogleBooksService = GoogleBooksService()) { self.service = service }

    func search(_ query: String) async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { books = []; return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do { books = try await service.searchBooks(query: text) }
        catch { books = []; errorMessage = error.localizedDescription }
    }
}
