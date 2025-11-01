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
    
    /// Returns the SwiftUI layout direction for this language
    var layoutDirection: LayoutDirection {
        switch self {
        case .farsi:
            return .rightToLeft
        case .english:
            return .leftToRight
        }
    }
    
    /// Returns the horizontal alignment for this language
    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .farsi:
            return .trailing
        case .english:
            return .leading
        }
    }
    
    /// Returns the text alignment for this language
    var textAlignment: TextAlignment {
        switch self {
        case .farsi:
            return .trailing
        case .english:
            return .leading
        }
    }
    
    /// Returns the frame alignment for this language (used in .frame(alignment:))
    var frameAlignment: Alignment {
        switch self {
        case .farsi:
            return .trailing
        case .english:
            return .leading
        }
    }
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
    @State private var showExplanations: [Int: Bool] = [:] // Show line-by-line explanations per poem ID
    @State private var showDeepAnalysisSheet = false // Control Deep Analysis bottom sheet
    
    // Initialize with saved display mode preference
    init() {
        let savedMode = UserDefaults.standard.string(forKey: "displayMode") ?? DisplayMode.staticMode.rawValue
        _selectedDisplayMode = State(initialValue: DisplayMode(rawValue: savedMode) ?? .staticMode)
    }
    
    // Multiple poems from API
    @State private var allPoems: [PoemData] = [] // All fetched poems
    @State private var displayedPoems: [PoemData] = [] // Currently displayed poems (sets of 10)
    @State private var currentPageSet = 0 // Current set of 10 poems
    @State private var isLoadingMore = false // Loading state for pagination
    @State private var hasMorePoems = true // Whether there are more poems to load
    @State private var viewedPoemIds: Set<Int> = [] // Track viewed poems for refresh logic
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
            for poem in displayedPoems {
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
            allPoems = []
            displayedPoems = []
            translatedPoems = [:]
            viewedPoemIds.removeAll()
            currentPageSet = 0
            completedTypewriterPages.removeAll() // Clear completed pages on refresh
            
            // Fetch new poems from Supabase
            let newPoems = await poetryService.fetchPoems(limit: 100, offset: 0)
            if !newPoems.isEmpty {
                // Shuffle poems for random order
                var shuffledPoems = newPoems
                shuffledPoems.shuffle()
                allPoems = shuffledPoems
                updateDisplayedPoems()
                currentPage = 0
                
                // Automatic translation disabled
                // translatePoemsIfNeeded()
            }
        }
        
        // Hide toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showToast = false
        }
    }
    
    // Update displayed poems based on current page set
    private func updateDisplayedPoems() {
        let poemsPerSet = 10
        let startIndex = currentPageSet * poemsPerSet
        let endIndex = min(startIndex + poemsPerSet, allPoems.count)
        
        if startIndex < allPoems.count {
            // Show all poems from start to endIndex (cumulative)
            displayedPoems = Array(allPoems[0..<endIndex])
            hasMorePoems = endIndex < allPoems.count
        } else {
            displayedPoems = []
            hasMorePoems = false
        }
    }
    
    // Load next set of poems
    private func loadNextSet() {
        guard !isLoadingMore && hasMorePoems else { return }
        
        isLoadingMore = true
        
        Task {
            // If we have more poems in our current batch, just show them
            if (currentPageSet + 1) * 10 < allPoems.count {
                currentPageSet += 1
                updateDisplayedPoems()
            } else {
                // Need to fetch more poems from server
                let nextOffset = allPoems.count
                let newPoems = await poetryService.fetchPoems(limit: 100, offset: nextOffset)
                
                if !newPoems.isEmpty {
                    // Shuffle new poems and append to existing ones
                    var shuffledNewPoems = newPoems
                    shuffledNewPoems.shuffle()
                    allPoems.append(contentsOf: shuffledNewPoems)
                    currentPageSet += 1
                    updateDisplayedPoems()
                } else {
                    hasMorePoems = false
                }
            }
            
            isLoadingMore = false
        }
    }
    
    var body: some View {
        ZStack {
            // Background - adapts to dark mode
            (colorScheme == .dark ? Color.black : Color(red: 244/255, green: 244/255, blue: 244/255))
                .ignoresSafeArea()
            
            // Paging carousel with peek of adjacent cards
            VStack(spacing: 0) {
                if displayedPoems.isEmpty {
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
                            cardIndex: index,
                            showExplanations: Binding(
                                get: { showExplanations[index] ?? false },
                                set: { showExplanations[index] = $0 }
                            ),
                            showDeepAnalysisSheet: $showDeepAnalysisSheet
                        )
                        .id("\(selectedDisplayMode.rawValue)-\(index)")
                    }, currentPage: $currentPage)
                } else if selectedLanguage == .farsi {
                    // Show Farsi poems - use fresh data from farsiPoems if available (has tafseer), otherwise use displayedPoems
                    let farsiPoemsList = displayedPoems.map { poem -> PoemData in
                        // Use fresh Farsi poem with tafseer if available, otherwise use cached poem
                        if let freshPoem = poetryService.farsiPoems[poem.id] {
                            return freshPoem
                        }
                        return poem
                    }
                    
                    PagingScrollView(pageCount: farsiPoemsList.count, content: { index in
                        PoemCardView(
                            poem: farsiPoemsList[index],
                            isTranslated: false,
                            selectedLanguage: .farsi,
                            displayMode: selectedDisplayMode,
                            toFarsiNumber: toFarsiNumber,
                            showMenu: $showMenu,
                            activeCardIndex: $activeCardIndex,
                            typewriterTrigger: $typewriterTrigger,
                            completedPages: $completedTypewriterPages,
                            menuNamespace: menuNamespace,
                            cardIndex: index,
                            showExplanations: Binding(
                                get: { showExplanations[farsiPoemsList[index].id] ?? false },
                                set: { showExplanations[farsiPoemsList[index].id] = $0 }
                            ),
                            showDeepAnalysisSheet: $showDeepAnalysisSheet
                        )
                        .id("\(selectedDisplayMode.rawValue)-\(index)")
                    }, currentPage: $currentPage, onLoadMore: {
                        loadNextSet()
                    })
                } else {
                    // Show English poems from Supabase
                    let englishPoemsList = displayedPoems.compactMap { poem -> PoemData? in
                        poetryService.englishPoems[poem.id]
                    }
                    
                    if englishPoemsList.count == displayedPoems.count {
                        // All poems have English translations
                        PagingScrollView(pageCount: englishPoemsList.count, content: { index in
                            PoemCardView(
                                poem: englishPoemsList[index],
                                isTranslated: true,
                                selectedLanguage: .english,
                                displayMode: selectedDisplayMode,
                                toFarsiNumber: toFarsiNumber,
                                showMenu: $showMenu,
                                activeCardIndex: $activeCardIndex,
                                typewriterTrigger: $typewriterTrigger,
                                completedPages: $completedTypewriterPages,
                                menuNamespace: menuNamespace,
                                cardIndex: index,
                                showExplanations: Binding(
                                    get: { showExplanations[englishPoemsList[index].id] ?? false },
                                    set: { showExplanations[englishPoemsList[index].id] = $0 }
                                ),
                                showDeepAnalysisSheet: $showDeepAnalysisSheet
                            )
                            .id("\(selectedDisplayMode.rawValue)-\(index)")
                        }, currentPage: $currentPage, onLoadMore: {
                            loadNextSet()
                        })
                    } else {
                        // Some translations missing, show Farsi
                        PagingScrollView(pageCount: displayedPoems.count, content: { index in
                            PoemCardView(
                                poem: displayedPoems[index],
                                isTranslated: false,
                                selectedLanguage: .farsi,
                                displayMode: selectedDisplayMode,
                                toFarsiNumber: toFarsiNumber,
                                showMenu: $showMenu,
                                activeCardIndex: $activeCardIndex,
                                typewriterTrigger: $typewriterTrigger,
                                completedPages: $completedTypewriterPages,
                                menuNamespace: menuNamespace,
                                cardIndex: index,
                                showExplanations: Binding(
                                    get: { showExplanations[displayedPoems[index].id] ?? false },
                                    set: { showExplanations[displayedPoems[index].id] = $0 }
                                ),
                                showDeepAnalysisSheet: $showDeepAnalysisSheet
                            )
                            .id("\(selectedDisplayMode.rawValue)-\(index)")
                        }, currentPage: $currentPage, onLoadMore: {
                            loadNextSet()
                        })
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
                    showExplanations: {
                        // Get current poem ID for active card
                        let currentPoemId: Int
                        if selectedLanguage == .farsi && activeCardIndex < displayedPoems.count {
                            currentPoemId = displayedPoems[activeCardIndex].id
                        } else if selectedLanguage == .english {
                            let englishPoemsList = displayedPoems.compactMap { poem -> PoemData? in
                                poetryService.englishPoems[poem.id]
                            }
                            if activeCardIndex < englishPoemsList.count {
                                currentPoemId = englishPoemsList[activeCardIndex].id
                            } else if activeCardIndex < displayedPoems.count {
                                currentPoemId = displayedPoems[activeCardIndex].id
                            } else {
                                return false
                            }
                        } else {
                            return false
                        }
                        return showExplanations[currentPoemId] ?? false
                    }(),
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
                            // Reset explanations when language changes to ensure fresh state
                            showExplanations.removeAll()
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
                    },
                    onSimplyExplained: {
                        // Toggle showExplanations for the current active card
                        let currentPoemId: Int
                        if selectedLanguage == .farsi && activeCardIndex < displayedPoems.count {
                            currentPoemId = displayedPoems[activeCardIndex].id
                        } else if selectedLanguage == .english {
                            let englishPoemsList = displayedPoems.compactMap { poem -> PoemData? in
                                poetryService.englishPoems[poem.id]
                            }
                            if activeCardIndex < englishPoemsList.count {
                                currentPoemId = englishPoemsList[activeCardIndex].id
                            } else if activeCardIndex < displayedPoems.count {
                                currentPoemId = displayedPoems[activeCardIndex].id
                            } else {
                                return
                            }
                        } else {
                            return
                        }
                        
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showExplanations[currentPoemId] = !(showExplanations[currentPoemId] ?? false)
                            showMenu = false
                            showLanguageMenu = false
                            showConfigureMenu = false
                        }
                    },
                    onDeepAnalysis: {
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showDeepAnalysisSheet = true
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
        .sheet(isPresented: $showDeepAnalysisSheet) {
            Group {
                // Get current poem for tafseer
                let currentPoem: PoemData? = {
                    if selectedLanguage == .farsi {
                        // Build Farsi poems list (with fresh tafseer data if available)
                        let farsiPoemsList = displayedPoems.map { poem -> PoemData in
                            if let freshPoem = poetryService.farsiPoems[poem.id] {
                                return freshPoem
                            }
                            return poem
                        }
                        
                        // Use currentPage to get the currently displayed poem
                        if currentPage < farsiPoemsList.count {
                            return farsiPoemsList[currentPage]
                        }
                        return nil
                    } else if selectedLanguage == .english {
                        let englishPoemsList = displayedPoems.compactMap { poem -> PoemData? in
                            poetryService.englishPoems[poem.id]
                        }
                        
                        // Use currentPage to get the currently displayed poem
                        if currentPage < englishPoemsList.count {
                            return englishPoemsList[currentPage]
                        }
                        // Fallback: if English poems aren't ready, use Farsi
                        if currentPage < displayedPoems.count {
                            return displayedPoems[currentPage]
                        }
                        return nil
                    } else {
                        return nil
                    }
                }()
                
                if let poem = currentPoem {
                    DeepAnalysisBottomSheet(poem: poem, selectedLanguage: selectedLanguage)
                        .presentationDetents([.fraction(0.75), .large])
                        .presentationDragIndicator(.hidden)
                        .presentationCornerRadius(20)
                } else {
                    Text("No poem data available")
                        .font(.system(size: 17))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .presentationDetents([.fraction(0.75), .large])
                        .presentationDragIndicator(.hidden)
                        .presentationCornerRadius(20)
                }
            }
        }
        .navigationBarHidden(true)
        .animation(.snappy(duration: 0.3, extraBounce: 0), value: showMenu)
        .onAppear {
            // Only fetch poems if they haven't been loaded yet (fresh app launch)
            if allPoems.isEmpty {
                Task {
                    let initialPoems = await poetryService.fetchPoems(limit: 100, offset: 0)
                    
                    // Shuffle poems for random order on fresh launch
                    if !initialPoems.isEmpty {
                        var shuffledPoems = initialPoems
                        shuffledPoems.shuffle()
                        allPoems = shuffledPoems
                        updateDisplayedPoems()
                        currentPage = 0
                        print("🔀 Loaded and shuffled \(shuffledPoems.count) fresh poems")
                        
                        // Automatic translation disabled
                        // translatePoemsIfNeeded()
                    }
                }
            } else {
                // Poems already loaded - user is just switching back to this tab
                // Position is preserved automatically via @State
                print("📖 Returning to saved position: \(currentPage)")
            }
        }
        .onChange(of: currentPage) { _, newPage in
            // Reset verse page when changing cards
            if newPage < displayedPoems.count {
                versePage = 0
                
                // Track viewed poems
                if newPage < displayedPoems.count {
                    viewedPoemIds.insert(displayedPoems[newPage].id)
                }
                
                // Check if we need to load more poems
                if newPage >= displayedPoems.count - 2 && hasMorePoems && !isLoadingMore {
                    loadNextSet()
                }
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
                                    HStack {
                                        Spacer()
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .frame(width: 32, height: 32)
                                }
                                .buttonStyle(.plain)
                                
                                // Save/Bookmark button - commented out
                                /*
                                Button(action: {}) {
                HStack {
                                        Spacer()
                                        Image(systemName: "bookmark")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .frame(width: 32, height: 32)
                                }
                                .buttonStyle(.plain)
                                */
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
                                // Save/Bookmark button - commented out
                                /*
                                Button(action: {}) {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "bookmark")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .frame(width: 32, height: 32)
                                }
                                .buttonStyle(.plain)
                                */
                                
                                Button(action: {}) {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .frame(width: 32, height: 32)
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
    @Binding var showExplanations: Bool // Show line-by-line explanations
    @Binding var showDeepAnalysisSheet: Bool // Control Deep Analysis bottom sheet
    
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
                .onChange(of: colorScheme) { _, _ in
                    // Force re-render when color scheme changes to update backgrounds
                    // This ensures PageCurlView and other components update their backgrounds
                }
        }
    }
    
    private var poemHeader: some View {
        let poemData = poem!
        
        return VStack(spacing: 0) {
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
                                        .frame(width: 32, height: 32)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(CircularButtonStyle())
                                .matchedTransitionSource(id: "MENUCONTENT\(cardIndex)", in: menuNamespace)
                                
                                // Lightbulb icon (to the right of ellipsis) - always visible
                                Button(action: {
                                    // Toggle explanations with spring animation
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        showExplanations.toggle()
                                    }
                                }) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(showExplanations ? .yellow : .primary)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(CircularButtonStyle())
                                
                                // Uncover Meaning icon - opens deep analysis bottom sheet
                                Button(action: {
                                    withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                                        showDeepAnalysisSheet = true
                                    }
                                }) {
                                    Image(systemName: "book.pages")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(CircularButtonStyle())
                                
                                // Save/Bookmark button - commented out
                                /*
                                Button(action: {}) {
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(CircularButtonStyle())
                                */
                            }
                            
                            Spacer()
                            
                            // Title and poet (right side in Farsi)
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(poemData.title)
                                    .font(.custom("Palatino-Roman", size: 16))
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
                                    .font(.custom("Palatino-Roman", size: 16))
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
                                // Save/Bookmark button - commented out
                                /*
                                Button(action: {}) {
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(CircularButtonStyle())
                                */
                                
                                // Uncover Meaning icon - opens deep analysis bottom sheet (to the left of lightbulb)
                                Button(action: {
                                    withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                                        showDeepAnalysisSheet = true
                                    }
                                }) {
                                    Image(systemName: "book.pages")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(CircularButtonStyle())
                                
                                // Lightbulb icon (to the left of ellipsis) - always visible
                                Button(action: {
                                    // Toggle explanations with spring animation
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        showExplanations.toggle()
                                    }
                                }) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(showExplanations ? .yellow : .primary)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(CircularButtonStyle())
                                
                                Button(action: {
                                    activeCardIndex = cardIndex
                                    withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                                        showMenu.toggle()
                                    }
                                }) {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(CircularButtonStyle())
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
    }
    
    @ViewBuilder
    private func buildPageContent(poemData: PoemData, pageIndex: Int, beytsPerPage: Int) -> some View {
        let vStackAlignment: HorizontalAlignment = showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center
        
        VStack(alignment: vStackAlignment, spacing: 0) {
            let startBeytIndex = pageIndex * beytsPerPage
            let endBeytIndex = min(startBeytIndex + beytsPerPage, poemData.verses.count)
            let triggerKey = "\(poemData.id)-\(pageIndex)-\(cardIndex)"
            
            ForEach(Array(startBeytIndex..<endBeytIndex), id: \.self) { beytIndex in
                if beytIndex < poemData.verses.count {
                    let beyt = poemData.verses[beytIndex]
                    let beytOffset = beytIndex - startBeytIndex
                    
                    // Calculate delays: Line 1 of Beyt 1 = 0, Line 2 of Beyt 1 = text1.length * 0.05 + 0.2
                    // Line 1 of Beyt 2 = (text1.length + text2.length) * 0.05 + 0.4, etc.
                    let lineIndex = beytOffset * 2
                    
                    VStack(alignment: vStackAlignment, spacing: 10) {
                        // First line of beyt with its own vertical line
                        if beyt.count > 0 {
                            if showExplanations {
                                // Wrap line 1 + explanation in HStack with vertical line
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: vStackAlignment, spacing: 0) {
                                        if displayMode == .typewriter {
                                            let pageKey = "\(poemData.id)-\(pageIndex)-\(cardIndex)"
                                            let isPageCompleted = completedPages.contains(pageKey)
                                            let isLastLine = beytIndex == endBeytIndex - 1 && beyt.count == 1
                                            
                                            TypewriterText(
                                                text: beyt[0],
                                                font: isTranslated ? .custom("Palatino-Roman", size: 16) : .custom("Palatino", size: 16),
                                                color: colorScheme == .dark ? .white : .black,
                                                lineSpacing: isTranslated ? 4 : 14 * 2.66,
                                                kerning: 1,
                                                alignment: showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center,
                                                delay: calculateLineDelay(poemData: poemData, startBeytIndex: startBeytIndex, targetBeytIndex: beytIndex, lineIndex: 0),
                                                isCompleted: isPageCompleted,
                                                onComplete: {
                                                    if isLastLine {
                                                        completedPages.insert(pageKey)
                                                    }
                                                }
                                            )
                                            .frame(maxWidth: .infinity, alignment: showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center)
                                            .id("\(triggerKey)-\(beytIndex)-0-\(typewriterTrigger[triggerKey] ?? 0)")
                                        } else {
                                            Text(beyt[0])
                                                .font(isTranslated ? .custom("Palatino-Roman", size: 16) : .custom("Palatino", size: 16))
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .lineSpacing(isTranslated ? 4 : 14 * 2.66)
                                                .kerning(1)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .multilineTextAlignment(showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center)
                                                .frame(maxWidth: .infinity, alignment: showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center)
                                        }
                                        
                                        // Show explanation for line 1 if enabled
                                        if showExplanations {
                                            let tafseer = selectedLanguage == .farsi ? poemData.tafseerLineByLineFa : poemData.tafseerLineByLineEn
                                            if let tafseer = tafseer {
                                                if beytIndex * 2 < tafseer.count {
                                                    let explanation = tafseer[beytIndex * 2].explanation
                                                    if !explanation.isEmpty {
                                                        Text(explanation)
                                                            .font(.custom("Palatino", size: selectedLanguage == .farsi ? 14 : 13))
                                                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                                                            .multilineTextAlignment(selectedLanguage == .farsi ? .trailing : .leading)
                                                            .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                                                            .padding(.top, 8)
                                                            .transition(.asymmetric(
                                                                insertion: .move(edge: .top).combined(with: .opacity),
                                                                removal: .move(edge: .top).combined(with: .opacity)
                                                            ))
                                                            .id("exp-line1-\(beytIndex)")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .background(
                                        GeometryReader { geometry in
                                            if selectedLanguage == .english {
                                                Rectangle()
                                                    .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                                                    .frame(width: 1, height: geometry.size.height)
                                                    .offset(x: -12)
                                            } else {
                                                Rectangle()
                                                    .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                                                    .frame(width: 1, height: geometry.size.height)
                                                    .offset(x: geometry.size.width + 12)
                                            }
                                        }
                                    )
                                }
                            } else {
                                // No vertical line when explanations are off
                                if displayMode == .typewriter {
                                    let pageKey = "\(poemData.id)-\(pageIndex)-\(cardIndex)"
                                    let isPageCompleted = completedPages.contains(pageKey)
                                    let isLastLine = beytIndex == endBeytIndex - 1 && beyt.count == 1
                                    
                                    TypewriterText(
                                        text: beyt[0],
                                        font: isTranslated ? .custom("Palatino-Roman", size: 16) : .custom("Palatino", size: 16),
                                        color: colorScheme == .dark ? .white : .black,
                                        lineSpacing: isTranslated ? 4 : 14 * 2.66,
                                        kerning: 1,
                                        alignment: showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center,
                                        delay: calculateLineDelay(poemData: poemData, startBeytIndex: startBeytIndex, targetBeytIndex: beytIndex, lineIndex: 0),
                                        isCompleted: isPageCompleted,
                                        onComplete: {
                                            if isLastLine {
                                                completedPages.insert(pageKey)
                                            }
                                        }
                                    )
                                    .frame(maxWidth: .infinity, alignment: showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center)
                                    .id("\(triggerKey)-\(beytIndex)-0-\(typewriterTrigger[triggerKey] ?? 0)")
                                } else {
                                    Text(beyt[0])
                                        .font(isTranslated ? .custom("Palatino-Roman", size: 16) : .custom("Palatino", size: 16))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .lineSpacing(isTranslated ? 4 : 14 * 2.66)
                                        .kerning(1)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .multilineTextAlignment(showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center)
                                        .frame(maxWidth: .infinity, alignment: showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center)
                                }
                            }
                        }
                        
                        // Second line of beyt with its own vertical line
                        if beyt.count > 1 {
                            if showExplanations {
                                // Wrap line 2 + explanation in HStack with vertical line
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: vStackAlignment, spacing: 0) {
                                        if displayMode == .typewriter {
                                            let pageKey = "\(poemData.id)-\(pageIndex)-\(cardIndex)"
                                            let isPageCompleted = completedPages.contains(pageKey)
                                            let isLastLine = beytIndex == endBeytIndex - 1
                                            
                                            TypewriterText(
                                                text: beyt[1],
                                                font: isTranslated ? .custom("Palatino-Roman", size: 16) : .custom("Palatino", size: 16),
                                                color: colorScheme == .dark ? .white : .black,
                                                lineSpacing: isTranslated ? 4 : 14 * 2.66,
                                                kerning: 1,
                                                alignment: showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center,
                                                delay: calculateLineDelay(poemData: poemData, startBeytIndex: startBeytIndex, targetBeytIndex: beytIndex, lineIndex: 1),
                                                isCompleted: isPageCompleted,
                                                onComplete: {
                                                    if isLastLine {
                                                        completedPages.insert(pageKey)
                                                    }
                                                }
                                            )
                                            .frame(maxWidth: .infinity, alignment: showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center)
                                            .id("\(triggerKey)-\(beytIndex)-1-\(typewriterTrigger[triggerKey] ?? 0)")
                                        } else {
                                            Text(beyt[1])
                                                .font(isTranslated ? .custom("Palatino-Roman", size: 16) : .custom("Palatino", size: 16))
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .lineSpacing(isTranslated ? 4 : 14 * 2.66)
                                                .kerning(1)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .multilineTextAlignment(showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center)
                                                .frame(maxWidth: .infinity, alignment: showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center)
                                        }
                                        
                                        // Show explanation for line 2 if enabled
                                        if showExplanations {
                                            let tafseer = selectedLanguage == .farsi ? poemData.tafseerLineByLineFa : poemData.tafseerLineByLineEn
                                            if let tafseer = tafseer {
                                                if beytIndex * 2 + 1 < tafseer.count {
                                                    let explanation = tafseer[beytIndex * 2 + 1].explanation
                                                    if !explanation.isEmpty {
                                                        Text(explanation)
                                                            .font(.custom("Palatino", size: selectedLanguage == .farsi ? 14 : 13))
                                                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                                                            .multilineTextAlignment(selectedLanguage == .farsi ? .trailing : .leading)
                                                            .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                                                            .padding(.top, 8)
                                                            .transition(.asymmetric(
                                                                insertion: .move(edge: .top).combined(with: .opacity),
                                                                removal: .move(edge: .top).combined(with: .opacity)
                                                            ))
                                                            .id("exp-line2-\(beytIndex)")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .background(
                                        GeometryReader { geometry in
                                            if selectedLanguage == .english {
                                                Rectangle()
                                                    .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                                                    .frame(width: 1, height: geometry.size.height)
                                                    .offset(x: -12)
                                            } else {
                                                Rectangle()
                                                    .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                                                    .frame(width: 1, height: geometry.size.height)
                                                    .offset(x: geometry.size.width + 12)
                                            }
                                        }
                                    )
                                }
                            } else {
                                // No vertical line when explanations are off
                                if displayMode == .typewriter {
                                    let pageKey = "\(poemData.id)-\(pageIndex)-\(cardIndex)"
                                    let isPageCompleted = completedPages.contains(pageKey)
                                    let isLastLine = beytIndex == endBeytIndex - 1
                                    
                                    TypewriterText(
                                        text: beyt[1],
                                        font: isTranslated ? .custom("Palatino-Roman", size: 16) : .custom("Palatino", size: 16),
                                        color: colorScheme == .dark ? .white : .black,
                                        lineSpacing: isTranslated ? 4 : 14 * 2.66,
                                        kerning: 1,
                                        alignment: showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center,
                                        delay: calculateLineDelay(poemData: poemData, startBeytIndex: startBeytIndex, targetBeytIndex: beytIndex, lineIndex: 1),
                                        isCompleted: isPageCompleted,
                                        onComplete: {
                                            if isLastLine {
                                                completedPages.insert(pageKey)
                                            }
                                        }
                                    )
                                    .frame(maxWidth: .infinity, alignment: showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center)
                                    .id("\(triggerKey)-\(beytIndex)-1-\(typewriterTrigger[triggerKey] ?? 0)")
                                } else {
                                    Text(beyt[1])
                                        .font(isTranslated ? .custom("Palatino-Roman", size: 16) : .custom("Palatino", size: 16))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .lineSpacing(isTranslated ? 4 : 14 * 2.66)
                                        .kerning(1)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .multilineTextAlignment(showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center)
                                        .frame(maxWidth: .infinity, alignment: showExplanations ? (selectedLanguage == .farsi ? .trailing : .leading) : .center)
                                }
                            }
                        }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showExplanations)
                    .padding(.bottom, beytIndex < endBeytIndex - 1 ? 24 : 0)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(colorScheme == .dark ? Color(red: 13/255, green: 13/255, blue: 13/255) : Color.white)
        .cornerRadius((poemData.verses.count + beytsPerPage - 1) / beytsPerPage > 1 ? 0 : 12, corners: [.bottomLeft, .bottomRight])
        .onAppear {
            // Trigger typewriter animation when page appears
            let key = "\(poemData.id)-\(pageIndex)-\(cardIndex)"
            typewriterTrigger[key] = (typewriterTrigger[key] ?? 0) + 1
        }
    }
    
    private var poemContent: some View {
        let poemData = poem!
        let beytsPerPage = 2
        let totalPages = (poemData.verses.count + beytsPerPage - 1) / beytsPerPage
        // Include language in contentVersion so view rebuilds when language changes
        let contentVersion = (showExplanations ? 1 : 0) + (selectedLanguage == .farsi ? 10 : 20)
        
        return Group {
            if !poemData.verses.isEmpty {
                PageCurlView(currentPage: $versePage, pageCount: totalPages, isRTL: selectedLanguage == .farsi, content: { pageIndex in
                    buildPageContent(poemData: poemData, pageIndex: pageIndex, beytsPerPage: beytsPerPage)
                }, contentVersion: contentVersion)
                .id("\(poemData.id)-\(colorScheme)-\(showExplanations)-\(selectedLanguage)")
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
    }
    
    private var actualPoemView: some View {
        VStack(spacing: 8) {
            poemHeader
            poemContent
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
    let showExplanations: Bool
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
    let onSimplyExplained: () -> Void
    let onDeepAnalysis: () -> Void
    
    @State private var isVisible: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        LiquidGlassMenu(
            isPresented: .constant(true),
            selectedLanguage: selectedLanguage,
            showLanguageMenu: $showLanguageMenu,
            selectedDisplayMode: selectedDisplayMode,
            showConfigureMenu: $showConfigureMenu,
            showExplanations: showExplanations,
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
            onThemes: onThemes,
            onSimplyExplained: onSimplyExplained,
            onDeepAnalysis: onDeepAnalysis
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

// Circular button style for 32x32 tap targets
struct CircularButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle()
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.15 : 0))
                    .frame(width: 32, height: 32)
                    .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ProfileView()
}

