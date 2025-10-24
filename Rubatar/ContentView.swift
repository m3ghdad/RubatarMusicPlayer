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
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    // MARK: - State Variables
    @State private var searchText = ""
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("didInitializeTheme") private var didInitializeTheme = false
    @State private var showWelcomeModal = false
    @Environment(\.colorScheme) private var systemColorScheme
    
    // MARK: - Content Management
    @StateObject private var contentManager = ContentManager()
    @State private var showMiniPlayer = false
    @State private var showCard = false
    @State private var showVideoPlayer = false
    @State private var isTabBarMinimized = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showEnhancedPlayer = false
    @State private var shouldShowMiniPlayer = false
    @State private var showProfileSheet = false
    @State private var playerOpenedFrom: PlayerSource = .none
    @StateObject private var audioPlayer = AudioPlayer()
    @Namespace private var animation
    @State private var showLearnMore = false
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    
    enum PlayerSource {
        case none
        case playlistCard
        case miniPlayer
    }
    
    // MARK: - Video Configuration
    private let videoURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
    @State private var player: AVPlayer?

    init() {
        configureTabBarAppearance()
    }

    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea(.all)
            
            TabView {
        Tab {
                    HomeView(
                        showCard: $showCard,
                        showWelcomeModal: $showWelcomeModal,
                        showVideoPlayer: $showVideoPlayer,
                        isTabBarMinimized: $isTabBarMinimized,
                        scrollOffset: $scrollOffset,
                        onMusicSelected: playSelectedTrack,
                        onPlaylistSelected: playSelectedPlaylist,
                        showProfileSheet: $showProfileSheet
                    )
                    .environmentObject(contentManager)
                } label: {
                    Label {
                        Text("Home")
                            .font(.custom("Palatino", size: 10))
                    } icon: {
                        Image(systemName: "music.note.house.fill")
                    }
                }

                /*
                Tab("Music", systemImage: "music.note") {
                    MusicView(
                        showCard: $showCard,
                        showWelcomeModal: $showWelcomeModal,
                        showVideoPlayer: $showVideoPlayer,
                        isTabBarMinimized: $isTabBarMinimized,
                        scrollOffset: $scrollOffset,
                        onMusicSelected: playSelectedTrack,
                        onPlaylistSelected: playSelectedPlaylist,
                        showProfileSheet: $showProfileSheet
                    )
                }
                */

                /*
                Tab("Favorites", systemImage: "heart") {
                    PlanView()
                }
                */

                Tab("Rubatar", systemImage: "apple.books.pages.fill") {
                    ProfileView()
                }

                Tab("Search", systemImage: "magnifyingglass", role: .search) {
                    NavigationStack {
                        SearchTabContent(searchText: searchText)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search")
            .tint(isDarkMode ? Color(hex: "E3B887") : Color(hex: "7A5C39"))
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .tabBarMinimizeBehavior(.onScrollDown)
            .tabViewBottomAccessory {
                miniPlayerView
            }
            .onAppear {
                // Initialize app theme to match system on first launch
                if !didInitializeTheme {
                    isDarkMode = (systemColorScheme == .dark)
                    didInitializeTheme = true
                }
                // Present welcome after a tick so updated color scheme propagates to the sheet
                if !hasSeenWelcome {
                    DispatchQueue.main.async {
                        showWelcomeModal = true
                    }
                }
            }
            .sheet(isPresented: $showWelcomeModal) {
                welcomeModalView
            }
            
            // Enhanced Music Player Overlay
            if showEnhancedPlayer {
                EnhancedMusicPlayer(
                    show: $showEnhancedPlayer,
                    hideMiniPlayer: .constant(false),
                    animation: animation
                )
                .environmentObject(audioPlayer)
                .environmentObject(contentManager)
                .zIndex(1000)
                .transition(getPlayerTransition())
            }
        }
        .onAppear { initializeVideoPlayer() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowWelcomeLearnMore"))) { _ in
            showLearnMore = true
        }
        .onChange(of: showEnhancedPlayer) { oldValue, newValue in
            if oldValue == true && newValue == false {
                // Dismissing - use snappy animation with no bounce
                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                    handleEnhancedPlayerDismissal(oldValue: oldValue, newValue: newValue)
                }
            } else {
                handleEnhancedPlayerDismissal(oldValue: oldValue, newValue: newValue)
            }
            
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            videoPlayerView
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileBottomSheet(isPresented: $showProfileSheet)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(16)
        }
        .sheet(isPresented: $showLearnMore) {
            AboutRubatarModalView(
                isDarkMode: isDarkMode,
                onButtonDismiss: { showLearnMore = false },
                skipFirstPage: true
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(16)
        }
        
    }
    
    // MARK: - Computed Views
    @ViewBuilder
    private var miniPlayerView: some View {
        // Always show mini player if user has ever played a track
        if audioPlayer.hasPlayedTrack && !showEnhancedPlayer {
            PlayBackView(
                onTap: { 
                    playerOpenedFrom = .miniPlayer
                    // Animate the transition to enhanced player with zoom effect
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showEnhancedPlayer = true
                    }
                    shouldShowMiniPlayer = true
                },
                onPlayPause: { audioPlayer.togglePlayPause() },
                onNext: { audioPlayer.playNextTrack() },
                currentTrack: audioPlayer.currentTrack,
                currentArtist: audioPlayer.currentArtist,
                currentArtwork: audioPlayer.currentArtwork,
                isPlaying: audioPlayer.isPlaying,
                isLoading: audioPlayer.isLoadingTrack
            )
            .padding(.vertical, 8)
            .onChange(of: isTabBarMinimized) { _, newValue in
                print("🎛️ Mini player - Tab bar minimized: \(newValue)")
            }
        }
    }
    
    @ViewBuilder
    private var welcomeModalView: some View {
            AboutRubatarModalView(
                isDarkMode: (systemColorScheme == .dark),
            onButtonDismiss: {
                showWelcomeModal = false
                hasSeenWelcome = true
            },
            skipFirstPage: false
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(16)
        .interactiveDismissDisabled(false)
        .onAppear {
            showMiniPlayer = false
            showCard = false
        }
    }
    
    @ViewBuilder
    private var videoPlayerView: some View {
        if let player = player {
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .onAppear { player.play() }
                .onDisappear { player.pause() }
        }
    }
    
    // MARK: - Private Methods
    private func configureTabBarAppearance() {
        #if canImport(UIKit)
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
    
    private func initializeVideoPlayer() {
        player = AVPlayer(url: videoURL)
    }
    
    private func handleEnhancedPlayerDismissal(oldValue: Bool, newValue: Bool) {
        if oldValue == true && newValue == false && shouldShowMiniPlayer {
            showMiniPlayer = true
            shouldShowMiniPlayer = false
        }
    }
    
    private func getPlayerTransition() -> AnyTransition {
        switch playerOpenedFrom {
        case .playlistCard:
            // Scale to center of screen (where card would be)
            return .scale(scale: 0.3).combined(with: .opacity)
        case .miniPlayer:
            // Scale to bottom (where mini player is)
            return .asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.1, anchor: .bottom).combined(with: .opacity)
            )
        case .none:
            return .scale(scale: 0.8).combined(with: .opacity)
        }
    }
    
    // MARK: - Music Control Functions
    private func playSelectedTrack(track: String, artist: String, artwork: URL?) {
        audioPlayer.playSelectedTrack(track: track, artist: artist, artwork: artwork)
        showMiniPlayer = true
        provideHapticFeedback()
        print("🎵 Now playing: \(track) by \(artist)")
    }
    
    private func playSelectedPlaylist(playlistId: String, playlistTitle: String, curatorName: String, artwork: URL?) {
        audioPlayer.playSelectedPlaylist(
            playlistId: playlistId,
            playlistTitle: playlistTitle,
            curatorName: curatorName,
            artwork: artwork
        )
        showMiniPlayer = true
        playerOpenedFrom = .playlistCard
        
        // Animate the transition to enhanced player with zoom effect
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showEnhancedPlayer = true
        }
        
        provideHapticFeedback()
        print("🎶 Now playing playlist: \(playlistTitle) by \(curatorName)")
    }
    
    private func provideHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

#if canImport(UIKit)
// Transparent background helper to remove sheet chrome so content can show through
struct TransparentBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
#else
struct TransparentBackgroundView: View { var body: some View { Color.clear } }
#endif
#Preview {
    ContentView()
}