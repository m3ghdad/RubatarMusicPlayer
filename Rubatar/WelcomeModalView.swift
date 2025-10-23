import SwiftUI
import MusicKit

struct WelcomeModalView: View {
    let isDarkMode: Bool
    let onButtonDismiss: () -> Void
    let skipFirstPage: Bool
    
    @State private var currentPage: Int = 0
    @State private var showPermissionResult: Bool = false
    @State private var lastAuthStatus: MusicAuthorization.Status? = nil
    private let topImageHeight: CGFloat = 300

    private var totalPages: Int { skipFirstPage ? 4 : 5 }
    private var lastPageIndex: Int { totalPages - 1 }
    private var isLastPage: Bool { currentPage >= lastPageIndex }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Pager (top image should be visually behind drag handle)
                TabView(selection: $currentPage) {
                    if skipFirstPage == false {
                        // Page 1 - Welcome
                        welcomePage
                            .tag(0)
                        // Page 2
                        infoPage(
                            title: "About Rubatar",
                            text: "The name Rubatar blends Rubaii (رباعیات), a Persian four-line poetic form, with Tār (تار), an 18th-century Persian string instrument central to Iranian music."
                        )
                        .tag(1)
                        // Page 3
                        infoPage(
                            title: "How it works",
                            text: "You’ll also find a daily selection of poems to read and enjoy, even without an Apple Music subscription.\n\nUpcoming features will let you analyze, bookmark, and annotate poems as you explore."
                        )
                        .tag(2)
                        // Page 4
                        infoPage(
                            title: "What’s next",
                            text: "We’re working on new features, including:\n• Saving and sharing your favorite poems\n• Searching and filtering by poet, poems, songs, artists and more.\nWe’ll keep expanding Rubatar based on community interest, your feedback helps shape its future support@rubatar.com"
                        )
                        .tag(3)
                        // Page 5
                        infoPage(
                            title: "Get featured",
                            text: "If you curate traditional or regional playlists on Apple Music, or play instruments like Tār, Setār, Santoor, Oud, or Tonbak, get in touch, we’d love to feature your work.\nYou don’t need a published album; we welcome all passionate musicians and independent poets from around the world. Contact us at support@rubatar.com"
                        )
                        .tag(4)
                    } else {
                        // Skipping first page; re-tag remaining as 0..3
                        infoPage(
                            title: "About Rubatar",
                            text: "The name Rubatar blends Rubaii (رباعیات), a Persian four-line poetic form, with Tār (تار), an 18th-century Persian string instrument central to Iranian music."
                        )
                        .tag(0)
                        infoPage(
                            title: "How it works",
                            text: "You’ll also find a daily selection of poems to read and enjoy, even without an Apple Music subscription.\n\nUpcoming features will let you analyze, bookmark, and annotate poems as you explore."
                        )
                        .tag(1)
                        infoPage(
                            title: "What’s next",
                            text: "We’re working on new features, including:\n• Saving and sharing your favorite poems\n• Searching and filtering by poet, poems, songs, artists and more.\nWe’ll keep expanding Rubatar based on community interest, your feedback helps shape its future support@rubatar.com"
                        )
                        .tag(2)
                        infoPage(
                            title: "Get featured",
                            text: "If you curate traditional or regional playlists on Apple Music, or play instruments like Tār, Setār, Santoor, Oud, or Tonbak, get in touch, we’d love to feature your work.\nYou don’t need a published album; we welcome all passionate musicians and independent poets from around the world. Contact us at support@rubatar.com"
                        )
                        .tag(3)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                .overlay(alignment: .topLeading) {
                    // Close button at top-left
                    Button(action: onButtonDismiss) {
                        ZStack {
                            Circle()
                                .fill(.clear)
                                .frame(width: 40, height: 40)
                                .glassEffect(in: Circle())
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 16)
                    .padding(.top, 12)
                }
                
                // Bottom area with CTA or permission result actions
                VStack(spacing: 0) {
                    Divider()
                    // Footer buttons per spec
                    footerButtons
                }
                .background(.regularMaterial)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: Pages
    private var welcomePage: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background image
                Image("AppleMusic")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: topImageHeight)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [Color.black.opacity(0.2), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .ignoresSafeArea(.container, edges: .top)
            
            VStack(spacing: 12) {
                Text("Welcome")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Rubatar connects traditional regional music with classical poetry.\n\nConnect to Apple Music to explore curated playlists of traditional regional music.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)
        }
    }
    
    private func infoPage(title: String, text: String) -> some View {
        VStack(spacing: 16) {
            // Placeholder gradient for images (edge-to-edge, full top area)
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.2, blue: 0.3),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [Color.white.opacity(0.25), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 160
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: topImageHeight)
            .clipped()
            .ignoresSafeArea(.container, edges: .top)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(text)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Footer Buttons
extension WelcomeModalView {
    @ViewBuilder
    private var footerButtons: some View {
        // Determine effective status (current if no prior prompt)
        let effectiveStatus = lastAuthStatus ?? MusicAuthorization.currentStatus
        let isAuthorized = (effectiveStatus == .authorized)
        let isDenied = (effectiveStatus == .denied || effectiveStatus == .restricted)
        let isFirstPageInSet = currentPage == 0

        VStack(spacing: 10) {
            if isFirstPageInSet {
                if isDenied {
                    // First page when denied: Open App Settings + Next
                    secondaryOpenSettingsButton()
                    primaryNextButton()
                } else if !isAuthorized {
                    // First page when not yet authorized: Connect + Next
                    connectAppleMusicButton()
                    primaryNextButton()
                } else {
                    // First page when authorized: Next
                    primaryNextButton()
                }
            } else {
                // Subsequent pages: only Next/Done
                primaryNextButton()
            }
        }
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func primaryNextButton() -> some View {
        Button {
            if isLastPage { onButtonDismiss() } else { currentPage += 1 }
        } label: {
            Text(isLastPage ? "Done" : "Next")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background((isDarkMode ? Color(hex: "E3B887") : Color(hex: "7A5C39")), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private func secondaryOpenSettingsButton() -> some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                #if canImport(UIKit)
                UIApplication.shared.open(url)
                #endif
            }
        } label: {
            Text("Open App Settings")
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func connectAppleMusicButton() -> some View {
        Button {
            Task {
                let status = await MusicAuthorization.request()
                await MainActor.run {
                    lastAuthStatus = status
                    showPermissionResult = true
                }
            }
        } label: {
            Text("Connect to Apple Music")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "F71A33"), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
    }
}
