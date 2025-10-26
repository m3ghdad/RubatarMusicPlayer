//
//  AboutRubatarModalView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import SwiftUI
import MusicKit

struct AboutRubatarModalView: View {
    let isDarkMode: Bool
    let onButtonDismiss: () -> Void
    let skipFirstPage: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var currentPage: Int = 0
    @State private var showPermissionResult: Bool = false
    @State private var lastAuthStatus: MusicAuthorization.Status? = nil
    private let topImageHeight: CGFloat = 453.6

    // When opened on first launch (skipFirstPage == false), only show 3 pages: Welcome, About, How it works
    private var totalPages: Int { skipFirstPage ? 4 : 3 }
    private var lastPageIndex: Int { totalPages - 1 }
    private var isLastPage: Bool { currentPage >= lastPageIndex }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main content container (green) filling the sheet
            VStack(spacing: 0) {
                // Carousel Content
                TabView(selection: $currentPage) {
                    if skipFirstPage == false {
                        // Page 1 - Welcome
                        welcomePage
                            .tag(0)
                        // Page 2
                        infoPage(
                            title: "About the App",
                            text: "Rubatar connects traditional regional music with classical poetry.\n\nThe name Rubatar blends Rubaii (رباعیات), a Persian four-line poetic form, with Tār (تار), an 18th-century Persian string instrument central to Iranian music."
                        )
                        .tag(1)
                        // Page 3
                        infoPage(
                            title: "How it Works",
                            text: "You'll find a daily selection of poems to read and enjoy while listening to traditional regional music.\n\nUpcoming features will let you analyze, bookmark, and annotate poems as you explore."
                        )
                        .tag(2)
                        // Page 4 (What's next) and Page 5 (Get featured) are hidden on first launch
                        // They remain visible when opened from Profile (skipFirstPage == true)
                    } else {
                        // Skipping first page; re-tag remaining as 0..3 (full set including 'What's next' and 'Get featured')
                        infoPage(
                            title: "About Rubatar",
                            text: "Rubatar connects traditional regional music with classical poetry.\n\nThe name Rubatar blends Rubaii (رباعیات), a Persian four-line poetic form, with Tār (تار), an 18th-century Persian string instrument central to Iranian music."
                        )
                        .tag(0)
                        infoPage(
                            title: "How it Works",
                            text: "You'll also find a daily selection of poems to read and enjoy, even without an Apple Music subscription.\n\nUpcoming features will let you analyze, bookmark, and annotate poems as you explore."
                        )
                        .tag(1)
                        infoPage(
                            title: "What's Next",
                            text: "We're working on new features, including:\n• Saving and sharing your favorite poems\n• Searching and filtering by poet, poems, songs, artists and more.\nWe'll keep expanding Rubatar based on community interest, your feedback helps shape its future."
                        )
                        .tag(2)
                        infoPage(
                            title: "Get Featured",
                            text: "If you curate traditional or regional playlists on Apple Music, \n Or play instruments like Tār, Setār, Santoor, Oud, or Tonbak, get in touch, we'd love to feature your work.\nYou don't need a published album; we welcome all passionate musicians and independent poets from around the world. \n Contact us at support@rubatar.com"
                        )
                        .tag(3)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                
                // Footer buttons
                footerButtons
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
        }
        .overlay(alignment: .topLeading) {
            Button(action: {
                print("🔘 Close button tapped")
                onButtonDismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(.clear)
                        .frame(width: 48, height: 48)
                        .glassEffect(in: Circle())
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .allowsHitTesting(true)
            .padding(.leading, 20)
            .padding(.top, 16)
            .zIndex(1000)
        }
        .onAppear { updatePageControl(for: colorScheme) }
        .onChange(of: colorScheme) { _, newValue in updatePageControl(for: newValue) }
        
    }
    
    // MARK: Pages
    private var welcomePage: some View {
        VStack(spacing: 16) {
            ZStack {
                // Custom gradient from top center to bottom center
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "EED6AA").opacity(1.0), location: 0.0),
                        .init(color: Color(hex: "F2BB56").opacity(0.8), location: 0.2),
                        .init(color: Color(hex: "C88100").opacity(0.6), location: 0.45),
                        .init(color: Color(hex: "765822").opacity(0.4), location: 0.8),
                        .init(color: Color(hex: "000000").opacity(0.1), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // WelcomeImageOne centered in the container (20% smaller)
                Image("WelcomeImageOne")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: topImageHeight)
            
            VStack(spacing: 12) {
                Text("Welcome to\nRubatar")
                    .font(.custom("Palatino", size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                // Description container - fills remaining space and centers its content
                HStack {
                    Spacer(minLength: 0)
                    Text("Connect to Apple Music to explore curated playlists of traditional regional music.")
                        .font(.custom("Palatino", size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: -64)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
    }
    
    private func infoPage(title: String, text: String) -> some View {
        VStack(spacing: 16) {
            // Image container with custom gradient
            ZStack {
                // Custom gradient from top center to bottom center
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "EED6AA").opacity(1.0), location: 0.0),
                        .init(color: Color(hex: "F2BB56").opacity(0.8), location: 0.2),
                        .init(color: Color(hex: "C88100").opacity(0.6), location: 0.45),
                        .init(color: Color(hex: "765822").opacity(0.4), location: 0.8),
                        .init(color: Color(hex: "000000").opacity(0.1), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // WelcomeImageOne centered in the container (20% smaller)
                Image("WelcomeImageOne")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: topImageHeight)

            VStack(spacing: 12) {
                Text(title)
                    .font(.custom("Palatino", size: 22))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                // Description container - fills remaining space; top-aligned; special layout for "What's next"
                HStack {
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: 8) {
                        if title == "What's next" {
                            let lines = text
                                .replacingOccurrences(of: "\r", with: "")
                                .components(separatedBy: .newlines)
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                            if let first = lines.first {
                                // Intro line (no bullet)
                                emailText(first)
                            }
                            ForEach(Array(lines.dropFirst()), id: \.self) { rawLine in
                                let lineNoBullet = rawLine.hasPrefix("•") ? String(rawLine.dropFirst()).trimmingCharacters(in: .whitespaces) : rawLine
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.custom("Palatino", size: 16))
                                        .foregroundColor(.secondary)
                                    emailText(lineNoBullet)
                                }
                            }
                        } else {
                            ForEach(bulletLines(for: text), id: \.self) { line in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.custom("Palatino", size: 16))
                                        .foregroundColor(.secondary)
                                    emailText(line)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        
    }
}

// MARK: - UIPageControl Styling
extension AboutRubatarModalView {
    private func updatePageControl(for scheme: ColorScheme) {
        #if canImport(UIKit)
        let pageControl = UIPageControl.appearance()
        if scheme == .dark {
            pageControl.currentPageIndicatorTintColor = UIColor.white
            pageControl.pageIndicatorTintColor = UIColor(white: 1.0, alpha: 0.35)
        } else {
            pageControl.currentPageIndicatorTintColor = UIColor.black
            pageControl.pageIndicatorTintColor = UIColor(white: 0.0, alpha: 0.25)
        }
        #endif
    }
}

// MARK: - Helpers
extension AboutRubatarModalView {
    private func bulletLines(for text: String) -> [String] {
        // Split by line breaks or '•' and trim whitespace; filter empties
        let manualSplit = text
            .replacingOccurrences(of: "\r", with: "")
            .components(separatedBy: .newlines)
            .flatMap { $0.split(separator: "•").map(String.init) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if manualSplit.isEmpty { return [text] }
        return manualSplit
    }

    @ViewBuilder
    private func emailText(_ content: String) -> some View {
        // Detect 'support@rubatar.com' and render as tappable link
        if content.contains("support@rubatar.com") {
            let parts = content.components(separatedBy: "support@rubatar.com")
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(parts.first ?? "")
                    .font(.custom("Palatino", size: 16))
                    .foregroundColor(.secondary)
                Link("support@rubatar.com", destination: URL(string: "mailto:support@rubatar.com")!)
                    .font(.custom("Palatino", size: 16))
                Text(parts.dropFirst().joined(separator: "support@rubatar.com"))
                    .font(.custom("Palatino", size: 16))
                    .foregroundColor(.secondary)
            }
        } else {
            Text(content)
                .font(.custom("Palatino", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Footer Buttons
extension AboutRubatarModalView {
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
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func primaryNextButton() -> some View {
        Button {
            if isLastPage { onButtonDismiss() } else { currentPage += 1 }
        } label: {
            Text(isLastPage ? "Done" : ((skipFirstPage == false && (currentPage == 0 ? true : (currentPage == totalPages - 1)))) ? (currentPage == 0 ? "Skip" : "Done") : "Continue")
                .font(.custom("Palatino", size: 17).weight(.semibold))
                .foregroundColor(isLastPage ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    {
                        if isLastPage {
                            (isDarkMode ? Color(hex: "E3B887") : Color(hex: "7A5C39"))
                        } else {
                            Color.secondary.opacity(0.2)
                        }
                    }(), in: RoundedRectangle(cornerRadius: 12)
                )
        }
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
                .font(.custom("Palatino", size: 17).weight(.semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        }
    }

    @ViewBuilder
    private func connectAppleMusicButton() -> some View {
        Button {
            Task {
                let status = await MusicAuthorization.request()
                await MainActor.run {
                    lastAuthStatus = status
                    showPermissionResult = true
                    if status == .authorized {
                        hasSeenWelcome = true
                        if currentPage == 0 { currentPage = 1 }
                    }
                }
            }
        } label: {
            Text("Connect to Apple Music")
                .font(.custom("Palatino", size: 17).weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "F71A33"), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

