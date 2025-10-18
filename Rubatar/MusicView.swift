import SwiftUI

struct MusicView: View {
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0
    @Binding var showCard: Bool
    @Binding var showWelcomeModal: Bool
    @Binding var showVideoPlayer: Bool
    @Binding var isTabBarMinimized: Bool
    @Binding var scrollOffset: CGFloat
    let onMusicSelected: (String, String, URL?) -> Void
    let onPlaylistSelected: (String, String, String, URL?) -> Void
    @Binding var showProfileSheet: Bool
    
    @State private var lastScrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            getBackgroundColors()[selectedBackgroundColor].gradient
                .ignoresSafeArea()
            
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Music")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Spacer()
                            AvatarButtonView(action: {
                                showProfileSheet = true
                            })
                        }
                        .padding(.horizontal, 16)
                        
                        MusicSectionView(
                            onMusicSelected: { track, artist, artwork in
                                onMusicSelected(track, artist, artwork)
                            },
                            onPlaylistSelected: { playlistId, playlistTitle, curatorName, artwork in
                                onPlaylistSelected(playlistId, playlistTitle, curatorName, artwork)
                            }
                        )
                        
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
}
