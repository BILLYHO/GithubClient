//
//  GithubClientApp.swift
//  GithubClient
//
//  Created by BILLY  HO on 2025/4/10.
//

import SwiftUI

@main
struct GithubClientApp: App {

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label(LocalizedStringKey("tab.home"), systemImage: "house.fill")
                    }
                ProfileView()
                    .tabItem {
                        Label(LocalizedStringKey("tab.profile"), systemImage: "person.fill")
                    }
            }.onOpenURL { url in
                print("Received URL: \(url)")
                if url.absoluteString.starts(with: AuthManager.shared.redirectURI) {
                    AuthManager.shared.handleCallback(url: url)
                }
              }
        }
    }
}


