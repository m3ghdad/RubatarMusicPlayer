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

    // When opened on first launch (skipFirstPage == false), only show 3 pages: Welcome, How it Works, Get Featured
    // When opened from profile (skipFirstPage == true), show 3 pages: Welcome, How it Works, Get Featured
    private var totalPages: Int { 3 }
    private var lastPageIndex: Int { totalPages - 1 }
    private var isLastPage: Bool { currentPage >= lastPageIndex }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background gradient for the entire bottom sheet
            Group {
                if colorScheme == .dark {
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "000000"), location: 0.5),
                            .init(color: Color(hex: "0B0701"), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "FFFFFF"), location: 0.5),
                            .init(color: Color(hex: "F7EBD7"), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .ignoresSafeArea()
            
            // Main content container (green) filling the sheet
            VStack(spacing: 0) {
                // Carousel Content
                TabView(selection: $currentPage) {
                    if skipFirstPage == false {
                        // Page 1 - Welcome
                        welcomePage
                            .tag(0)
                        // Page 2 - How it Works
                        infoPage(
                            title: "How it Works",
                            text: "You'll find a daily selection of poems to read and enjoy while listening to traditional regional music.\n\nUpcoming features will let you analyze, bookmark, and annotate poems. In future realses you will be able to:.",
                            imageName: "HowItWorks"
                        )
                        .tag(1)
                        // Page 3 - Get Featured
                        infoPage(
                            title: "Get Featured",
                            text: "If you curate traditional or regional playlists on Apple Music, Or play instruments like Tār, Setār, Santoor, Oud, or Tonbak, get in touch, we'd love to feature your work.\n\nDon't have an album published? No problem, we welcome all passionate musicians and independent poets from around the world.\n\nContact us at support@rubatar.com",
                            imageName: "GetFeatured"
                        )
                        .tag(2)
                        // Page 4 (What's next) and Page 5 (Get featured) are hidden on first launch
                        // They remain visible when opened from Profile (skipFirstPage == true)
                    } else {
                        // Opened from profile; same pages as first launch
                        // Page 1 - Welcome
                        welcomePage
                            .tag(0)
                        // Page 2 - How it Works
                        infoPage(
                            title: "How it Works",
                            text: "You'll find a daily selection of poems to read and enjoy while listening to traditional regional music.\n\nUpcoming features will let you analyze, bookmark, and annotate poems as you explore.",
                            imageName: "HowItWorks"
                        )
                        .tag(1)
                        // Page 3 - Get Featured
                        infoPage(
                            title: "Get Featured",
                            text: "If you curate traditional or regional playlists on Apple Music,  Or play instruments like Tār, Setār, Santoor, Oud, or Tonbak, get in touch, we'd love to feature your work.\n\nDon't have an album published? No problem, we welcome all passionate musicians and independent poets from around the world.\n\nContact us at support@rubatar.com",
                            imageName: "GetFeatured"
                        )
                        .tag(2)
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
        .onAppear { 
            updatePageControl(for: colorScheme)
            // Set hasSeenWelcome to true as soon as the modal appears
            hasSeenWelcome = true
        }
        .onChange(of: colorScheme) { _, newValue in updatePageControl(for: newValue) }
        
    }
    
    // MARK: Pages
    private var welcomePage: some View {
        VStack(spacing: 16) {
            ZStack {
                // Custom gradient - different for light/dark mode
                Group {
                    if colorScheme == .dark {
                        // Dark mode gradient
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: "C98200"), location: 0.0),
                                .init(color: Color(hex: "C78102").opacity(0.8), location: 0.25),
                                .init(color: Color(hex: "BD7A00").opacity(0.5), location: 0.5),
                                .init(color: Color(hex: "7D5100").opacity(0.5), location: 0.75),
                                .init(color: Color(hex: "000000").opacity(0.5), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        // Light mode gradient
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: "D78F0C").opacity(0.5), location: 0.0),
                                .init(color: Color(hex: "FFDB99").opacity(0.75), location: 0.25),
                                .init(color: Color(hex: "EFD9B2").opacity(0.5), location: 0.5),
                                .init(color: Color(hex: "FFFFFF").opacity(1.0), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                
                // WelcomeImageOne centered in the container (20% smaller)
                Image("WelcomeImageOne")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(0.8)
                    .offset(y: -24)
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
                    VStack(alignment: .leading, spacing: 16) {
                        // First paragraph
                        (Text("Rubatar")
                            .bold()
                            .italic()
                            .foregroundColor(colorScheme == .dark ? Color(hex: "FFFFFF") : Color.black) +
                         Text(" connects regional music with classical poetry.")
                            .foregroundColor(Color.secondary))
                            .font(.custom("Palatino", size: 16))
                        
                        // Divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                            .padding(.vertical, 8)
                        
                        // Second paragraph
                        (Text("The name ") +
                         Text("Rubatar")
                            .bold()
                            .italic()
                            .foregroundColor(colorScheme == .dark ? Color(hex: "FFFFFF") : Color.black) +
                         Text(" blends ") +
                         Text("Rubaii")
                            .bold()
                            .italic()
                            .foregroundColor(colorScheme == .dark ? Color(hex: "FFFFFF") : Color.black) +
                         Text(" (رباعیات), a Persian four-line poetic form, with ") +
                         Text("Tār")
                            .bold()
                            .italic()
                            .foregroundColor(colorScheme == .dark ? Color(hex: "FFFFFF") : Color.black) +
                         Text(" (تار), an 18th-century Persian string instrument central to Iranian music."))
                            .font(.custom("Palatino", size: 16))
                            .foregroundColor(Color.secondary)
                        
                        // Third paragraph
                        (Text("Connect to ") +
                         Text("Apple Music")
                            .bold()
                            .italic()
                            .foregroundColor(colorScheme == .dark ? Color(hex: "FFFFFF") : Color.black) +
                         Text(" to explore curated playlists & albums."))
                            .font(.custom("Palatino", size: 16))
                            .foregroundColor(Color.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: -112)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
    }
    
    private func infoPage(title: String, text: String, imageName: String = "WelcomeImageOne", customText: [Text]? = nil) -> some View {
        VStack(spacing: 16) {
            // Image container with custom gradient
            ZStack {
                // Custom gradient - different for light/dark mode
                Group {
                    if colorScheme == .dark {
                        // Dark mode gradient
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: "C98200"), location: 0.0),
                                .init(color: Color(hex: "C78102").opacity(0.8), location: 0.25),
                                .init(color: Color(hex: "BD7A00").opacity(0.5), location: 0.5),
                                .init(color: Color(hex: "7D5100").opacity(0.5), location: 0.75),
                                .init(color: Color(hex: "000000").opacity(0.5), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        // Light mode gradient
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: "D78F0C").opacity(0.5), location: 0.0),
                                .init(color: Color(hex: "FFDB99").opacity(0.75), location: 0.25),
                                .init(color: Color(hex: "EFD9B2").opacity(0.5), location: 0.5),
                                .init(color: Color(hex: "FFFFFF").opacity(1.0), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                
                // Image centered in the container (20% smaller)
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(0.8)
                    .offset(y: imageName == "HowItWorks" ? -2 : -24)
            }
            .frame(maxWidth: .infinity)
            .frame(height: topImageHeight)

            VStack(spacing: 12) {
                Text(title)
                    .font(.custom("Palatino", size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                // Description container - fills remaining space; top-aligned; special layout for "What's next" and "How it Works"
                HStack {
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: 16) {
                        if title == "How it Works" {
                            // Custom styled text for "How it Works"
                            VStack(alignment: .leading, spacing: 16) {
                                // First paragraph
                                (Text("You'll find a daily selection of poems to ") +
                                 Text("read")
                                    .bold()
                                    .italic()
                                    .foregroundColor(colorScheme == .dark ? Color(hex: "FFFFFF") : Color.black) +
                                 Text(" while ") +
                                 Text("listening")
                                    .bold()
                                    .italic()
                                    .foregroundColor(colorScheme == .dark ? Color(hex: "FFFFFF") : Color.black) +
                                 Text(" to regional music."))
                                    .font(.custom("Palatino", size: 16))
                                    .foregroundColor(Color.secondary)
                                
                                // Divider
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.vertical, 8)
                                
                                // Second paragraph with colon
                                Text("Upcoming features will let you analyze, bookmark, and annotate poems, and the following will be released soon:")
                                    .font(.custom("Palatino", size: 16))
                                    .foregroundColor(Color.secondary)
                                
                                // Empty line
                                Text("")
                                    .font(.custom("Palatino", size: 16))
                                
                                // Bullet points
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .font(.custom("Palatino", size: 16))
                                            .foregroundColor(.secondary)
                                        Text("Saving and sharing your favorite poems")
                                            .font(.custom("Palatino", size: 16))
                                            .foregroundColor(.secondary)
                                    }
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .font(.custom("Palatino", size: 16))
                                            .foregroundColor(.secondary)
                                        Text("Searching and filtering by poet, poems, songs, artists and more.")
                                            .font(.custom("Palatino", size: 16))
                                            .foregroundColor(.secondary)
                                    }
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .font(.custom("Palatino", size: 16))
                                            .foregroundColor(.secondary)
                                        Text("And more! We'll keep expanding Rubatar based on community interest")
                                            .font(.custom("Palatino", size: 16))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        } else if title == "Get Featured" {
                            // Custom styled text for "Get Featured"
                            VStack(alignment: .leading, spacing: 16) {
                                // First paragraph
                                Text("If you curate traditional or regional playlists on Apple Music, or play instruments like Tār, Setār, Santoor, Oud, or Tonbak, get in touch, we'd love to feature your work.")
                                    .font(.custom("Palatino", size: 16))
                                    .foregroundColor(Color.secondary)
                                
                                // Empty line
                                Text("")
                                    .font(.custom("Palatino", size: 16))
                                
                                // Second paragraph
                                Text("Don't have an album published? No problem, we welcome all passionate musicians and independent poets from around the world.")
                                    .font(.custom("Palatino", size: 16))
                                    .foregroundColor(Color.secondary)
                                
                                // Divider
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.vertical, 8)
                                
                                // Contact email
                                emailText("Contact us at support@rubatar.com")
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        } else if title == "What's next" {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: title == "How it Works" ? -92 : -112)
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
        let buttonText = isLastPage ? "Done" : ((skipFirstPage == false && (currentPage == 0 ? true : (currentPage == totalPages - 1)))) ? (currentPage == 0 ? "Continue" : "Done") : "Continue"
        
        Button {
            if isLastPage { onButtonDismiss() } else { currentPage += 1 }
        } label: {
            Text(buttonText)
                .font(.custom("Palatino", size: 17).weight(.semibold))
                .foregroundColor(
                    isLastPage ? Color.white : (isDarkMode ? Color.black : Color.white)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    {
                        if isLastPage {
                            Color(hex: "BF8121")
                        } else {
                            // Skip/Continue buttons - white in dark mode, black in light mode
                            (isDarkMode ? Color.white : Color.black)
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
                .background(Color(hex: "BF8121"), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

