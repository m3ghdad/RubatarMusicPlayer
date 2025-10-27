//
//  SearchHistory.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/27/25.
//

import Foundation
import Combine

enum SearchHistoryItemType: String, Codable {
    case textSearch       // User typed and pressed Enter
    case poetResult      // User tapped a poet from results
    case poemResult      // User tapped a poem from results
}

struct SearchHistoryItem: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let type: SearchHistoryItemType
    let searchType: SearchType // Music or Poems
    
    // For text searches
    var query: String?
    
    // For poet results
    var poetId: String?
    var poetNameFa: String?
    var poetNameEn: String?
    var poetEra: String?
    
    // For poem results
    var poemId: Int?
    var poemTitle: String?
    var poemText: String?
    var poetName: String?
    
    init(id: UUID = UUID(), timestamp: Date = Date(), searchType: SearchType, query: String) {
        self.id = id
        self.timestamp = timestamp
        self.type = .textSearch
        self.searchType = searchType
        self.query = query
    }
    
    init(id: UUID = UUID(), timestamp: Date = Date(), searchType: SearchType, poet: SupabasePoetDetail) {
        self.id = id
        self.timestamp = timestamp
        self.type = .poetResult
        self.searchType = searchType
        self.poetId = poet.id
        self.poetNameFa = poet.displayNameFa
        self.poetNameEn = poet.displayNameEn
        self.poetEra = poet.era
    }
    
    init(id: UUID = UUID(), timestamp: Date = Date(), searchType: SearchType, poem: PoemData) {
        self.id = id
        self.timestamp = timestamp
        self.type = .poemResult
        self.searchType = searchType
        self.poemId = poem.id
        self.poemTitle = poem.title
        self.poemText = poem.poem_text
        self.poetName = poem.poet.name
    }
}

enum SearchType: String, Codable {
    case music
    case poems
}

class SearchHistoryManager: ObservableObject {
    @Published var musicHistory: [SearchHistoryItem] = []
    @Published var poemsHistory: [SearchHistoryItem] = []
    
    private let musicKey = "musicSearchHistory"
    private let poemsKey = "poemsSearchHistory"
    
    init() {
        loadHistory()
    }
    
    // Add text search (when user presses Enter)
    func addTextSearch(query: String, type: SearchType) {
        let item = SearchHistoryItem(searchType: type, query: query)
        addItem(item, to: type)
    }
    
    // Add poet result (when user taps a poet)
    func addPoetResult(poet: SupabasePoetDetail, type: SearchType) {
        let item = SearchHistoryItem(searchType: type, poet: poet)
        addItem(item, to: type)
    }
    
    // Add poem result (when user taps a poem)
    func addPoemResult(poem: PoemData, type: SearchType) {
        let item = SearchHistoryItem(searchType: type, poem: poem)
        addItem(item, to: type)
    }
    
    private func addItem(_ item: SearchHistoryItem, to type: SearchType) {
        switch type {
        case .music:
            // Remove duplicate if exists
            if item.type == .textSearch, let query = item.query {
                musicHistory.removeAll { $0.type == .textSearch && $0.query == query }
            } else if item.type == .poetResult, let poetId = item.poetId {
                musicHistory.removeAll { $0.type == .poetResult && $0.poetId == poetId }
            } else if item.type == .poemResult, let poemId = item.poemId {
                musicHistory.removeAll { $0.type == .poemResult && $0.poemId == poemId }
            }
            
            musicHistory.insert(item, at: 0)
            if musicHistory.count > 30 {
                musicHistory = Array(musicHistory.prefix(30))
            }
        case .poems:
            // Remove duplicate if exists
            if item.type == .textSearch, let query = item.query {
                poemsHistory.removeAll { $0.type == .textSearch && $0.query == query }
            } else if item.type == .poetResult, let poetId = item.poetId {
                poemsHistory.removeAll { $0.type == .poetResult && $0.poetId == poetId }
            } else if item.type == .poemResult, let poemId = item.poemId {
                poemsHistory.removeAll { $0.type == .poemResult && $0.poemId == poemId }
            }
            
            poemsHistory.insert(item, at: 0)
            if poemsHistory.count > 30 {
                poemsHistory = Array(poemsHistory.prefix(30))
            }
        }
        
        saveHistory()
    }
    
    func removeSearch(item: SearchHistoryItem) {
        switch item.searchType {
        case .music:
            musicHistory.removeAll { $0.id == item.id }
        case .poems:
            poemsHistory.removeAll { $0.id == item.id }
        }
        saveHistory()
    }
    
    func clearHistory(type: SearchType) {
        switch type {
        case .music:
            musicHistory.removeAll()
        case .poems:
            poemsHistory.removeAll()
        }
        saveHistory()
    }
    
    private func saveHistory() {
        if let musicData = try? JSONEncoder().encode(musicHistory) {
            UserDefaults.standard.set(musicData, forKey: musicKey)
        }
        if let poemsData = try? JSONEncoder().encode(poemsHistory) {
            UserDefaults.standard.set(poemsData, forKey: poemsKey)
        }
    }
    
    private func loadHistory() {
        if let musicData = UserDefaults.standard.data(forKey: musicKey),
           let music = try? JSONDecoder().decode([SearchHistoryItem].self, from: musicData) {
            musicHistory = music
        }
        if let poemsData = UserDefaults.standard.data(forKey: poemsKey),
           let poems = try? JSONDecoder().decode([SearchHistoryItem].self, from: poemsData) {
            poemsHistory = poems
        }
    }
}
