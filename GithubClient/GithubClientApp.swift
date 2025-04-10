//
//  GithubClientApp.swift
//  GithubClient
//
//  Created by BILLY  HO on 2025/4/10.
//

import SwiftUI

@main
struct GithubClientApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.colorScheme) private var systemColorScheme

    init() {
        // 应用启动时读取系统的深色模式设置
        isDarkMode = systemColorScheme == .dark
        print("\(systemColorScheme)")
    }

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
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onOpenURL { url in
                print("Received URL: \(url)")
                if url.absoluteString.starts(with: AuthManager.shared.redirectURI) {
                    AuthManager.shared.handleCallback(url: url)
                }
            }
        }
    }
}
