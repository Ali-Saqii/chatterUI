//
//  URLResolver.swift
//  chatter
//

import Foundation

/// Centralized URL resolution for relative media/avatar paths from the backend.
enum URLResolver {
    /// Resolves a potentially relative URL string (e.g. "uploads/avatar.jpg")
    /// into a full URL using the API base URL.
    static func resolve(_ urlString: String?) -> URL? {
        guard let urlString = urlString, !urlString.isEmpty else { return nil }
        
        // Already a full URL
        if urlString.hasPrefix("http") {
            return URL(string: urlString)
        }
        
        // Build from base URL by stripping /api/ suffix
        var base = APIClient.shared.baseURL
        if base.hasSuffix("/api/") {
            base = String(base.dropLast(5))
        } else if base.hasSuffix("/api") {
            base = String(base.dropLast(4))
        }
        
        let separator = base.hasSuffix("/") ? "" : "/"
        return URL(string: "\(base)\(separator)\(urlString)")
    }
}
