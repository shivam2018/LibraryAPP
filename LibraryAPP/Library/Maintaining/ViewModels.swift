//
//  ViewModels.swift
//  ViewModels
//
//  Created by Shivam Trivedi on 18/04/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Async State
enum AsyncState<T> {
    case idle
    case loading
    case success(T)
    case failure(NetworkError)

    var isLoading: Bool { if case .loading = self { return true }; return false }
    var value: T? { if case .success(let v) = self { return v }; return nil }
    var error: NetworkError? { if case .failure(let e) = self { return e }; return nil }
}

// MARK: - Home ViewModel
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var trending: AsyncState<[BookDoc]> = .idle
    @Published var fantasy: AsyncState<[BookDoc]> = .idle
    @Published var science: AsyncState<[BookDoc]> = .idle

    private let client = HTTPClient.shared

    func loadAll() async {
        async let t: () = loadTrending()
        async let f: () = loadSubject("fantasy")
        async let s: () = loadSubject("science")
        _ = await (t, f, s)
    }

    func loadTrending() async {
        trending = .loading
        do {
            let req = SearchBooksRequest(query: "popular classics literature", limit: 15)
            let result = try await client.execute(req)
            trending = .success(result.docs.filter { $0.coverId != nil })
        } catch let e as NetworkError {
            trending = .failure(e)
        } catch {
            trending = .failure(.unknown(error))
        }
    }

    func loadSubject(_ subject: String) async {
        if subject == "fantasy" { fantasy = .loading } else { science = .loading }
        do {
            let req = SubjectBooksRequest(subject: subject, limit: 15)
            let result = try await client.execute(req)
            let books = result.works.filter { $0.coverId != nil }.map(\.asBookDoc)
            if subject == "fantasy" {
                fantasy = .success(books)
            } else {
                science = .success(books)
            }
        } catch let e as NetworkError {
            if subject == "fantasy" { fantasy = .failure(e) } else { science = .failure(e) }
        } catch {
            if subject == "fantasy" { fantasy = .failure(.unknown(error)) } else { science = .failure(.unknown(error)) }
        }
    }
}

// MARK: - Search ViewModel
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var state: AsyncState<[BookDoc]> = .idle
    @Published var query: String = ""

    private let client = HTTPClient.shared
    private var searchTask: Task<Void, Never>?

    func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            state = .idle; return
        }
        searchTask?.cancel()
        state = .loading
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)  // debounce
            guard !Task.isCancelled else { return }
            do {
                let req = SearchBooksRequest(query: query, limit: 20)
                let result = try await client.execute(req)
                state = .success(result.docs.filter { $0.coverId != nil })
            } catch let e as NetworkError {
                state = .failure(e)
            } catch {
                state = .failure(.unknown(error))
            }
        }
    }

    func clear() {
        searchTask?.cancel()
        state = .idle
        query = ""
    }
}

// MARK: - Book Detail ViewModel
@MainActor
final class BookDetailViewModel: ObservableObject {
    @Published var detailState: AsyncState<BookDetailResponse> = .idle
    @Published var authorState: AsyncState<AuthorResponse> = .idle

    private let client = HTTPClient.shared

    func load(book: BookDoc) async {
        detailState = .loading
        do {
            let req = BookDetailsRequest(workKey: book.workKey)
            let detail = try await client.execute(req)
            detailState = .success(detail)
        } catch let e as NetworkError {
            detailState = .failure(e)
        } catch {
            detailState = .failure(.unknown(error))
        }
    }
}

// MARK: - Favourites Store (local)
final class FavouritesStore: ObservableObject {
    @Published private(set) var books: [BookDoc] = []

    func toggle(_ book: BookDoc) {
        if isFavourite(book) {
            books.removeAll { $0.id == book.id }
        } else {
            books.insert(book, at: 0)
        }
    }

    func isFavourite(_ book: BookDoc) -> Bool {
        books.contains { $0.id == book.id }
    }
}
