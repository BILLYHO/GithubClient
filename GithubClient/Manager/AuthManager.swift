//
//  AuthManager.swift
//  GithubClient
//
//  Created by BILLY  HO on 2025/4/10.
//

import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var isLoading = false
    
    let githubClientID = "Iv23liZUp1r6aBwzNc7b"
    let githubClientSecret = "9568e4e6b2dac1372ae0a9e970ec05770374751e"
    let redirectURI = "github-client://callback"
    let scopes = "user,repo"
    
    private init() {}
    
    
    
    func handleCallback(url: URL) {
        
        
        let comps = URLComponents(url:url, resolvingAgainstBaseURL: false)
        let params = comps?.queryItems?.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
        
        if let code = params?["code"] {
            print("handleCallback \(code)")
            let notiName = NSNotification.Name(rawValue: "LoginSuccessNotification");
            NotificationCenter.default.post(name:notiName , object: nil, userInfo: ["code": code])
        }
    }
    
//    func logout() {
//        user = nil
//        isAuthenticated = false
//        // Clear any stored tokens or credentials
//    }
//    
}

struct User: Codable, Identifiable {
    let id: Int
    let login: String
    let avatarUrl: String
    let name: String?
    let bio: String?
    let location: String?
    let email: String?
    let followers: Int
    let following: Int
    let publicRepos: Int
    let publicGists: Int
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarUrl = "avatar_url"
        case name
        case bio
        case location
        case email
        case followers
        case following
        case publicRepos = "public_repos"
        case publicGists = "public_gists"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
    }
}

enum AuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
