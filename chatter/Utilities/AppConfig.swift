//
//  AppConfig.swift
//  chatter
//

import Foundation

enum AppConfig {
    static let defaultBaseURL = "http://localhost:5000/api/"
    
    private static let baseURLOverrideKey = "com.chatter.baseURLOverride"
    
    static var baseURL: String {
        get {
            UserDefaults.standard.string(forKey: baseURLOverrideKey) ?? defaultBaseURL
        }
        set {
            if newValue.isEmpty || newValue == defaultBaseURL {
                UserDefaults.standard.removeObject(forKey: baseURLOverrideKey)
            } else {
                UserDefaults.standard.set(newValue, forKey: baseURLOverrideKey)
            }
        }
    }
}
