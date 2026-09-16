//
//  APIClient.swift
//  chatter
//

import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let data: T?
    let errors: [String]?
}

struct EmptyResponse: Decodable {}

struct MultipartFile {
    let fieldName: String
    let fileName: String
    let mimeType: String
    let data: Data
}

final class APIClient {
    static let shared = APIClient()
    
    var baseURL: String {
        get { AppConfig.baseURL }
        set { AppConfig.baseURL = newValue }
    }
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with fractional seconds
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            // Try standard ISO8601
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Fallback to standard formatter formats
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd HH:mm:ss"
            ]
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            for fmt in formats {
                formatter.dateFormat = fmt
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            #if DEBUG
            print("[APIClient] Warning: Could not decode date string: \(dateString)")
            #endif
            return Date()
        }
    }
    
    // MARK: - Standard JSON Requests
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = endpoint.url(baseURL: baseURL) else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        AuthInterceptor.shared.adapt(&urlRequest, requiresAuth: endpoint.requiresAuth)
        
        if let body = body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                urlRequest.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.networkError("Failed to encode request body: \(error.localizedDescription)")
            }
        }
        
        return try await execute(urlRequest)
    }
    
    // MARK: - Multipart Upload Requests
    func uploadMultipart<T: Decodable>(
        _ endpoint: APIEndpoint,
        fields: [String: String] = [:],
        files: [MultipartFile] = []
    ) async throws -> T {
        guard let url = endpoint.url(baseURL: baseURL) else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        AuthInterceptor.shared.adapt(&urlRequest, requiresAuth: endpoint.requiresAuth)
        
        let boundary = "Boundary-\(UUID().uuidString)"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var bodyData = Data()
        
        // Append text fields
        for (key, value) in fields {
            bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
            bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            bodyData.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Append file fields
        for file in files {
            bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
            bodyData.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n".data(using: .utf8)!)
            bodyData.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
            bodyData.append(file.data)
            bodyData.append("\r\n".data(using: .utf8)!)
        }
        
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = bodyData
        
        return try await execute(urlRequest)
    }
    
    // MARK: - Execution & Decoding
    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
        
        AuthInterceptor.shared.handleResponse(response)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Try decoding envelope first
        let envelope: APIResponse<T>? = try? decoder.decode(APIResponse<T>.self, from: data)
        
        if (200...299).contains(httpResponse.statusCode) {
            if let envelope = envelope {
                if let payload = envelope.data {
                    return payload
                } else if T.self == EmptyResponse.self {
                    return EmptyResponse() as! T
                }
            }
            
            // If envelope didn't match or data was direct:
            if let directPayload = try? decoder.decode(T.self, from: data) {
                return directPayload
            }
            
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            
            throw APIError.emptyData
        } else {
            // Handle error status code
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            } else if httpResponse.statusCode == 403 {
                throw APIError.forbidden
            } else if httpResponse.statusCode == 404 {
                throw APIError.notFound
            }
            
            if let envelope = envelope {
                if let errors = envelope.errors, !errors.isEmpty {
                    throw APIError.serverError(errors.joined(separator: ", "))
                } else if let message = envelope.message, !message.isEmpty {
                    throw APIError.serverError(message)
                }
            }
            
            // Fallback error from raw JSON message if possible
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorJson["message"] as? String {
                throw APIError.serverError(message)
            }
            
            throw APIError.serverError("Server returned status \(httpResponse.statusCode)")
        }
    }
}
