//
//  ContentView.swift
//  AppleLiquidGlassTapBar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Shared Background Color Manager
class BackgroundColorManager: ObservableObject {
    @Published var selectedColor: Int = 0 // Default to Ocean
    
    static let shared = BackgroundColorManager()
    
    private init() {}
    
    func getBackgroundColors() -> [(name: String, gradient: LinearGradient)] {
        return [
            ("Ocean", LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue,
                    Color.cyan,
                    Color.teal
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )),
            ("Sunset", LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange,
                    Color.pink,
                    Color.purple
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )),
            ("Forest", LinearGradient(
                gradient: Gradient(colors: [
                    Color.green,
                    Color.mint,
                    Color.blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )),
            ("Lavender", LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple,
                    Color.indigo,
                    Color.blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )),
            ("Classic", LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.blue,
                    Color.purple
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        ]
    }
}

struct ContentView: View {
    @State private var searchText = ""
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0 // Default to Ocean
    @State private var showWelcomeModal = true
    @StateObject private var backgroundManager = BackgroundColorManager.shared

    init() {
        #if canImport(UIKit)
        // Configure a translucent, glass-like background for the tab bar using blur,
        // because UITabBarAppearance.backgroundEffect expects a UIBlurEffect.
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = true
        tabBar.unselectedItemTintColor = UIColor.lightGray
        #endif
    }

    var body: some View {
        ZStack {
            // Simple blue background
            Color.blue
                .ignoresSafeArea(.all)
            
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
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                showWelcomeModal = true
            }
            .sheet(isPresented: $showWelcomeModal) {
                WelcomeModalView(isDarkMode: isDarkMode) {
                    showWelcomeModal = false
                }
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(16)
                .interactiveDismissDisabled(false)
            }
        }
    }
}

// MARK: - Individual Views
struct HomeView: View {
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0
    
    @StateObject private var backgroundManager = BackgroundColorManager.shared
    
    private var backgroundColors: [(name: String, gradient: LinearGradient)] {
        backgroundManager.getBackgroundColors()
    }
    
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
                        
                        Text("Background: \(backgroundColors[selectedBackgroundColor].name)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
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
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0

    @StateObject private var backgroundManager = BackgroundColorManager.shared

    private var backgroundColors: [(name: String, gradient: LinearGradient)] {
        backgroundManager.getBackgroundColors()
    }
    
    var body: some View {
        ZStack {
            // Apply selected background color
            backgroundColors[selectedBackgroundColor].gradient
                .ignoresSafeArea()
            
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
}

struct PlanView: View {
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0

    @StateObject private var backgroundManager = BackgroundColorManager.shared

    private var backgroundColors: [(name: String, gradient: LinearGradient)] {
        backgroundManager.getBackgroundColors()
    }
    
    var body: some View {
        ZStack {
            // Apply selected background color
            backgroundColors[selectedBackgroundColor].gradient
                .ignoresSafeArea()
            
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
}

struct ProfileView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0 // Default to Ocean
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var backgroundManager = BackgroundColorManager.shared
    
    // Use shared background colors
    private var backgroundColors: [(name: String, gradient: LinearGradient)] {
        backgroundManager.getBackgroundColors()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                    // Profile info card
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
                    
                    // Settings card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .foregroundStyle(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Appearance")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("Choose your preferred theme")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isDarkMode)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
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
                    
                    // Background color picker card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .foregroundStyle(.green)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Background Theme")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("Choose your favorite color")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // Color picker grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(0..<backgroundColors.count, id: \.self) { index in
                                ColorOptionView(
                                    name: backgroundColors[index].name,
                                    gradient: backgroundColors[index].gradient,
                                    isSelected: selectedBackgroundColor == index,
                                    action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedBackgroundColor = index
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
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
                    
                    // Additional settings cards
                    VStack(spacing: 12) {
                        SettingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Manage your alerts")
                        SettingsRow(icon: "lock.fill", title: "Privacy", subtitle: "Control your data")
                        SettingsRow(icon: "gear", title: "General", subtitle: "App preferences")
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.top, 20)
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct ColorOptionView: View {
    let name: String
    let gradient: LinearGradient
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Color preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(gradient)
                    .frame(height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color.blue : Color.clear,
                                lineWidth: isSelected ? 3 : 0
                            )
                    )
                    .overlay(
                        Group {
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title3)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                        }
                    )
                
                // Color name
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct SearchTabContent: View {
    var searchText: String
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0

    @StateObject private var backgroundManager = BackgroundColorManager.shared

    private var backgroundColors: [(name: String, gradient: LinearGradient)] {
        backgroundManager.getBackgroundColors()
    }

    var body: some View {
        ZStack {
            // Apply selected background color
            backgroundColors[selectedBackgroundColor].gradient
                .ignoresSafeArea()
            
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
}

// MARK: - Welcome Modal
struct WelcomeModalView: View {
    let isDarkMode: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Video container - fills the container
                ZStack {
                    // Background image
                    AsyncImage(url: URL(string: "https://plus.unsplash.com/premium_photo-1752782188828-6bff4fe86c4e?q=80&w=2664&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(.quaternary)
                    }
                    .frame(height: 200)
                    .clipped()
                    
                    // Play button with authentic Apple Liquid Glass effect
                    Button(action: {}) {
                        ZStack {
                            // Liquid Glass material with proper translucency
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 80, height: 80)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.2), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                                .shadow(color: .white.opacity(0.15), radius: 2, x: 0, y: -1)
                            
                            // Play icon with high contrast white
                            Image(systemName: "play.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                                .offset(x: 2)
                        }
                    }
                }
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Add 16px padding between video and text
                        Spacer()
                            .frame(height: 16)
                        
                        // Description section
                        VStack(spacing: 16) {
                            Text("Title")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("Aenean pharetra, erat id malesuada iaculis, mauris tortor dictum ligula, dapibus faucibus odio est id arcu. Proin metus justo, mattis eu lacus a, accumsan sodales tellus.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                            
                            // Page indicators
                            HStack(spacing: 8) {
                                ForEach(0..<5) { index in
                                    Circle()
                                        .fill(index == 0 ? Color.blue : Color.gray.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                    }
                }
                
                // Footer with button
                VStack(spacing: 0) {
                    Divider()
                    
                    Button(action: onDismiss) {
                        Text("CTA")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(.regularMaterial)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Extension for corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
