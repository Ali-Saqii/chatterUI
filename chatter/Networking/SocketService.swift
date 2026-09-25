//
//  SocketService.swift
//  chatter
//
//  Lightweight Socket.IO v4 client using native URLSessionWebSocketTask.
//  No external dependencies required — implements the Engine.IO / Socket.IO
//  wire protocol directly over WebSocket transport.
//

import Foundation
import Combine

// MARK: - Socket Events

enum SocketEvent {
    case newNotification(AppNotification)
    case notificationRead(notificationId: String, readAt: Date)
    case allNotificationsRead
    case connected
    case disconnected
}

// MARK: - Socket Service

@MainActor
final class SocketService: ObservableObject {
    static let shared = SocketService()
    
    // MARK: - Published State
    @Published private(set) var isConnected = false
    
    /// Event bus — AppState and ViewModels subscribe to this.
    let events = PassthroughSubject<SocketEvent, Never>()
    
    // MARK: - Private State
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private var currentToken: String?
    private var isIntentionalDisconnect = false
    
    /// Shared JSON decoder matching APIClient's date strategy.
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) { return date }
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) { return date }
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss'Z'"
            ]
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            for fmt in formats {
                formatter.dateFormat = fmt
                if let date = formatter.date(from: dateString) { return date }
            }
            return Date()
        }
        return d
    }()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Opens a WebSocket connection to the Socket.IO server.
    /// If already connected, this is a no-op.
    func connect(token: String) {
        guard !isConnected else {
            print("🔌 [SocketService] Already connected, skipping.")
            return
        }
        
        isIntentionalDisconnect = false
        currentToken = token
        
        guard let socketURL = buildSocketURL() else {
            print("❌ [SocketService] Could not build Socket.IO URL from baseURL: \(AppConfig.baseURL)")
            return
        }
        
        print("🔌 [SocketService] Connecting to \(socketURL.absoluteString)")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
        webSocket = session?.webSocketTask(with: socketURL)
        webSocket?.resume()
        
        // Start the receive loop
        receiveTask = Task { [weak self] in
            await self?.receiveLoop()
        }
    }
    
    /// Cleanly disconnects the WebSocket and cancels reconnection.
    func disconnect() {
        print("🔌 [SocketService] Disconnecting (intentional).")
        isIntentionalDisconnect = true
        currentToken = nil
        reconnectAttempts = 0
        reconnectTask?.cancel()
        reconnectTask = nil
        receiveTask?.cancel()
        receiveTask = nil
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        session?.invalidateAndCancel()
        session = nil
        
        if isConnected {
            isConnected = false
            events.send(.disconnected)
        }
    }
    
    // MARK: - URL Builder
    
    /// Converts the REST base URL (e.g. `http://localhost:5000/api/`)
    /// into a WebSocket Socket.IO URL: `ws://localhost:5000/socket.io/?EIO=4&transport=websocket`
    private func buildSocketURL() -> URL? {
        var base = AppConfig.baseURL
        
        // Strip /api/ suffix to get the server root
        if base.hasSuffix("/api/") {
            base = String(base.dropLast(5))
        } else if base.hasSuffix("/api") {
            base = String(base.dropLast(4))
        }
        
        // Convert http(s) → ws(s)
        if base.hasPrefix("https://") {
            base = "wss://" + base.dropFirst(8)
        } else if base.hasPrefix("http://") {
            base = "ws://" + base.dropFirst(7)
        }
        
        // Ensure no trailing slash
        while base.hasSuffix("/") {
            base = String(base.dropLast())
        }
        
        return URL(string: "\(base)/socket.io/?EIO=4&transport=websocket")
    }
    
    // MARK: - Receive Loop
    
    /// Continuously reads messages from the WebSocket until disconnection.
    private func receiveLoop() async {
        guard let ws = webSocket else { return }
        
        while !isIntentionalDisconnect && !Task.isCancelled {
            do {
                let message = try await ws.receive()
                handleRawMessage(message)
            } catch {
                if !isIntentionalDisconnect {
                    print("❌ [SocketService] WebSocket receive error: \(error.localizedDescription)")
                    handleDisconnect()
                }
                return
            }
        }
    }
    
    // MARK: - Engine.IO / Socket.IO Protocol Parser
    
    private func handleRawMessage(_ message: URLSessionWebSocketTask.Message) {
        var text: String?
        switch message {
        case .string(let str):
            text = str
        case .data(let data):
            text = String(data: data, encoding: .utf8)
        @unknown default:
            break
        }
        
        guard let text = text, let firstChar = text.first else { return }
        
        // Engine.IO v4 packet types (first character)
        // 0 = open, 1 = close, 2 = ping, 3 = pong, 4 = message
        switch firstChar {
        case "0": // Engine.IO OPEN — server sends session id and config
            handleEngineOpen(text)
        case "2": // Engine.IO PING — respond with PONG
            sendRawText("3")
        case "4": // Engine.IO MESSAGE — contains a Socket.IO packet
            let sioPacket = String(text.dropFirst())
            handleSocketIOPacket(sioPacket)
        default:
            break
        }
    }
    
    /// Handles Engine.IO OPEN: `0{"sid":"...","upgrades":[],"pingInterval":25000,...}`
    /// Immediately sends a Socket.IO CONNECT with the JWT auth payload.
    private func handleEngineOpen(_ text: String) {
        print("🔌 [SocketService] Engine.IO OPEN received.")
        
        // Send Socket.IO CONNECT (type 0) on the default namespace with auth
        if let token = currentToken {
            // Escape token for safe JSON embedding
            let escaped = token
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            sendRawText("40{\"token\":\"\(escaped)\"}")
        } else {
            sendRawText("40")
        }
    }
    
    /// Parses Socket.IO packets (after the Engine.IO "4" prefix has been stripped).
    /// Socket.IO types: 0 = CONNECT, 1 = DISCONNECT, 2 = EVENT, 3 = ACK
    private func handleSocketIOPacket(_ packet: String) {
        guard let firstChar = packet.first else { return }
        
        switch firstChar {
        case "0": // Socket.IO CONNECT ACK
            print("✅ [SocketService] Connected to Socket.IO namespace.")
            isConnected = true
            reconnectAttempts = 0
            events.send(.connected)
            
        case "1": // Socket.IO DISCONNECT
            print("🔌 [SocketService] Server sent Socket.IO DISCONNECT.")
            handleDisconnect()
            
        case "2": // Socket.IO EVENT — `["eventName", payload]`
            let eventJSON = String(packet.dropFirst())
            handleSocketIOEvent(eventJSON)
            
        default:
            break
        }
    }
    
    // MARK: - Event Handling
    
    /// Parses a Socket.IO EVENT. The wire format is a JSON array:
    /// `["notification:new", { ...notification object... }]`
    private func handleSocketIOEvent(_ eventData: String) {
        guard let data = eventData.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let eventName = array.first as? String else {
            return
        }
        
        let payload = array.count > 1 ? array[1] : nil
        
        #if DEBUG
        print("📩 [SocketService] Event: \(eventName)")
        #endif
        
        switch eventName {
        case "notification:new":
            guard let payloadObj = payload,
                  let payloadData = try? JSONSerialization.data(withJSONObject: payloadObj),
                  let notification = try? decoder.decode(AppNotification.self, from: payloadData) else {
                print("❌ [SocketService] Failed to decode notification:new payload.")
                return
            }
            events.send(.newNotification(notification))
            
        case "notification:read":
            guard let dict = payload as? [String: Any],
                  let notificationId = dict["notificationId"] as? String else {
                return
            }
            let readAt: Date
            if let readAtStr = dict["readAt"] as? String {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                readAt = iso.date(from: readAtStr) ?? Date()
            } else {
                readAt = Date()
            }
            events.send(.notificationRead(notificationId: notificationId, readAt: readAt))
            
        case "notification:read_all":
            events.send(.allNotificationsRead)
            
        default:
            #if DEBUG
            print("ℹ️ [SocketService] Unhandled event: \(eventName)")
            #endif
        }
    }
    
    // MARK: - Disconnection & Reconnection
    
    private func handleDisconnect() {
        let wasConnected = isConnected
        isConnected = false
        receiveTask?.cancel()
        receiveTask = nil
        webSocket?.cancel(with: .abnormalClosure, reason: nil)
        webSocket = nil
        session?.invalidateAndCancel()
        session = nil
        
        if wasConnected {
            events.send(.disconnected)
        }
        
        // Auto-reconnect with exponential backoff
        if !isIntentionalDisconnect, let token = currentToken {
            scheduleReconnect(token: token)
        }
    }
    
    private func scheduleReconnect(token: String) {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("⚠️ [SocketService] Max reconnect attempts reached (\(maxReconnectAttempts)).")
            return
        }
        
        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0) // 2s, 4s, 8s, ... max 30s
        
        print("🔄 [SocketService] Reconnecting in \(Int(delay))s (attempt \(reconnectAttempts)/\(maxReconnectAttempts))...")
        
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self = self, !self.isIntentionalDisconnect, !Task.isCancelled else { return }
            self.connect(token: token)
        }
    }
    
    // MARK: - Send Helper
    
    private func sendRawText(_ text: String) {
        webSocket?.send(.string(text)) { error in
            if let error = error {
                print("❌ [SocketService] Send failed: \(error.localizedDescription)")
            }
        }
    }
}
