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
    @State private var showWelcomeModal = true
    @State private var showMiniPlayer = false
    @State private var showCard = false
    @State private var showVideoPlayer = false
    @State private var isTabBarMinimized = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showEnhancedPlayer = false
    @State private var shouldShowMiniPlayer = false
    @State private var showProfileSheet = false
    @StateObject private var audioPlayer = AudioPlayer()
    @Namespace private var animation
    
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
                } label: {
                    Label {
                        Text("Home")
                            .font(.custom("Palatino", size: 10))
                    } icon: {
                        Image(systemName: "house")
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
            .onAppear { showWelcomeModal = true }
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
                .zIndex(1000)
            }
        }
        .onAppear { initializeVideoPlayer() }
        .onChange(of: showEnhancedPlayer) { oldValue, newValue in
            handleEnhancedPlayerDismissal(oldValue: oldValue, newValue: newValue)
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
    }
    
    // MARK: - Computed Views
    @ViewBuilder
    private var miniPlayerView: some View {
        // Always show mini player if user has ever played a track
        if audioPlayer.hasPlayedTrack && !showEnhancedPlayer {
            PlayBackView(
                onTap: { 
                    showEnhancedPlayer = true
                    shouldShowMiniPlayer = true
                },
                onPlayPause: { audioPlayer.togglePlayPause() },
                onNext: { audioPlayer.playNextTrack() },
                currentTrack: audioPlayer.currentTrack,
                currentArtist: audioPlayer.currentArtist,
                currentArtwork: audioPlayer.currentArtwork,
                isPlaying: audioPlayer.isPlaying
            )
            .padding(.vertical, 8)
            .onChange(of: isTabBarMinimized) { _, newValue in
                print("🎛️ Mini player - Tab bar minimized: \(newValue)")
            }
        }
    }
    
    @ViewBuilder
    private var welcomeModalView: some View {
        WelcomeModalView(
            isDarkMode: isDarkMode,
            onButtonDismiss: {
                showWelcomeModal = false
            },
            onPlayTapped: {
                                showVideoPlayer = true
            }
        )
        .presentationDetents([.fraction(0.75)])
        .presentationDragIndicator(.visible)
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
        provideHapticFeedback()
        print("🎶 Now playing playlist: \(playlistTitle) by \(curatorName)")
    }
    
    private func provideHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    ContentView()
}