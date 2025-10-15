//
//  ContentView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import SwiftUI
import AVKit
import AVFoundation
import MusicKit

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
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
    @State private var showMiniPlayer = false // Track mini player visibility
    @State private var showCard = false // Track card visibility
    @State private var dismissedByDrag = false // Track if dismissed by drag vs button
    @State private var showVideoPlayer = false // Track video player presentation
    @State private var isTabBarMinimized = false // Track tab bar minimize state
    @State private var scrollOffset: CGFloat = 0 // Track scroll position
    @State private var showEnhancedPlayer = false // Track enhanced player visibility
    @State private var hideMiniPlayer = false // Track mini player hide state
    @StateObject private var backgroundManager = BackgroundColorManager.shared
    @StateObject private var audioPlayer = AudioPlayer()
    
    // Sample video URL - replace with your actual video content
    private let videoURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
    @State private var player: AVPlayer?

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
            HomeView(showCard: $showCard, showWelcomeModal: $showWelcomeModal, showVideoPlayer: $showVideoPlayer, isTabBarMinimized: $isTabBarMinimized, scrollOffset: $scrollOffset)
        }

                Tab("Music", systemImage: "music.note") {
                    MusicView(showCard: $showCard, showWelcomeModal: $showWelcomeModal, showVideoPlayer: $showVideoPlayer, isTabBarMinimized: $isTabBarMinimized, scrollOffset: $scrollOffset, onMusicSelected: playSelectedTrack, onPlaylistSelected: playSelectedPlaylist)
                }

                Tab("Plan", systemImage: "heart") {
                    PlanView()
                }

                Tab("Messages", systemImage: "message") {
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
            .tabBarMinimizeBehavior(.onScrollDown)
            .tabViewBottomAccessory {
                if showMiniPlayer {
                    PlayBackView(
                        onTap: {
                            // Open enhanced player instead of just toggling play/pause
                            showEnhancedPlayer = true
                        },
                        onNext: {
                            audioPlayer.playNextTrack()
                        },
                        currentTrack: audioPlayer.currentTrack,
                        currentArtist: audioPlayer.currentArtist,
                        currentArtwork: audioPlayer.currentArtwork,
                        isPlaying: audioPlayer.isPlaying
                    )
                    .padding(.vertical, 8)
                    .onChange(of: isTabBarMinimized) { oldValue, newValue in
                        print("🎛️ Mini player - Tab bar minimized: \(newValue)")
                    }
                }
            }
            .onAppear {
                showWelcomeModal = true
            }
            .sheet(isPresented: $showWelcomeModal, onDismiss: {
                // Reset flag - mini player is now controlled by music selection
                dismissedByDrag = false
            }) {
                WelcomeModalView(isDarkMode: isDarkMode, onButtonDismiss: {
                    // This is called when "Learn more" button is tapped
                    dismissedByDrag = false
                    showWelcomeModal = false
                    // Don't show mini player when dismissed via button
                }, onPlayTapped: {
                    // Open video player when play button is tapped
                    showVideoPlayer = true
                })
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(16)
                .interactiveDismissDisabled(false)
                .onAppear {
                    showMiniPlayer = false // Hide mini player when modal appears
                    showCard = false // Hide card when modal appears
                    dismissedByDrag = true // Assume drag dismissal unless button is pressed
                }
            }
            
            // Enhanced Music Player Overlay
            if showEnhancedPlayer {
                EnhancedMusicPlayer(
                    show: $showEnhancedPlayer,
                    hideMiniPlayer: $hideMiniPlayer
                )
                .environmentObject(audioPlayer)
                .zIndex(1000)
            }
            
        }
        .onAppear {
            // Initialize player when ContentView appears
            player = AVPlayer(url: videoURL)
            //player?.allowsExternalPlayback = false
        }
        // Video Player Presentation
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let player = player {
                
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        // Auto-play when video player appears
                        player.play()
                    }
                    .onDisappear {
                        // Pause when video player disappears
                        player.pause()
                    }
                
            }
        }
    }
    
    // MARK: - Music Control Functions
    func playSelectedTrack(track: String, artist: String, artwork: URL?) {
        audioPlayer.playSelectedTrack(track: track, artist: artist, artwork: artwork)
        showMiniPlayer = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("🎵 Now playing: \(track) by \(artist)")
    }
    
    func playSelectedPlaylist(playlistId: String, playlistTitle: String, curatorName: String, artwork: URL?) {
        audioPlayer.playSelectedPlaylist(playlistId: playlistId, playlistTitle: playlistTitle, curatorName: curatorName, artwork: artwork)
        showMiniPlayer = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("🎶 Now playing playlist: \(playlistTitle) by \(curatorName)")
    }
}

// Reusable avatar button view
struct AvatarButtonView: View {
    var body: some View {
        Button(action: {
            // TODO: Handle avatar tap (e.g., navigate to profile)
        }) {
            // Profile image avatar; replace the URL with your user's avatar
            AsyncImage(url: URL(string: "https://i.ibb.co/TDWzY83h/IMG-3079.jpgformat&fit=crop")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_):
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                        .foregroundColor(.secondary)
                        .background(Color.secondary.opacity(0.15))
                case .empty:
                    ZStack {
                        Color.secondary.opacity(0.1)
                        ProgressView()
                    }
                @unknown default:
                    Color.secondary.opacity(0.1)
                }
            }
            .frame(width: 34, height: 34)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
            .accessibilityLabel("Profile")
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Individual Views
struct HomeView: View {
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0
    @Binding var showCard: Bool
    @Binding var showWelcomeModal: Bool
    @Binding var showVideoPlayer: Bool
    @Binding var isTabBarMinimized: Bool
    @Binding var scrollOffset: CGFloat
    
    @State private var lastScrollOffset: CGFloat = 0
    
    @StateObject private var backgroundManager = BackgroundColorManager.shared
    
    private var backgroundColors: [(name: String, gradient: LinearGradient)] {
        backgroundManager.getBackgroundColors()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text("Home")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        AvatarButtonView()
                    }
                    .padding(.horizontal, 16)
                    if showCard {
                        VideoCardView(onPlayTapped: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                showCard = false
                                showVideoPlayer = true
                            }
                        })
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    
                    // Browse Collections Section
                    BrowseCollectionsSection()
                    // Removed .padding(.horizontal, 16) here
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
                .padding(.horizontal, 16)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .global).minY)
                    }
                )
            }
            .scrollIndicators(.hidden)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                let delta = value - lastScrollOffset
                scrollOffset = value

                // Small changes are noise; ignore them to avoid flicker
                if abs(delta) <= 2 { return }

                print("🏠 HomeView scroll - delta: \(delta), isTabBarMinimized: \(isTabBarMinimized)")

                withAnimation(.easeInOut(duration: 0.25)) {
                    if delta < 0 {
                        // Scrolling down -> minimize tab bar
                        isTabBarMinimized = true
                        print("🏠 HomeView - Minimizing tab bar")
                    } else {
                        // Scrolling up -> expand tab bar
                        isTabBarMinimized = false
                        print("🏠 HomeView - Expanding tab bar")
                    }
                }

                lastScrollOffset = value
            }
            .navigationBarHidden(true)
        }
    }
}

struct MusicView: View {
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0
    @Binding var showCard: Bool
    @Binding var showWelcomeModal: Bool
    @Binding var showVideoPlayer: Bool
    @Binding var isTabBarMinimized: Bool
    @Binding var scrollOffset: CGFloat
    let onMusicSelected: (String, String, URL?) -> Void
    let onPlaylistSelected: (String, String, String, URL?) -> Void
    
    @State private var lastScrollOffset: CGFloat = 0
    
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
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Music")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Spacer()
                            AvatarButtonView()
                        }
                        .padding(.horizontal, 16)
                        
                        // Music Section
                        MusicSectionView(
                            onMusicSelected: { track, artist, artwork in
                                onMusicSelected(track, artist, artwork)
                            },
                            onPlaylistSelected: { playlistId, playlistTitle, curatorName, artwork in
                                onPlaylistSelected(playlistId, playlistTitle, curatorName, artwork)
                            }
                        )
                        
                        // Add some extra content to ensure scrolling
                        VStack(spacing: 20) {
                            ForEach(0..<5) { index in
                                VStack(spacing: 12) {
                                    Text("Music Category \(index + 1)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text("This is additional content to make sure the Music tab is scrollable and the mini player behavior works correctly.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.regularMaterial)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .global).minY)
                        }
                    )
                }
                .scrollIndicators(.hidden)
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    let delta = value - lastScrollOffset
                    scrollOffset = value

                    // Small changes are noise; ignore them to avoid flicker
                    if abs(delta) <= 2 { return }

                    print("🎵 MusicView scroll - delta: \(delta), isTabBarMinimized: \(isTabBarMinimized)")

                    withAnimation(.easeInOut(duration: 0.25)) {
                        if delta < 0 {
                            // Scrolling down -> minimize tab bar
                            isTabBarMinimized = true
                            print("🎵 MusicView - Minimizing tab bar")
                        } else {
                            // Scrolling up -> expand tab bar
                            isTabBarMinimized = false
                            print("🎵 MusicView - Expanding tab bar")
                        }
                    }

                    lastScrollOffset = value
                }
                .navigationBarHidden(true)
            }
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
                    HStack {
                        Text("Trips")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        AvatarButtonView()
                    }
                    .padding(.horizontal, 20)
                    
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
                .navigationBarHidden(true)
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
                    HStack {
                        Text("Plan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        AvatarButtonView()
                    }
                    .padding(.horizontal, 20)
                    
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
                .navigationBarHidden(true)
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
                HStack {
                    Text("Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    AvatarButtonView()
                }
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
                .navigationBarHidden(true)
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
        .buttonStyle(.plain)
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

    @Environment(\.isSearching) private var isSearching

    var body: some View {
        ZStack {
            // Apply selected background color
            backgroundColors[selectedBackgroundColor].gradient
                .ignoresSafeArea()
            
            List {
                if !isSearching {
                    HStack {
                        Text("Search")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        AvatarButtonView()
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
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
        }
    }
}

// MARK: - Mini Music Player
struct PlayBackView: View {
    let onTap: () -> Void
    let onNext: () -> Void
    let currentTrack: String
    let currentArtist: String
    let currentArtwork: URL?
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Album artwork
            AsyncImage(url: currentArtwork) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            .frame(width: 32, height: 32)
            .cornerRadius(8)
            .clipped()
            
            // Content info - expanded container
            VStack(alignment: .leading, spacing: 2) {
                Text(currentTrack)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(currentArtist)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Control buttons
            HStack(spacing: 8) {
                // Play/Pause button
                Button(action: onTap) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                // Next track button
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.separator, lineWidth: 0.5)
                )
        )
    }
}


// MARK: - Welcome Modal
struct WelcomeModalView: View {
    let isDarkMode: Bool
    let onButtonDismiss: () -> Void
    let onPlayTapped: () -> Void
    
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
                    
                    // Play button with Apple's official Glass Effect
                    Button(action: onPlayTapped) {
                        ZStack {
                            // Base circle with glass effect
                            Circle()
                                .fill(.clear)
                                .frame(width: 80, height: 80)
                                .glassEffect(in: Circle())
                            
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
                    
                    Button(action: onButtonDismiss) {
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

// MARK: - Video Card View
struct VideoCardView: View {
    let onPlayTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Video thumbnail with play button
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
                .frame(height: 180)
                .clipShape(
                    .rect(
                        topLeadingRadius: 12,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 12
                    )
                )
                
                // Play button with Apple's official Glass Effect
                Button(action: onPlayTapped) {
                    ZStack {
                        // Base circle with glass effect
                        Circle()
                            .fill(.clear)
                            .frame(width: 60, height: 60)
                            .glassEffect(in: Circle())
                        
                        // Play icon with high contrast white
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .offset(x: 1)
                    }
                }
            }
            
            // Content section
            VStack(alignment: .leading, spacing: 4) {
                Text("CardTitle")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Aenean pharetra, erat id malesuada iaculis, mauris tortor dictum ligula.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 16)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.separator, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .cornerRadius(12)
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

// MARK: - Browse Collections Section
struct BrowseCollectionsSection: View {
    let collections = [
        CollectionItem(
            badge: "New",
            title: "Nature Escapes",
            description: "Discover breathtaking landscapes and serene natural beauty",
            imageName: "forest",
            color: .green
        ),
        CollectionItem(
            badge: "Popular",
            title: "Urban Adventures",
            description: "Explore vibrant cityscapes and modern architecture",
            imageName: "building.2",
            color: .blue
        ),
        CollectionItem(
            badge: "Featured",
            title: "Ocean Views",
            description: "Immerse yourself in stunning coastal and marine scenes",
            imageName: "water.waves",
            color: .cyan
        ),
        CollectionItem(
            badge: "Trending",
            title: "Mountain Peaks",
            description: "Experience majestic mountain ranges and alpine vistas",
            imageName: "mountain.2",
            color: .orange
        ),
        CollectionItem(
            badge: "Editor's Pick",
            title: "Desert Landscapes",
            description: "Journey through vast deserts and golden dunes",
            imageName: "sun.max",
            color: .yellow
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            VStack(alignment: .leading, spacing: 8) {
                Text("SectionTitle")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Lectus sed pellentesque faucibus, urna lectus rutrum lorem, sit amet mattis orci lorem pretium nisl.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(16)
            
            // Vertical Collection Cards
            VStack(spacing: 16) {
                ForEach(collections, id: \.title) { collection in
                    CollectionCard(collection: collection)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct CollectionCard: View {
    let collection: CollectionItem
    
    var body: some View {
        ZStack {
            // Background image/content area
            if collection.title == "Nature Escapes" {
                // Use AsyncImage for Nature Escapes
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1618005198919-d3d4b5a92ead?q=80&w=2748&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    collection.color.opacity(0.4),
                                    collection.color.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(height: 280)
            } else {
                // Use gradient for other cards
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                collection.color.opacity(0.4),
                                collection.color.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 280)
                
                // SF Symbol as subtle background decoration
                Image(systemName: collection.imageName)
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.15))
                    .offset(x: 15, y: -10)
            }
            
            VStack(spacing: 0) {
                // Top section with badge
                HStack {
                    // Badge
                    Text(collection.badge)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.black.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.white.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Bottom overlay with content
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                    
                    Text(collection.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [
                            .clear,
                            .black.opacity(0.4),
                            .black.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

struct CollectionItem {
    let badge: String
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

#Preview {
    ContentView()
}
