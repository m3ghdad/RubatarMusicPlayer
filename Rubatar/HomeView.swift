import SwiftUI

struct HomeView: View {
    @Binding var showCard: Bool
    @Binding var showWelcomeModal: Bool
    @Binding var showVideoPlayer: Bool
    @Binding var isTabBarMinimized: Bool
    @Binding var scrollOffset: CGFloat
    let onMusicSelected: (String, String, URL?) -> Void
    let onPlaylistSelected: (String, String, String, URL?) -> Void
    @Binding var showProfileSheet: Bool
    @EnvironmentObject var contentManager: ContentManager
    @EnvironmentObject var contentPreloader: ContentPreloader
    
    @State private var lastScrollOffset: CGFloat = 0
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Simple black background
                Color.black
                    .ignoresSafeArea()
                
                NavigationView {
                    ScrollView {
                        HomeContent(
                            isIPad: geometry.size.width > 600,
                            screenWidth: geometry.size.width,
                            onMusicSelected: onMusicSelected,
                            onPlaylistSelected: onPlaylistSelected,
                            showProfileSheet: $showProfileSheet,
                            lastScrollOffset: $lastScrollOffset,
                            scrollOffset: $scrollOffset,
                            isTabBarMinimized: $isTabBarMinimized
                        )
                        .environmentObject(contentManager)
                        .environmentObject(contentPreloader)
                    }
                    .scrollIndicators(.hidden)
                    .navigationBarHidden(true)
                }
                .navigationViewStyle(.stack) // Force stack style on iPad to prevent sidebar
            }
        }
    }
}

// MARK: - Home Content (Extracted for better organization)
struct HomeContent: View {
    let isIPad: Bool
    let screenWidth: CGFloat
    let onMusicSelected: (String, String, URL?) -> Void
    let onPlaylistSelected: (String, String, String, URL?) -> Void
    @Binding var showProfileSheet: Bool
    @EnvironmentObject var contentManager: ContentManager
    @EnvironmentObject var contentPreloader: ContentPreloader
    @Binding var lastScrollOffset: CGFloat
    @Binding var scrollOffset: CGFloat
    @Binding var isTabBarMinimized: Bool
    
    var horizontalPadding: CGFloat {
        isIPad ? min(screenWidth * 0.1, 120) : 16
    }
    
    var contentMaxWidth: CGFloat {
        isIPad ? 1200 : .infinity
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Home")
                    .font(.custom("Palatino", size: isIPad ? 40 : 34))
                    .fontWeight(.bold)
                Spacer()
                AvatarButtonView(action: {
                    showProfileSheet = true
                })
            }
            .padding(.horizontal, isIPad ? 56 : horizontalPadding + 8)
            
            // Content container with max width for iPad
            VStack(spacing: 20) {
                MusicSectionView(
                    onMusicSelected: { track, artist, artwork in
                        onMusicSelected(track, artist, artwork)
                    },
                    onPlaylistSelected: { playlistId, playlistTitle, curatorName, artwork in
                        onPlaylistSelected(playlistId, playlistTitle, curatorName, artwork)
                    },
                    isPreloading: contentPreloader.isLoading
                )
            }
            .frame(maxWidth: contentMaxWidth, alignment: .center)
            
            Spacer(minLength: 100)
        }
        .padding(.top, 20)
        .padding(.horizontal, horizontalPadding)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .global).minY)
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            let delta = value - lastScrollOffset
            scrollOffset = value

            if abs(delta) <= 2 { return }

            withAnimation(.easeInOut(duration: 0.25)) {
                if delta < 0 { isTabBarMinimized = true } else { isTabBarMinimized = false }
            }

            lastScrollOffset = value
        }
    }
}

// MARK: - Original HomeView Content (Commented Out)
/*
struct HomeView_Original: View {
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0
    @Binding var showCard: Bool
    @Binding var showWelcomeModal: Bool
    @Binding var showVideoPlayer: Bool
    @Binding var isTabBarMinimized: Bool
    @Binding var scrollOffset: CGFloat
    @Binding var showProfileSheet: Bool
    
    @State private var lastScrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text("Home")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        AvatarButtonView(action: {
                            showProfileSheet = true
                        })
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
                    
                    BrowseCollectionsSection()
                    
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

                if abs(delta) <= 2 { return }

                withAnimation(.easeInOut(duration: 0.25)) {
                    if delta < 0 { isTabBarMinimized = true } else { isTabBarMinimized = false }
                }

                lastScrollOffset = value
            }
            .navigationBarHidden(true)
        }
    }
}
*/
