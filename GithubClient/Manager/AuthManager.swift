//
//  AuthManager.swift
//  GithubClient
//
//  Created by BILLY  HO on 2025/4/10.
//

import Foundation
import KeychainAccess
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

        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let params = comps?.queryItems?.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }

        if let code = params?["code"] {
            print("handleCallback \(code)")
            getAccessToken(
                code: code,
                completion: { [weak self] result in
                    switch result {
                    case .success(let token):
                        print("token \(token)")
                        self?.notifyLogin(token: token)
                    case .failure(let error):
                        print("Error getting access token: \(error.localizedDescription)")

                    }

                })
        }
    }

    func loginWithBiometrics() {
        // Try to get token from keychain
        let keychain = Keychain(service:"billyho.GithubClient")
        print("\(keychain)")
        if let token = keychain["GithubClientAccessToken"] {
            notifyLogin(token: token)
        } else {
            print("login fail")
        }
    }

    func notifyLogin(token: String) {
        let notiName = NSNotification.Name(rawValue: "LoginSuccessNotification")
        NotificationCenter.default.post(name: notiName, object: nil, userInfo: ["token": token])
    }

    func getAccessToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        // GitHub OAuth token endpoint
        guard let url = URL(string: "https://github.com/login/oauth/access_token") else {
            completion(.failure(AuthError.invalidURL))
            return
        }

        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Request body
        let parameters =
            "client_id=\(githubClientID)&client_secret=\(githubClientSecret)&code=\(code)&redirect_uri=\(redirectURI)"
        request.httpBody = parameters.data(using: .utf8)

        // Create data task
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network error
            if let error = error {
                completion(.failure(error))
                return
            }

            // Check response
            guard let data = data,
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                completion(.failure(AuthError.invalidResponse))
                return
            }

            // Decode response
            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                // Save token to keychain
                completion(.success(tokenResponse.accessToken))
            } catch {
                completion(.failure(error))
            }
        }.resume()  // Start the task
    }

    func getUserInfo(accessToken: String, completion: @escaping (Result<User, Error>) -> Void) {
        // GitHub API endpoint
        guard let url = URL(string: "https://api.github.com/user") else {
            completion(.failure(AuthError.invalidURL))
            return
        }

        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")

        // Create data task
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network error
            if let error = error {
                completion(.failure(error))
                return
            }

            // Check response
            guard let data = data,
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                completion(.failure(AuthError.invalidResponse))
                return
            }

            // Decode response
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                let keychain = Keychain(service:"billyho.GithubClient")
                keychain["GithubClientAccessToken"] = accessToken
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
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

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

enum AuthError: LocalizedError {
    case invalidURL
    case missingCode
    case invalidResponse
    case networkError
    case keychainError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .missingCode:
            return "Missing authorization code"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError:
            return "Network error occurred"
        case .keychainError:
            return "Failed to save token to keychain"
        }
    }
}
