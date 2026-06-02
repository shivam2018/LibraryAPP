// MARK: - Models.swift
// Decodable models for Open Library API

import Foundation

// MARK: - Book Search Response
struct BookSearchResponse: Decodable {
    let numFound: Int
    let docs: [BookDoc]
}

struct BookDoc: Decodable, Identifiable {
    let key: String           // e.g. "/works/OL45804W"
    let title: String
    let authorName: [String]?
    let coverId: Int?
    let firstPublishYear: Int?
    let subject: [String]?
    let numberOfPagesMedian: Int?
    let ratingsAverage: Double?
    let ratingsCount: Int?

    var id: String { key }

    var workKey: String {
        key.replacingOccurrences(of: "/works/", with: "")
    }

    var coverURL: URL? {
        guard let coverId else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg")
    }

    var largeCoverURL: URL? {
        guard let coverId else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg")
    }

    var primaryAuthor: String {
        authorName?.first ?? "Unknown Author"
    }

    var rating: String {
        guard let avg = ratingsAverage else { return "N/A" }
        return String(format: "%.1f", avg)
    }
}

// MARK: - Subject Books Response
struct SubjectBooksResponse: Decodable {
    let name: String
    let workCount: Int
    let works: [SubjectWork]
}

struct SubjectWork: Decodable, Identifiable {
    let key: String
    let title: String
    let authors: [WorkAuthor]?
    let coverId: Int?
    let firstPublishYear: Int?
    let subject: [String]?

    var id: String { key }

    var workKey: String {
        key.replacingOccurrences(of: "/works/", with: "")
    }

    var primaryAuthor: String {
        authors?.first?.name ?? "Unknown Author"
    }

    var coverURL: URL? {
        guard let coverId else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg")
    }

    var largeCoverURL: URL? {
        guard let coverId else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg")
    }

    // Convert to BookDoc for unified use
    var asBookDoc: BookDoc {
        BookDoc(
            key: key,
            title: title,
            authorName: authors?.map(\.name),
            coverId: coverId,
            firstPublishYear: firstPublishYear,
            subject: subject,
            numberOfPagesMedian: nil,
            ratingsAverage: nil,
            ratingsCount: nil
        )
    }
}

struct WorkAuthor: Decodable {
    let key: String
    let name: String
}

// MARK: - Book Detail Response
struct BookDetailResponse: Decodable {
    let key: String
    let title: String
    let description: BookDescription?
    let subjects: [String]?
    let subjectPlaces: [String]?
    let subjectTimes: [String]?
    let firstPublishDate: String?
    let covers: [Int]?

    var descriptionText: String {
        switch description {
        case .string(let s): return s
        case .object(let o): return o.value
        case nil: return "No description available."
        }
    }

    var coverURL: URL? {
        guard let id = covers?.first else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(id)-L.jpg")
    }
}

enum BookDescription: Decodable {
    case string(String)
    case object(DescriptionObject)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else {
            self = .object(try container.decode(DescriptionObject.self))
        }
    }
}

struct DescriptionObject: Decodable {
    let value: String
}

// MARK: - Author Response
struct AuthorResponse: Decodable {
    let key: String
    let name: String
    let bio: AuthorBio?
    let birthDate: String?
    let deathDate: String?
    let photos: [Int]?
    let topWork: String?

    var bioText: String {
        switch bio {
        case .string(let s): return s
        case .object(let o): return o.value
        case nil: return "No bio available."
        }
    }

    var photoURL: URL? {
        guard let id = photos?.first else { return nil }
        return URL(string: "https://covers.openlibrary.org/a/id/\(id)-L.jpg")
    }
}

enum AuthorBio: Decodable {
    case string(String)
    case object(DescriptionObject)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else {
            self = .object(try container.decode(DescriptionObject.self))
        }
    }
}
