import SwiftUI

struct SearchTabContent: View {
    var searchText: String
    @StateObject private var searchHistoryManager = SearchHistoryManager()
    @StateObject private var poetryService = PoetryService()
    @StateObject private var poetService = PoetService()
    @AppStorage("selectedLanguage") private var selectedLanguageRaw = AppLanguage.english.rawValue
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isSearching) var isSearching
    @State private var selectedSearchTab: SearchType = .poems
    @State private var showClearAlert = false
    @State private var poemSearchResults: [PoemData] = []
    @State private var poetSearchResults: [SupabasePoetDetail] = []
    @State private var isSearching_custom = false
    @FocusState private var isSearchFieldFocused: Bool
    
    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: selectedLanguageRaw) ?? .english
    }
    
    private var currentHistory: [SearchHistoryItem] {
        let history = selectedSearchTab == .music ? searchHistoryManager.musicHistory : searchHistoryManager.poemsHistory
        // Sort: Result cards first, then text searches
        return history.sorted { item1, item2 in
            if item1.type == .textSearch && item2.type != .textSearch {
                return false // text searches go after result cards
            } else if item1.type != .textSearch && item2.type == .textSearch {
                return true // result cards go before text searches
            } else {
                return item1.timestamp > item2.timestamp // within same type, sort by timestamp
            }
        }
    }

    var body: some View {
        ZStack {
            // Dynamic background that adapts to light/dark mode
            (colorScheme == .dark ? Color.black : Color(red: 244/255, green: 244/255, blue: 244/255))
                .ignoresSafeArea(.all)
            
            if isSearching || !searchText.isEmpty {
                // Active search mode
                searchModeView
            } else {
                // Default category grid mode
                categoryGridView
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
        .onSubmit {
            // User pressed Enter - save to history as text search
            if !searchText.isEmpty {
                if selectedSearchTab == .poems {
                    searchHistoryManager.addTextSearch(query: searchText, type: .poems)
                } else {
                    searchHistoryManager.addTextSearch(query: searchText, type: .music)
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty {
                performSearch(query: newValue)
            } else {
                poemSearchResults = []
                poetSearchResults = []
                isSearching_custom = false
            }
        }
    }
    
    // MARK: - Category Grid View (Default)
    private var categoryGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                // Poets card - navigates to PoetListView
                NavigationLink(destination: PoetListView()) {
                    VStack {
                        GeometryReader { geometry in
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
                                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
                                
                                VStack(spacing: 12) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(colorScheme == .dark ? Color(hex: "E3B887") : Color(hex: "7A5C39"))
                                    
                                    Text("Poets")
                                        .font(.custom("Palatino", size: 18))
                                        .fontWeight(.semibold)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Placeholder for future categories
                CategoryCard(title: "Topics", icon: "folder.fill") {
                    // TODO: Implement Topics
                }
                .opacity(0.5)
                .disabled(true)
                
                CategoryCard(title: "Collections", icon: "books.vertical.fill") {
                    // TODO: Implement Collections
                }
                .opacity(0.5)
                .disabled(true)
                
                CategoryCard(title: "Eras", icon: "clock.fill") {
                    // TODO: Implement Eras
                }
                .opacity(0.5)
                .disabled(true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Search Mode View
    private var searchModeView: some View {
        VStack(spacing: 0) {
            // Segmented Control
            Picker("Search Type", selection: $selectedSearchTab) {
                Text("Music").tag(SearchType.music)
                Text("Poems").tag(SearchType.poems)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            if searchText.isEmpty {
                // Show recently searched
                if !currentHistory.isEmpty {
                    recentlySearchedView
                } else {
                    emptySearchView
                }
            } else {
                // Show search results
                searchResultsView
            }
        }
    }
    
    // MARK: - Recently Searched View
    private var recentlySearchedView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recently Searched")
                    .font(.custom("Palatino", size: 17))
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                Button("Clear") {
                    showClearAlert = true
                }
                .font(.custom("Palatino", size: 15))
                .foregroundColor(colorScheme == .dark ? Color(hex: "E3B887") : Color(hex: "7A5C39"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            List {
                ForEach(currentHistory) { item in
                    Group {
                        switch item.type {
                        case .textSearch:
                            // Simple text search display
                            Button(action: {
                                // TODO: Could re-trigger search with this query
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary)
                                    Text(item.query ?? "")
                                        .font(.custom("Palatino", size: 16))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    Spacer()
                                }
                            }
                            
                        case .poetResult:
                            // Full poet card display - navigates to PoetDetailView
                            NavigationLink(value: ContentView.PoetRoute(name: selectedLanguage == .farsi ? (item.poetNameFa ?? "") : (item.poetNameEn ?? ""))) {
                                VStack(alignment: selectedLanguage == .farsi ? .trailing : .leading, spacing: 8) {
                                    // Supertitle - language based
                                    Text(selectedLanguage == .farsi ? "شاعر" : "Poet")
                                        .font(.custom("Palatino", size: 12))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    
                                    // Title - show name in selected language
                                    if selectedLanguage == .farsi {
                                        if let nameFa = item.poetNameFa {
                                            Text(nameFa)
                                                .font(.custom("Palatino", size: 18))
                                                .fontWeight(.semibold)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                        }
                                    } else {
                                        if let nameEn = item.poetNameEn {
                                            Text(nameEn)
                                                .font(.custom("Palatino", size: 18))
                                                .fontWeight(.semibold)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                        }
                                    }
                                    
                                    // Subtitle - era
                                    if let era = item.poetEra, !era.isEmpty {
                                        Text(era)
                                            .font(.custom("Palatino", size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                                .padding(.vertical, 4)
                            }
                            
                        case .poemResult:
                            // Full poem card display
                            Button(action: {
                                // Don't navigate anywhere
                            }) {
                                VStack(alignment: selectedLanguage == .farsi ? .trailing : .leading, spacing: 8) {
                                    // Supertitle - poet name (same for both languages)
                                    if let poetName = item.poetName {
                                        Text(poetName)
                                            .font(.custom("Palatino", size: 12))
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)
                                    }
                                    
                                    // Title - poem title
                                    if let title = item.poemTitle {
                                        Text(title)
                                            .font(.custom("Palatino", size: 18))
                                            .fontWeight(.semibold)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }
                                    
                                    // Subtitle - poem text preview
                                    if let text = item.poemText {
                                        Text(text)
                                            .font(.custom("Palatino", size: 15))
                                            .foregroundColor(colorScheme == .dark ? Color(hex: "E3B887").opacity(0.9) : Color(hex: "7A5C39").opacity(0.9))
                                            .lineLimit(3)
                                            .multilineTextAlignment(selectedLanguage == .farsi ? .trailing : .leading)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            searchHistoryManager.removeSearch(item: item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .alert("Clear Searches?", isPresented: $showClearAlert) {
            Button("Clear Searches", role: .destructive) {
                searchHistoryManager.clearHistory(type: selectedSearchTab)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Clearing your searches will remove your search history from the device")
        }
    }
    
    // MARK: - Empty Search View
    private var emptySearchView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedSearchTab == .music ? "music.note.list" : "book.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text(selectedSearchTab == .music ? "Search for music" : "Search for poems or poets")
                .font(.custom("Palatino", size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Search Results View
    private var searchResultsView: some View {
        Group {
            if selectedSearchTab == .poems {
                poemSearchResultsView
            } else {
                musicSearchResultsView
            }
        }
    }
    
    // MARK: - Poem Search Results
    private var poemSearchResultsView: some View {
        List {
            // Debug section
            if isSearching_custom {
                Section {
                    HStack {
                        ProgressView()
                        Text("Searching...")
                            .font(.custom("Palatino", size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Poet results - show both Farsi and English names
            if !poetSearchResults.isEmpty {
                Section {
                    ForEach(poetSearchResults) { poet in
                        NavigationLink(value: ContentView.PoetRoute(name: selectedLanguage == .farsi ? poet.displayNameFa : poet.displayNameEn)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(selectedLanguage == .farsi ? "شاعر" : "Poet")
                                    .font(.custom("Palatino", size: 12))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                // Show both Farsi and English names
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(poet.displayNameFa)
                                        .font(.custom("Palatino", size: 18))
                                        .fontWeight(.semibold)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    
                                    if let nameEn = poet.name_en, !nameEn.isEmpty {
                                        Text(poet.displayNameEn)
                                            .font(.custom("Palatino", size: 16))
                                            .foregroundColor(colorScheme == .dark ? Color(hex: "E3B887").opacity(0.8) : Color(hex: "7A5C39").opacity(0.8))
                                    }
                                }
                                
                                // Show era if available
                                if let era = poet.era, !era.isEmpty {
                                    Text(era)
                                        .font(.custom("Palatino", size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            // Save poet result to search history when user taps
                            searchHistoryManager.addPoetResult(poet: poet, type: selectedSearchTab)
                        })
                    }
                }
            }
            
            // Poem results - show in both languages
            if !poemSearchResults.isEmpty {
                Section {
                    ForEach(poemSearchResults) { poem in
                        Button(action: {
                            // Save poem result to search history when user taps
                            searchHistoryManager.addPoemResult(poem: poem, type: selectedSearchTab)
                            // Don't navigate anywhere - as requested
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(poem.poet.name)
                                    .font(.custom("Palatino", size: 12))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(poem.title)
                                    .font(.custom("Palatino", size: 18))
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                
                                Text(poem.poem_text)
                                    .font(.custom("Palatino", size: 15))
                                    .foregroundColor(colorScheme == .dark ? Color(hex: "E3B887").opacity(0.9) : Color(hex: "7A5C39").opacity(0.9))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            if poetSearchResults.isEmpty && poemSearchResults.isEmpty && !isSearching_custom {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No results found")
                            .font(.custom("Palatino", size: 18))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Music Search Results (Placeholder)
    private var musicSearchResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("Music search coming soon")
                .font(.custom("Palatino", size: 18))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Search Functions
    private func performSearch(query: String) {
        guard !query.isEmpty else { return }
        
        isSearching_custom = true
        
        if selectedSearchTab == .poems {
            Task {
                // Fetch poets if not already loaded
                if poetService.poets.isEmpty {
                    await poetService.fetchPoets()
                }
                
                // Search poets in BOTH languages
                let filteredPoets = poetService.poets.filter { poet in
                    poet.displayNameFa.localizedCaseInsensitiveContains(query) ||
                    poet.displayNameEn.localizedCaseInsensitiveContains(query) ||
                    (poet.name_fa.localizedCaseInsensitiveContains(query)) ||
                    (poet.name_en?.localizedCaseInsensitiveContains(query) ?? false)
                }
                
                // Search poems in BOTH languages
                do {
                    print("🔍 Starting poem search for query: \(query)")
                    let farsiPoems = try await poetryService.searchPoems(query: query, language: .farsi)
                    print("🔍 Farsi poems found: \(farsiPoems.count)")
                    
                    let englishPoems = try await poetryService.searchPoems(query: query, language: .english)
                    print("🔍 English poems found: \(englishPoems.count)")
                    
                    // Combine and deduplicate poems by ID
                    var uniquePoems: [Int: PoemData] = [:]
                    for poem in farsiPoems + englishPoems {
                        uniquePoems[poem.id] = poem
                    }
                    let combinedPoems = Array(uniquePoems.values)
                    print("🔍 Total unique poems: \(combinedPoems.count)")
                    
                    await MainActor.run {
                        self.poetSearchResults = filteredPoets
                        self.poemSearchResults = combinedPoems
                        self.isSearching_custom = false
                        print("🔍 Updated UI - Poets: \(filteredPoets.count), Poems: \(combinedPoems.count)")
                    }
                } catch {
                    print("❌ Search error: \(error)")
                    print("❌ Error details: \(String(describing: error))")
                    await MainActor.run {
                        self.poetSearchResults = filteredPoets
                        self.poemSearchResults = []
                        self.isSearching_custom = false
                    }
                }
            }
        } else {
            // Music search - placeholder
            isSearching_custom = false
        }
    }
}
