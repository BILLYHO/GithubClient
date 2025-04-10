//
//  HomeView.swift
//  GithubClient
//
//  Created by BILLY  HO on 2025/4/10.
//

import SwiftUI

struct Repository: Identifiable, Codable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let owner: Owner
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case description
        case owner
    }
}

struct Owner: Codable {
    let login: String
    let avatarUrl: String
    
    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}


struct HomeView: View {
    @State private var searchText = ""
    @State private var repositories: [Repository] = []
    @State private var isLoading = false
    
    var filteredRepositories: [Repository] {
        if searchText.isEmpty {
            return repositories
        }
        return repositories.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                
                    List(filteredRepositories) { repository in
                        RepositoryRow(repository: repository)
                    }
                    .refreshable {
                        await loadRepositories()
                    }
                    .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle(LocalizedStringKey("tab.home"))
            .task {
                await loadRepositories()
            }
        }
    }
    
    private func loadRepositories() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "https://api.github.com/repositories") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            repositories = try JSONDecoder().decode([Repository].self, from: data)
        } catch {
            print("Error loading repositories: \(error)")
        }
    }
}

struct RepositoryRow: View {
    let repository: Repository
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AsyncImage(url: URL(string: repository.owner.avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 30, height: 30)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(repository.owner.login)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(repository.name)
                        .font(.headline)
                }
            }
            
            if let description = repository.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField(LocalizedStringKey("home.search"), text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 8)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    HomeView()
}
