//
//  ProfileView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import SwiftUI

// Language enum
enum AppLanguage: String {
    case english = "English"
    case farsi = "Farsi"
}

// Display mode enum for poem text
enum DisplayMode: String {
    case typewriter = "Typewriter"
    case staticMode = "Static"
}

// Custom dashed line shape
struct DashedLine: Shape {
    let dashCount: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let dashWidth = rect.width / CGFloat(dashCount * 2 - 1)
        
        for i in 0..<dashCount {
            let x = CGFloat(i * 2) * dashWidth
            path.move(to: CGPoint(x: x, y: rect.midY))
            path.addLine(to: CGPoint(x: x + dashWidth, y: rect.midY))
        }
        
        return path
    }
}

// Calculate cumulative delay for typewriter effect
private func calculateLineDelay(poemData: PoemData, startBeytIndex: Int, targetBeytIndex: Int, lineIndex: Int) -> TimeInterval {
    var delay: TimeInterval = 0
    
    // Add time for all previous beyts
    for beytIdx in startBeytIndex..<targetBeytIndex {
        if beytIdx < poemData.verses.count {
            let beyt = poemData.verses[beytIdx]
            if beyt.count > 0 {
                delay += Double(beyt[0].count) * 0.05 + 0.2
            }
            if beyt.count > 1 {
                delay += Double(beyt[1].count) * 0.05 + 0.2
            }
        }
    }
    
    // If this is the second line of the target beyt, add time for the first line
    if lineIndex == 1 && targetBeytIndex < poemData.verses.count {
        let beyt = poemData.verses[targetBeytIndex]
        if beyt.count > 0 {
            delay += Double(beyt[0].count) * 0.05 + 0.2
        }
    }
    
    return delay
}

struct ProfileView: View {
    @State private var showProfileSheet = false
    @State private var currentPage = 0 // Current page within a poem (verse index)
    @State private var showMenu = false
    @State private var showLanguageMenu = false // Language submenu state
    @State private var selectedLanguage: AppLanguage = .english // Current language
    @State private var showConfigureMenu = false // Configure submenu state
    @State private var selectedDisplayMode: DisplayMode // Display mode for poem text
    @State private var showToast = false
    @State private var toastMessage = ""
    @StateObject private var poetryService = PoetryService()
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var menuNamespace // For zoom animation
    @State private var activeCardIndex = 0 // Track which card's menu is open
    @State private var versePage = 0 // Track current page within a poem
    @State private var typewriterTrigger: [String: Int] = [:] // Trigger for typewriter: "poemId-pageIndex-cardIndex" -> count
    @State private var completedTypewriterPages: Set<String> = [] // Track pages that have completed typing
    
    // Initialize with saved display mode preference
    init() {
        let savedMode = UserDefaults.standard.string(forKey: "displayMode") ?? DisplayMode.staticMode.rawValue
        _selectedDisplayMode = State(initialValue: DisplayMode(rawValue: savedMode) ?? .staticMode)
    }
    
    // Multiple poems from API
    @State private var poems: [PoemData] = []
    @State private var translatedPoems: [Int: PoemData] = [:] // Cache: poem.id -> translated poem
    @State private var isTranslating = false
    
    // Translation manager
    private let translationManager = TranslationManager(apiKey: Config.openAIAPIKey)
    
    // Helper function to convert numbers to Farsi numerals
    private func toFarsiNumber(_ number: Int) -> String {
        let farsiDigits = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]
        return String(number).compactMap { char in
            guard let digit = Int(String(char)) else { return String(char) }
            return farsiDigits[digit]
        }.joined()
    }
    
    // Translate poems automatically
    private func translatePoemsIfNeeded() {
        Task {
            for poem in poems {
                // Skip if already translated
                guard translatedPoems[poem.id] == nil else { continue }
                
                isTranslating = true
                
                if let translated = await translationManager.translatePoem(poem) {
                    translatedPoems[poem.id] = translated
                }
                
                isTranslating = false
            }
        }
    }
    
    // Refresh poems - load new set of poems
    private func refreshPoems() {
        toastMessage = "Stirring the words…"
        showToast = true
        
        Task {
            // Clear existing poems and translations
            poems = []
            translatedPoems = [:]
            completedTypewriterPages.removeAll() // Clear completed pages on refresh
            
            // Fetch new poems from Supabase
            let newPoems = await poetryService.fetchPoems(limit: 10)
            if !newPoems.isEmpty {
                poems = newPoems
                currentPage = 0
                
                // Automatically translate new poems
                translatePoemsIfNeeded()
            }
        }
        
        // Hide toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showToast = false
        }
    }
    
    var body: some View {
        ZStack {
            // Background - adapts to dark mode
            (colorScheme == .dark ? Color.black : Color(red: 244/255, green: 244/255, blue: 244/255))
                .ignoresSafeArea()
            
            // Paging carousel with peek of adjacent cards
            VStack(spacing: 0) {
                if poems.isEmpty {
                    // Show loading skeleton cards until poems are fetched
                    PagingScrollView(pageCount: 3, content: { index in
                        PoemCardView(
                            poem: nil,
                            isTranslated: false,
                            selectedLanguage: selectedLanguage,
                            displayMode: selectedDisplayMode,
                            toFarsiNumber: toFarsiNumber,
                            showMenu: $showMenu,
                            activeCardIndex: $activeCardIndex,
                            typewriterTrigger: $typewriterTrigger,
                            completedPages: $completedTypewriterPages,
                            menuNamespace: menuNamespace,
                            cardIndex: index
                        )
                    }, currentPage: $currentPage)
                } else if selectedLanguage == .farsi {
                    // Show original Farsi poems
                    PagingScrollView(pageCount: poems.count, content: { index in
                        PoemCardView(
                            poem: poems[index],
                            isTranslated: false,
                            selectedLanguage: selectedLanguage,
                            displayMode: selectedDisplayMode,
                            toFarsiNumber: toFarsiNumber,
                            showMenu: $showMenu,
                            activeCardIndex: $activeCardIndex,
                            typewriterTrigger: $typewriterTrigger,
                            completedPages: $completedTypewriterPages,
                            menuNamespace: menuNamespace,
                            cardIndex: index
                        )
                    }, currentPage: $currentPage)
                } else {
                    // Show translated English poems
                    let translatedPoemsList = poems.compactMap { poem -> PoemData? in
                        translatedPoems[poem.id]
                    }
                    
                    if translatedPoemsList.isEmpty {
                        // Still translating, show skeleton
                        PagingScrollView(pageCount: 3, content: { index in
                            PoemCardView(
                                poem: nil,
                                isTranslated: false,
                                selectedLanguage: selectedLanguage,
                                displayMode: selectedDisplayMode,
                                toFarsiNumber: toFarsiNumber,
                                showMenu: $showMenu,
                                activeCardIndex: $activeCardIndex,
                                typewriterTrigger: $typewriterTrigger,
                                completedPages: $completedTypewriterPages,
                                menuNamespace: menuNamespace,
                                cardIndex: index
                            )
                        }, currentPage: $currentPage)
                    } else {
                        // Show translated poems
                        PagingScrollView(pageCount: translatedPoemsList.count, content: { index in
                            PoemCardView(
                                poem: translatedPoemsList[index],
                                isTranslated: true,
                                selectedLanguage: selectedLanguage,
                                displayMode: selectedDisplayMode,
                                toFarsiNumber: toFarsiNumber,
                                showMenu: $showMenu,
                                activeCardIndex: $activeCardIndex,
                                typewriterTrigger: $typewriterTrigger,
                                completedPages: $completedTypewriterPages,
                                menuNamespace: menuNamespace,
                                cardIndex: index
                            )
                        }, currentPage: $currentPage)
                    }
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .overlay {
            if showMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showLanguageMenu = false
                            showMenu = false
                        }
                    }
                    .transition(.opacity)
            }
        }
        .overlay(alignment: selectedLanguage == .farsi ? .topLeading : .topTrailing) {
            if showMenu {
                MenuPopoverHelper(
                    selectedLanguage: selectedLanguage,
                    showLanguageMenu: $showLanguageMenu,
                    selectedDisplayMode: selectedDisplayMode,
                    showConfigureMenu: $showConfigureMenu,
                    onSave: {
                        print("Save tapped")
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showMenu = false
                            showLanguageMenu = false
                            showConfigureMenu = false
                        }
                    },
                    onShare: {
                        print("Share tapped")
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showMenu = false
                            showLanguageMenu = false
                            showConfigureMenu = false
                        }
                    },
                    onSelectText: {
                        print("Select text tapped")
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showMenu = false
                            showLanguageMenu = false
                            showConfigureMenu = false
                        }
                    },
                    onRefresh: {
                        refreshPoems()
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showMenu = false
                            showLanguageMenu = false
                            showConfigureMenu = false
                        }
                    },
                    onGoToPoet: {
                        print("Go to poet tapped")
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showMenu = false
                            showLanguageMenu = false
                            showConfigureMenu = false
                        }
                    },
                    onInterpretation: {
                        print("Interpretation tapped")
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showMenu = false
                            showLanguageMenu = false
                            showConfigureMenu = false
                        }
                    },
                    onLanguage: {
                        // Toggle language submenu expansion
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showLanguageMenu.toggle()
                            showConfigureMenu = false // Close configure menu
                        }
                    },
                    onSelectLanguage: { language in
                        // Update selected language and close menus
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            selectedLanguage = language
                            showLanguageMenu = false
                            showMenu = false
                            showConfigureMenu = false
                        }
                    },
                    onConfigure: {
                        // Toggle configure submenu expansion
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showConfigureMenu.toggle()
                            showLanguageMenu = false // Close language menu
                        }
                    },
                    onSelectDisplayMode: { mode in
                        // Update display mode, save to UserDefaults, and close menus
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            selectedDisplayMode = mode
                            UserDefaults.standard.set(mode.rawValue, forKey: "displayMode")
                            showConfigureMenu = false
                            showMenu = false
                            showLanguageMenu = false
                            
                            // Clear completed pages when switching modes
                            completedTypewriterPages.removeAll()
                            
                            // Show toast message
                            toastMessage = mode == .typewriter ? "Typewriter mode enabled" : "Static mode enabled"
                            showToast = true
                        }
                        
                        // Hide toast after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showToast = false
                        }
                    },
                    onThemes: {
                        print("Themes tapped")
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showMenu = false
                            showLanguageMenu = false
                            showConfigureMenu = false
                        }
                    }
                )
                .padding(selectedLanguage == .farsi ? .leading : .trailing, 32)
                .padding(.top, 58)
                .matchedGeometryEffect(id: "MENUCONTENT\(activeCardIndex)", in: menuNamespace)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.01, anchor: selectedLanguage == .farsi ? .topLeading : .topTrailing).combined(with: .opacity),
                    removal: .scale(scale: 0.01, anchor: selectedLanguage == .farsi ? .topLeading : .topTrailing).combined(with: .opacity)
                ))
            }
        }
        .toast(isShowing: $showToast, message: toastMessage)
        .navigationBarHidden(true)
        .animation(.snappy(duration: 0.3, extraBounce: 0), value: showMenu)
        .onAppear {
            // Load initial poems from Supabase
            Task {
                let initialPoems = await poetryService.fetchPoems(limit: 10)
                if !initialPoems.isEmpty {
                    poems = initialPoems
                    currentPage = 0
                    
                    // Automatically translate poems
                    translatePoemsIfNeeded()
                }
            }
        }
        .onChange(of: currentPage) { _, newPage in
            // Reset verse page when changing cards
            if newPage < poems.count {
                versePage = 0
            }
        }
    }
}

// Animated Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0), location: 0.0),
                        .init(color: Color.white.opacity(0.2), location: 0.3),
                        .init(color: Color.white.opacity(0.6), location: 0.5),
                        .init(color: Color.white.opacity(0.2), location: 0.7),
                        .init(color: Color.white.opacity(0), location: 1.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 500
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// Skeleton Loading View
struct SkeletonLoadingView: View {
    let selectedLanguage: AppLanguage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with skeleton
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    HStack(alignment: .top) {
                        // In Farsi mode: buttons on left, placeholders on right
                        // In English mode: placeholders on left, buttons on right
                        
                        if selectedLanguage == .farsi {
                            // Buttons first (left side in Farsi)
                            HStack(spacing: 8) {
                                Button(action: {}) {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {}) {
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Spacer()
                            
                            // Placeholders (right side in Farsi)
                            VStack(alignment: .trailing, spacing: 8) {
                                // Title placeholder
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 246/255, green: 242/255, blue: 242/255))
                                    .frame(width: 135, height: 32)
                                    .shimmer()
                                
                                // Poet name placeholder
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 246/255, green: 242/255, blue: 242/255))
                                    .frame(width: 87, height: 16)
                                    .shimmer()
                            }
                        } else {
                            // Placeholders (left side in English)
                            VStack(alignment: .leading, spacing: 8) {
                                // Title placeholder
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 246/255, green: 242/255, blue: 242/255))
                                    .frame(width: 135, height: 32)
                                    .shimmer()
                                
                                // Poet name placeholder
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 246/255, green: 242/255, blue: 242/255))
                                    .frame(width: 87, height: 16)
                                    .shimmer()
                            }
                            
                            Spacer()
                            
                            // Buttons (right side in English)
                            HStack(spacing: 8) {
                                Button(action: {}) {
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {}) {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 48)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .background(colorScheme == .dark ? Color(red: 13/255, green: 13/255, blue: 13/255) : Color.white)
                .overlay(
                    VStack {
                    Spacer()
                        DashedLine(dashCount: 12)
                            .stroke((colorScheme == .dark ? Color.white : Color.black).opacity(0.1), lineWidth: 1)
                            .frame(height: 1)
                    }
                )
            }
            
            // Pages section with skeleton lines - centered vertically and horizontally
            VStack(spacing: 10) {
                VStack(spacing: 8) {
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 209, height: 12)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 228, height: 12)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 162, height: 12)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 125, height: 12)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .shimmer()
                    }
                }
                .padding(.vertical, 16)
                
                VStack(spacing: 8) {
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 209, height: 12)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 228, height: 12)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 162, height: 12)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 60/255) : Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 125, height: 12)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .shimmer()
                    }
                }
                .padding(.vertical, 16)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(colorScheme == .dark ? Color(red: 13/255, green: 13/255, blue: 13/255) : Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            
        }
        .background(colorScheme == .dark ? Color.black : Color(red: 244/255, green: 244/255, blue: 244/255))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// Individual Poem Card Component
struct PoemCardView: View {
    let poem: PoemData?
    let isTranslated: Bool
    let selectedLanguage: AppLanguage
    let displayMode: DisplayMode
    let toFarsiNumber: (Int) -> String
    @Binding var showMenu: Bool
    @Binding var activeCardIndex: Int // Track which card's menu is open
    @Binding var typewriterTrigger: [String: Int] // For typewriter animation
    @Binding var completedPages: Set<String> // Track completed typewriter pages
    var menuNamespace: Namespace.ID // For zoom animation
    var cardIndex: Int // Unique index for each card
    
    @State private var versePage = 0 // Current verse page within the poem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        // Show skeleton if no poem data
        if poem == nil {
            SkeletonLoadingView(selectedLanguage: selectedLanguage)
        } else {
            actualPoemView
                .onAppear {
                    // Trigger typewriter animation when this specific card appears (only if typewriter mode)
                    if displayMode == .typewriter {
                        guard let poemData = poem else { return }
                        let key = "\(poemData.id)-\(versePage)-\(cardIndex)"
                        
                        // Only trigger if page hasn't been completed yet
                        if !completedPages.contains(key) {
                            typewriterTrigger[key] = (typewriterTrigger[key] ?? 0) + 1
                        }
                    }
                }
        }
    }
    
    private var actualPoemView: some View {
        let poemData = poem! // Force unwrap since we checked for nil
        
        return VStack(spacing: 8) {
            // Header
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    HStack(alignment: .top) {
                        // In Farsi mode: buttons on left, title/poet on right
                        // In English mode: title/poet on left, buttons on right
                        
                        if selectedLanguage == .farsi {
                            // Buttons first (left side in Farsi)
                            HStack(spacing: 8) {
                                Button(action: {
                                    activeCardIndex = cardIndex
                                    withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                                        showMenu.toggle()
                                    }
                                }) {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(ElegantButtonStyle())
                                .matchedTransitionSource(id: "MENUCONTENT\(cardIndex)", in: menuNamespace)
                                
                                Button(action: {}) {
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Spacer()
                            
                            // Title and poet (right side in Farsi)
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(poemData.title)
                                    .font(.custom("Palatino-Roman", size: 24))
                                    .foregroundColor(colorScheme == .dark ? .white : Color(red: 60/255, green: 60/255, blue: 67/255, opacity: 0.6))
                                    .kerning(-0.43)
                                    .lineSpacing(22)
                                    .multilineTextAlignment(.trailing)
                                
                                Text(poemData.poet.name)
                                    .font(.custom("Palatino-Roman", size: 16))
                                    .foregroundColor(colorScheme == .dark ? Color(hex: "E3B887") : Color(red: 122/255, green: 92/255, blue: 57/255))
                                    .kerning(-0.23)
                                    .lineSpacing(20)
                                    .multilineTextAlignment(.trailing)
                            }
                        } else {
                            // Title and poet (left side in English)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(poemData.title)
                                    .font(.custom("Palatino-Roman", size: 24))
                                    .foregroundColor(colorScheme == .dark ? .white : Color(red: 60/255, green: 60/255, blue: 67/255, opacity: 0.6))
                                    .kerning(-0.43)
                                    .lineSpacing(22)
                                
                                Text(poemData.poet.name)
                                    .font(.custom("Palatino-Roman", size: 16))
                                    .foregroundColor(colorScheme == .dark ? Color(hex: "E3B887") : Color(red: 122/255, green: 92/255, blue: 57/255))
                                    .kerning(-0.23)
                                    .lineSpacing(20)
                            }
                            
                            Spacer()
                            
                            // Buttons (right side in English)
                            HStack(spacing: 8) {
                                Button(action: {}) {
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    activeCardIndex = cardIndex
                                    withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                                        showMenu.toggle()
                                    }
                                }) {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(ElegantButtonStyle())
                                .matchedTransitionSource(id: "MENUCONTENT\(cardIndex)", in: menuNamespace)
                            }
                        }
                    }
                    .padding(.top, 48)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .background(colorScheme == .dark ? Color(red: 13/255, green: 13/255, blue: 13/255) : Color.white)
                        .overlay(
                    VStack {
                        Spacer()
                        DashedLine(dashCount: 12)
                            .stroke((colorScheme == .dark ? Color.white : Color.black).opacity(0.1), lineWidth: 1)
                            .frame(height: 1)
                    }
                )
            }
            
            // Pages section with page curl
            if !poemData.verses.isEmpty {
                let beytsPerPage = 2
                let totalPages = (poemData.verses.count + beytsPerPage - 1) / beytsPerPage
                
                PageCurlView(currentPage: $versePage, pageCount: totalPages, isRTL: selectedLanguage == .farsi) { pageIndex in
                    VStack(alignment: .center, spacing: 0) {
                        let startBeytIndex = pageIndex * beytsPerPage
                        let endBeytIndex = min(startBeytIndex + beytsPerPage, poemData.verses.count)
                        let triggerKey = "\(poemData.id)-\(pageIndex)-\(cardIndex)"
                        
                        ForEach(startBeytIndex..<endBeytIndex, id: \.self) { beytIndex in
                            if beytIndex < poemData.verses.count {
                                let beyt = poemData.verses[beytIndex]
                                let beytOffset = beytIndex - startBeytIndex
                                
                                // Calculate delays: Line 1 of Beyt 1 = 0, Line 2 of Beyt 1 = text1.length * 0.05 + 0.2
                                // Line 1 of Beyt 2 = (text1.length + text2.length) * 0.05 + 0.4, etc.
                                let lineIndex = beytOffset * 2
                                
                                VStack(alignment: .center, spacing: 10) {
                                    // First line of beyt
                                    if beyt.count > 0 {
                                        if displayMode == .typewriter {
                                            let pageKey = "\(poemData.id)-\(pageIndex)-\(cardIndex)"
                                            let isPageCompleted = completedPages.contains(pageKey)
                                            let isLastLine = beytIndex == endBeytIndex - 1 && beyt.count == 1
                                            
                                            TypewriterText(
                                                text: beyt[0],
                                                font: isTranslated ? .custom("Palatino-Roman", size: 16) : .system(size: 14),
                                                color: colorScheme == .dark ? .white : .black,
                                                lineSpacing: isTranslated ? 4 : 14 * 2.66,
                                                kerning: 1,
                                                alignment: .center,
                                                delay: calculateLineDelay(poemData: poemData, startBeytIndex: startBeytIndex, targetBeytIndex: beytIndex, lineIndex: 0),
                                                isCompleted: isPageCompleted,
                                                onComplete: {
                                                    if isLastLine {
                                                        completedPages.insert(pageKey)
                                                    }
                                                }
                                            )
                                            .id("\(triggerKey)-\(beytIndex)-0-\(typewriterTrigger[triggerKey] ?? 0)")
                                        } else {
                                            Text(beyt[0])
                                                .font(isTranslated ? .custom("Palatino-Roman", size: 16) : .system(size: 14))
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .lineSpacing(isTranslated ? 4 : 14 * 2.66)
                                                .kerning(1)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                    
                                    // Second line of beyt
                                    if beyt.count > 1 {
                                        if displayMode == .typewriter {
                                            let pageKey = "\(poemData.id)-\(pageIndex)-\(cardIndex)"
                                            let isPageCompleted = completedPages.contains(pageKey)
                                            let isLastLine = beytIndex == endBeytIndex - 1
                                            
                                            TypewriterText(
                                                text: beyt[1],
                                                font: isTranslated ? .custom("Palatino-Roman", size: 16) : .system(size: 14),
                                                color: colorScheme == .dark ? .white : .black,
                                                lineSpacing: isTranslated ? 4 : 14 * 2.66,
                                                kerning: 1,
                                                alignment: .center,
                                                delay: calculateLineDelay(poemData: poemData, startBeytIndex: startBeytIndex, targetBeytIndex: beytIndex, lineIndex: 1),
                                                isCompleted: isPageCompleted,
                                                onComplete: {
                                                    if isLastLine {
                                                        completedPages.insert(pageKey)
                                                    }
                                                }
                                            )
                                            .id("\(triggerKey)-\(beytIndex)-1-\(typewriterTrigger[triggerKey] ?? 0)")
                                        } else {
                                            Text(beyt[1])
                                                .font(isTranslated ? .custom("Palatino-Roman", size: 16) : .system(size: 14))
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .lineSpacing(isTranslated ? 4 : 14 * 2.66)
                                                .kerning(1)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                }
                                .padding(.bottom, beytIndex < endBeytIndex - 1 ? 24 : 0)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(colorScheme == .dark ? Color(red: 13/255, green: 13/255, blue: 13/255) : Color.white)
                    .cornerRadius(totalPages > 1 ? 0 : 12, corners: [.bottomLeft, .bottomRight])
                    .onAppear {
                        // Trigger typewriter animation when page appears
                        let key = "\(poemData.id)-\(pageIndex)-\(cardIndex)"
                        typewriterTrigger[key] = (typewriterTrigger[key] ?? 0) + 1
                    }
                }
                .id(poemData.id)
                .onChange(of: versePage) { _, newPage in
                    // Trigger typewriter animation when page changes
                    let key = "\(poemData.id)-\(newPage)-\(cardIndex)"
                    typewriterTrigger[key] = (typewriterTrigger[key] ?? 0) + 1
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("در حال بارگذاری...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .background(colorScheme == .dark ? Color(red: 13/255, green: 13/255, blue: 13/255) : Color.white)
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            }
            
            // Page control with bottom corners rounded (only show if more than 1 page)
            let beytsPerPage = 2
            let totalPages = (poemData.verses.count + beytsPerPage - 1) / beytsPerPage
            
            if totalPages > 1 {
                HStack(spacing: 8) {
                    // Reverse the order for Farsi (RTL)
                    let pageRange = selectedLanguage == .farsi ? Array((0..<totalPages).reversed()) : Array(0..<totalPages)
                    ForEach(pageRange, id: \.self) { pageIndex in
                        Circle()
                            .fill(pageIndex == versePage ? (colorScheme == .dark ? Color.white : Color.black) : (colorScheme == .dark ? Color.white : Color.black).opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(colorScheme == .dark ? Color(red: 13/255, green: 13/255, blue: 13/255) : Color.white)
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            }
        }
        .background(colorScheme == .dark ? Color.black : Color(red: 244/255, green: 244/255, blue: 244/255))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// Menu Popover Helper with fade-in animation
struct MenuPopoverHelper: View {
    let selectedLanguage: AppLanguage
    @Binding var showLanguageMenu: Bool
    let selectedDisplayMode: DisplayMode
    @Binding var showConfigureMenu: Bool
    let onSave: () -> Void
    let onShare: () -> Void
    let onSelectText: () -> Void
    let onRefresh: () -> Void
    let onGoToPoet: () -> Void
    let onInterpretation: () -> Void
    let onLanguage: () -> Void
    let onSelectLanguage: (AppLanguage) -> Void
    let onConfigure: () -> Void
    let onSelectDisplayMode: (DisplayMode) -> Void
    let onThemes: () -> Void
    
    @State private var isVisible: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        LiquidGlassMenu(
            isPresented: .constant(true),
            selectedLanguage: selectedLanguage,
            showLanguageMenu: $showLanguageMenu,
            selectedDisplayMode: selectedDisplayMode,
            showConfigureMenu: $showConfigureMenu,
            onSave: onSave,
            onShare: onShare,
            onSelectText: onSelectText,
            onRefresh: onRefresh,
            onGoToPoet: onGoToPoet,
            onInterpretation: onInterpretation,
            onLanguage: onLanguage,
            onSelectLanguage: onSelectLanguage,
            onConfigure: onConfigure,
            onSelectDisplayMode: onSelectDisplayMode,
            onThemes: onThemes
        )
        .opacity(isVisible ? 1 : 0)
        .task {
            try? await Task.sleep(for: .seconds(0.1))
            withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                isVisible = true
            }
        }
        .presentationCompactAdaptation(.popover)
    }
}

// Language Menu Popover
struct LanguageMenuPopover: View {
    @Binding var selectedLanguage: AppLanguage
    let onDismiss: () -> Void
    
    @State private var isVisible: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Quick Actions - Top Section (same as main menu)
            HStack(spacing: 6) {
                // Save Quick Action
                QuickActionButton(
                    id: "save",
                    icon: "bookmark",
                    title: "Save",
                    isHovered: false
                )
                .opacity(0.5)
                
                // Share Quick Action
                QuickActionButton(
                    id: "share",
                    icon: "square.and.arrow.up",
                    title: "Share",
                    isHovered: false
                )
                .opacity(0.5)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 0)
            
            // Menu Items
            VStack(spacing: 0) {
                // Separator
                HStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color(hex: "E6E6E6"))
                        .frame(height: 1)
                }
                .frame(height: 21)
                .padding(.horizontal, 24)
                
                // Refresh (disabled)
                MenuItemView(
                    id: "refresh",
                    icon: "arrow.clockwise",
                    title: "Refresh",
                    isHovered: false
                )
                .opacity(0.5)
                
                // Select text (disabled)
                MenuItemView(
                    id: "selecttext",
                    icon: "document.on.clipboard",
                    title: "Select text",
                    isHovered: false
                )
                .opacity(0.5)
                
                // Go to poet (disabled)
                MenuItemView(
                    id: "poet",
                    icon: "text.page.badge.magnifyingglass",
                    title: "Go to poet",
                    isHovered: false
                )
                .opacity(0.5)
                
                // Separator
                HStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color(hex: "E6E6E6"))
                        .frame(height: 1)
                }
                .frame(height: 21)
                .padding(.horizontal, 24)
                
                // Interpretation (disabled)
                MenuItemView(
                    id: "interpretation",
                    icon: "book.pages",
                    title: "Interpretation",
                    isHovered: false
                )
                .opacity(0.5)
                
                // Separator
                HStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color(hex: "E6E6E6"))
                        .frame(height: 1)
                }
                .frame(height: 21)
                .padding(.horizontal, 24)
                
                // English option
                Button(action: {
                    selectedLanguage = .english
                    onDismiss()
                }) {
                    HStack(spacing: 8) {
                        // Checkmark (24x24 frame with centered icon)
                        ZStack {
                            if selectedLanguage == .english {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                            }
                        }
                        .frame(width: 24, height: 22)
                        
                        // Label
                        VStack(alignment: .leading, spacing: 2) {
                            Text("English")
                                .font(.system(size: 17))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                // Farsi option
                Button(action: {
                    selectedLanguage = .farsi
                    onDismiss()
                }) {
                    HStack(spacing: 8) {
                        // Checkmark (24x24 frame with centered icon)
                        ZStack {
                            if selectedLanguage == .farsi {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                            }
                        }
                        .frame(width: 24, height: 22)
                        
                        // Label
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Farsi")
                                .font(.system(size: 17))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                // Configure (disabled)
                MenuItemView(
                    id: "configure",
                    icon: "textformat",
                    title: "Configure",
                    hasChevron: true,
                    isHovered: false
                )
                .opacity(0.5)
                
                // Themes (disabled)
                MenuItemView(
                    id: "themes",
                    icon: "square.text.square",
                    title: "Themes",
                    hasChevron: true,
                    isHovered: false
                )
                .opacity(0.5)
            }
            .padding(.bottom, 10)
        }
        .frame(width: 238)
        .background(
            LiquidGlassBackground(cornerRadius: 34)
        )
        .opacity(isVisible ? 1 : 0)
        .task {
            try? await Task.sleep(for: .seconds(0.1))
            withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                isVisible = true
            }
        }
    }
}

// Elegant button style with press feedback
struct ElegantButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle()
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.15 : 0))
                    .frame(width: 28, height: 28)
                    .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ProfileView()
}

