//
//  SearchBooksRequest.swift
//  SearchBooksRequest
//
//  Created by Shivam Trivedi on 18/04/26.
//

import Foundation

let openLibraryBase = "https://openlibrary.org"

// MARK: - Search Books Request
struct SearchBooksRequest: APIRequest {
    typealias Response = BookSearchResponse

    var baseURL: String { openLibraryBase }
    var path: String { "/search.json" }

    let query: String
    let limit: Int

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "fields", value: "key,title,author_name,cover_i,first_publish_year,subject,number_of_pages_median,ratings_average,ratings_count")
        ]
    }
}

// MARK: - Trending Books Request (by subject)
struct SubjectBooksRequest: APIRequest {
    typealias Response = SubjectBooksResponse

    var baseURL: String { openLibraryBase }
    var path: String { "/subjects/\(subject).json" }

    let subject: String
    let limit: Int

    var queryItems: [URLQueryItem]? {
        [URLQueryItem(name: "limit", value: "\(limit)")]
    }
}

// MARK: - Book Details Request
struct BookDetailsRequest: APIRequest {
    typealias Response = BookDetailResponse

    var baseURL: String { openLibraryBase }
    var path: String { "/works/\(workKey).json" }

    let workKey: String  // e.g. "OL45804W"
}

// MARK: - Author Request
struct AuthorRequest: APIRequest {
    typealias Response = AuthorResponse

    var baseURL: String { openLibraryBase }
    var path: String { "/authors/\(authorKey).json" }

    let authorKey: String
}
