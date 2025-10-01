//
//  ContentView.swift
//  AppleLiquidGlassTapBar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import SwiftUI

struct ContentView: View {
    @State private var searchText = ""

    var body: some View {
        ZStack {
            // Background gradient for liquid glass effect
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.1),
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Native TabView following Apple HIG
            TabView {
                Tab("Home", systemImage: "house") {
                    HomeView()
                }

                Tab("Trips", systemImage: "airplane") {
                    TripsView()
                }

                Tab("Plan", systemImage: "calendar") {
                    PlanView()
                }

                Tab("Profile", systemImage: "person.circle") {
                    ProfileView()
                }

                Tab("Search", systemImage: "magnifyingglass", role: .search) {
                    NavigationStack {
                        SearchTabContent(searchText: searchText)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search")
            .tint(.blue) // System accent color
        }
    }
}

// MARK: - Individual Views
struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Liquid glass card
                VStack(spacing: 16) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    Text("Home")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("Welcome to your home screen")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SearchView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Liquid glass card
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                    Text("Search")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("Find what you're looking for")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct TripsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Liquid glass card
                VStack(spacing: 16) {
                    Image(systemName: "airplane")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                    Text("Trips")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("Your travel adventures")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Trips")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct PlanView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Liquid glass card
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 50))
                        .foregroundStyle(.purple)
                    Text("Plan")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("Plan your next adventure")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Liquid glass card
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.pink)
                    Text("Profile")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("Your personal space")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SearchTabContent: View {
    var searchText: String

    var body: some View {
        List {
            if searchText.isEmpty {
                Section("Quick Actions") {
                    Label("Explore destinations", systemImage: "globe")
                    Label("Find nearby", systemImage: "location")
                }
                Section("Recent searches") {
                    Text("No recent searches")
                        .foregroundColor(.secondary)
                }
            } else {
                Section("Results") {
                    Text("Results for \"\(searchText)\"")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    ContentView()
}
