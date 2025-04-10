//
//  ProfileView.swift
//  GithubClient
//
//  Created by BILLY  HO on 2025/4/10.
//

import LocalAuthentication
import SafariServices
import SwiftUI
import UIKit

struct GithubConst {
    static let oauthURL = "https://github.com/login/oauth/authorize"
    static let clientID = "Iv23liZUp1r6aBwzNc7b"
    static let clientSecret = "9568e4e6b2dac1372ae0a9e970ec05770374751e"
    static let callbackURL = "github-client://callback"
}

class ProfileViewModel: ObservableObject {
    @Published var isBiometricAuthAvailable = false
    @Published var isBiometricAuthEnabled = false
    @Published var isLoggingOut = false
    @Published var isAuthenticated = false
    @Published var username = "@username"
    @Published var avatarURL: URL?
    @Published var showSafari = false
    @Published var followersCount = 0
    @Published var followingCount = 0
    @Published var reposCount = 0

    private let context = LAContext()
    private let notificationCenter = NotificationCenter.default

    init() {
        setupNotifications()
        checkBiometricAvailability()
    }

    deinit {
        removeNotifications()
    }

    private func setupNotifications() {
        notificationCenter.addObserver(
            self, selector: #selector(handleLoginSuccess),
            name: NSNotification.Name("LoginSuccessNotification"), object: nil)
    }

    private func removeNotifications() {
        notificationCenter.removeObserver(
            self, name: NSNotification.Name("LoginSuccessNotification"), object: nil)
    }

    @objc func handleLoginSuccess(_ notification: Notification) {
        showSafari = false
        if let token = notification.userInfo?["token"] {
            AuthManager.shared.getUserInfo(
                accessToken: token as! String,
                completion: { [weak self] result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let user):
                            let avatarURL = URL(string: user.avatarUrl)
                            self?.username = "@\(user.login)"
                            self?.avatarURL = avatarURL
                            self?.isAuthenticated = true
                            self?.isBiometricAuthEnabled = true
                            self?.followersCount = user.followers
                            self?.followingCount = user.following
                            self?.reposCount = user.publicRepos
                        case .failure(let error):
                            print("Error getting access token: \(error.localizedDescription)")
                        }
                    }
                })
        }
    }

    func checkBiometricAvailability() {
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAuthAvailable = true
        } else {
            isBiometricAuthAvailable = false
        }
    }

    func authenticateWithBiometrics() {
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "请使用生物识别进行认证"

            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics, localizedReason: reason
            ) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        AuthManager.shared.loginWithBiometrics()
                    } else {
                        print(
                            "Authentication failed: \(authenticationError?.localizedDescription ?? "Unknown error")"
                        )
                    }
                }
            }
        } else {
            print(
                "Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")"
            )
        }
    }

    func handleLoginLogout() {
        if isAuthenticated {
            isLoggingOut = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isAuthenticated = false
                self.isBiometricAuthEnabled = false
                self.avatarURL = nil
                self.username = "@username"
                self.followersCount = 0
                self.followingCount = 0
                self.reposCount = 0
                self.isLoggingOut = false
            }
        } else {
            showSafari = true
        }
    }
}

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                // Profile Image
                AsyncImage(url: viewModel.avatarURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 10)
                } placeholder: {
                    Image("UserIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                }

                // Username
                Text(viewModel.username)
                    .font(.title)
                    .fontWeight(.bold)

                // Stats
                HStack(spacing: 30) {
                    VStack {
                        Text("\(viewModel.followersCount)")
                            .font(.headline)
                        Text(LocalizedStringKey("info.follower"))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    VStack {
                        Text("\(viewModel.followingCount)")
                            .font(.headline)
                        Text(LocalizedStringKey("info.following"))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    VStack {
                        Text("\(viewModel.reposCount)")
                            .font(.headline)
                        Text(LocalizedStringKey("info.repo"))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical)

                // Biometric Authentication
                if viewModel.isBiometricAuthAvailable && !viewModel.isAuthenticated {
                    Button(action: viewModel.authenticateWithBiometrics) {
                        HStack {
                            Image(systemName:"faceid")
                            Text(LocalizedStringKey("biometrics"))
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }

                // Login/Logout Button
                Button(action: viewModel.handleLoginLogout) {
                    HStack {
                        Image(systemName: viewModel.isAuthenticated ? "lock.fill" : "person.fill")
                        Text(viewModel.isAuthenticated ? LocalizedStringKey("logout") : LocalizedStringKey("login"))
                    }
                    .padding()
                    .background(viewModel.isAuthenticated ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isLoggingOut)
            }
            .padding()
            .navigationTitle("tab.profile")
            .sheet(isPresented: $viewModel.showSafari) {
                SafariView(
                    url: URL(
                        string:
                            "\(GithubConst.oauthURL)?client_id=\(GithubConst.clientID)&redirect_uri=\(GithubConst.callbackURL)&scope=user, repo"
                    )!)
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}

#Preview {
    ProfileView()
}
