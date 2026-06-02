// MARK: - HTTPClient.swift
// Generic Network Layer — works with ANY Codable API

import Foundation

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH
}

// MARK: - Network Error
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case serverError(Int)
    case unknown(Error)
    case noInternetConnection

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "The URL is invalid."
        case .noData:               return "No data received from server."
        case .decodingFailed(let e): return "Decoding failed: \(e.localizedDescription)"
        case .serverError(let code): return "Server returned error code: \(code)"
        case .unknown(let e):       return "Unknown error: \(e.localizedDescription)"
        case .noInternetConnection: return "No internet connection."
        }
    }
}

// MARK: - Request Protocol
protocol APIRequest {
    associatedtype Response: Decodable
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}

// Default implementations
extension APIRequest {
    var method: HTTPMethod { .GET }
    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
}

// MARK: - HTTPClient (Generic)
final class HTTPClient {
    static let shared = HTTPClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: Generic Execute — async/await
    func execute<R: APIRequest>(_ request: R) async throws -> R.Response {
        let urlRequest = try buildURLRequest(from: request)
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(R.Response.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    // MARK: Generic Execute — Combine (optional)
    func execute<R: APIRequest>(_ request: R, completion: @escaping (Result<R.Response, NetworkError>) -> Void) {
        guard let urlRequest = try? buildURLRequest(from: request) else {
            completion(.failure(.invalidURL)); return
        }
        session.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self else { return }
            if let error = error {
                completion(.failure(.unknown(error))); return
            }
            guard let data = data else {
                completion(.failure(.noData)); return
            }
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(.failure(.serverError(code))); return
            }
            do {
                let decoded = try self.decoder.decode(R.Response.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }.resume()
    }

    // MARK: URL Builder
    private func buildURLRequest<R: APIRequest>(from request: R) throws -> URLRequest {
        guard var components = URLComponents(string: request.baseURL + request.path) else {
            throw NetworkError.invalidURL
        }
        if let queryItems = request.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw NetworkError.invalidURL }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.headers?.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
        return urlRequest
    }
}
