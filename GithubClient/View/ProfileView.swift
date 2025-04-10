//
//  ProfileView.swift
//  GithubClient
//
//  Created by BILLY  HO on 2025/4/10.
//

import SwiftUI
import LocalAuthentication
import UIKit
import SafariServices

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
        notificationCenter.addObserver(self, selector: #selector(handleLoginSuccess), name: NSNotification.Name("LoginSuccessNotification"), object: nil)
    }
    
    private func removeNotifications() {
        notificationCenter.removeObserver(self, name: NSNotification.Name("LoginSuccessNotification"), object: nil)
    }
    
    @objc func handleLoginSuccess(_ notification: Notification) {
        showSafari = false
        if let token = notification.userInfo?["token"] {
            AuthManager.shared.getUserInfo(accessToken: token as! String, completion: { [weak self] result in
                    switch result {
                    case .success(let user):
                        let avatarURL = URL(string: user.avatarUrl)
                        self?.username = "@\(user.login)"
                        self?.avatarURL = avatarURL
                        self?.isAuthenticated = true
                        self?.isBiometricAuthEnabled = true
                    case .failure(let error):
                        print("Error getting access token: \(error.localizedDescription)")
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
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isBiometricAuthEnabled = true
                        self.isAuthenticated = true
                    } else {
                        print("Authentication failed: \(authenticationError?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func handleLoginLogout() {
        if isAuthenticated {
            isLoggingOut = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isAuthenticated = false
                self.isBiometricAuthEnabled = false
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
                
                // Biometric Authentication
                if viewModel.isBiometricAuthAvailable {
                    Button(action: viewModel.authenticateWithBiometrics) {
                        HStack {
                            Image(systemName: viewModel.isBiometricAuthEnabled ? "checkmark.circle.fill" : "touchid")
                            Text(viewModel.isBiometricAuthEnabled ? "已启用生物识别" : "启用生物识别")
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
                        Image(systemName: viewModel.isLoggingOut ? "lock.fill" : "person.fill")
                        Text(viewModel.isLoggingOut ? "登出" : "登录")
                    }
                    .padding()
                    .background(viewModel.isLoggingOut ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isLoggingOut)
                
                // Authentication Status
                if viewModel.isAuthenticated {
                    Text("已认证")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .navigationTitle("个人主页")
            .sheet(isPresented: $viewModel.showSafari) {
                SafariView(url: URL(string: "\(GithubConst.oauthURL)?client_id=\(GithubConst.clientID)&redirect_uri=\(GithubConst.callbackURL)&scope=user, repo")!)
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
