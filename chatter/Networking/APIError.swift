//
//  APIError.swift
//  chatter
//

import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case unauthorized
    case forbidden
    case notFound
    case serverError(String)
    case decodingError(String)
    case networkError(String)
    case emptyData
    case invalidResponse
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL."
        case .unauthorized:
            return "Session expired or invalid credentials. Please log in again."
        case .forbidden:
            return "You do not have permission to perform this action."
        case .notFound:
            return "Requested resource could not be found."
        case .serverError(let message):
            return message
        case .decodingError(let details):
            return "Failed to process data from server: \(details)"
        case .networkError(let details):
            return "Network connection issue: \(details)"
        case .emptyData:
            return "No data was returned by the server."
        case .invalidResponse:
            return "Invalid response received from the server."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}
