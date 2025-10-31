//
//  GanjoorAPI.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/17/25.
//
//  NOTE: Ganjoor API is no longer used - all data now comes from Supabase
//  The GanjoorAPIManager and related API response models are commented out below.
//

import Foundation
import Combine

// MARK: - API Response Models
// NOTE: Ganjoor API is no longer used - all data now comes from Supabase
/*
struct GanjoorPoemResponse: Codable {
    let id: Int
    let title: String?
    let fullTitle: String?
    let plainText: String?
    let text: String?
    let htmlText: String?
    let poet: GanjoorPoet?
}

struct GanjoorPoet: Codable {
    let id: Int
    let name: String?
    let fullName: String?
}
*/

// MARK: - Internal App Models
struct PoemData: Identifiable, Codable {
    let id: Int
    let title: String
    let poet: PoetInfo
    let verses: [[String]] // Array of couplets (each couplet is 2 lines)
    let topic: String?
    let mood: String?
    let moodColor: String?
    
    // Line-by-line tafseer
    let tafseerLineByLineFa: [LineByLineTafseer]?
    let tafseerLineByLineEn: [LineByLineTafseer]?
    
    // Full tafseer text
    let tafseerFa: String?
    let tafseerEn: String?
    
    // Additional fields for music integration (optional)
    var poem_text_en: String?
    var poem_name_en: String?
    var poet_name_en: String?
    var topic_name_en: String?
    var playlist_id: String?
    var playlist_name: String?
    var curator_name: String?
    var artwork_url: String?
    
    // Computed properties for consistency
    var poem_text: String { verses.flatMap { $0 }.joined(separator: "\n") }
    var poem_name_fa: String { title }
    var poet_name_fa: String { poet.fullName }
    var topic_name_fa: String? { topic }
    
    enum CodingKeys: String, CodingKey {
        case id, title, poet, verses, topic, mood, moodColor
        case tafseerLineByLineFa = "tafseer_line_by_line_fa"
        case tafseerLineByLineEn = "tafseer_line_by_line_en"
        case tafseerFa = "tafseer_fa"
        case tafseerEn = "tafseer_en"
        case poem_text_en, poem_name_en, poet_name_en, topic_name_en
        case playlist_id, playlist_name, curator_name, artwork_url
    }
}

struct PoetInfo: Codable {
    let id: Int
    let name: String
    let fullName: String
}

// MARK: - Ganjoor API Manager
// NOTE: Ganjoor API is no longer used - all data now comes from Supabase
/*
class GanjoorAPIManager: ObservableObject {
    @Published var isLoading = false
    @Published var currentPoem: PoemData?
    @Published var error: String?
    
    private var usedPoemIds = Set<Int>()
    private let baseURL = "https://api.ganjoor.net/api/ganjoor"
    
    // Fetch a single random poem
    func fetchRandomPoem() async -> PoemData? {
        // Check if we should try API
        guard let url = URL(string: "\(baseURL)/poem/random") else {
            print("❌ Invalid URL")
            return nil
        }
        
        do {
            // Create request with timeout
            var request = URLRequest(url: url)
            request.timeoutInterval = 5.0
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Rubatar Music App", forHTTPHeaderField: "User-Agent")
            request.cachePolicy = .reloadIgnoringLocalCacheData
            
            // Fetch data
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ API returned non-200 status")
                return nil
            }
            
            // Parse JSON
            let decoder = JSONDecoder()
            let poemResponse = try decoder.decode(GanjoorPoemResponse.self, from: data)
            
            // Skip if already used
            if usedPoemIds.contains(poemResponse.id) {
                return await fetchRandomPoem() // Recursive call to get a new one
            }
            
            // Extract poet name - try multiple sources
            var poetName = "نامعلوم"
            if let name = poemResponse.poet?.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
                poetName = name
            } else if let fullTitle = poemResponse.fullTitle, fullTitle.contains(" » ") {
                // Try extracting from fullTitle
                poetName = fullTitle.components(separatedBy: " » ").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "نامعلوم"
            }
            
            let poetFullName = poemResponse.poet?.fullName ?? poetName
            
            // Get poem text
            let poemText = (poemResponse.plainText ?? poemResponse.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parse verses into couplets
            let verses = parseVersesIntoCouplets(poemText)
            
            // Create poem object
            let poem = PoemData(
                id: poemResponse.id,
                title: (poemResponse.title ?? "بدون عنوان").trimmingCharacters(in: .whitespacesAndNewlines),
                poet: PoetInfo(
                    id: poemResponse.poet?.id ?? Int(Date().timeIntervalSince1970),
                    name: poetName,
                    fullName: poetFullName
                ),
                verses: verses,
                topic: nil,
                mood: nil,
                moodColor: nil,
                tafseerLineByLineFa: nil,
                tafseerLineByLineEn: nil,
                tafseerFa: nil,
                tafseerEn: nil
            )
            
            // Add to used poems
            usedPoemIds.insert(poemResponse.id)
            
            return poem
            
        } catch {
            print("❌ Error fetching poem: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Parse poem text into couplets (pairs of lines)
    private func parseVersesIntoCouplets(_ text: String) -> [[String]] {
        // Split by line breaks
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Group into pairs (couplets)
        var couplets: [[String]] = []
        for i in stride(from: 0, to: lines.count, by: 2) {
            if i + 1 < lines.count {
                // We have a complete couplet
                couplets.append([lines[i], lines[i + 1]])
            } else {
                // Last line is alone
                couplets.append([lines[i]])
            }
        }
        
        return couplets
    }
    
    // Fetch multiple poems
    func fetchMultiplePoems(count: Int = 4) async -> [PoemData] {
        var poems: [PoemData] = []
        let maxAttempts = count * 2
        var attempts = 0
        
        while poems.count < count && attempts < maxAttempts {
            attempts += 1
            
            if let poem = await fetchRandomPoem() {
                poems.append(poem)
            }
            
            // Small delay between requests to avoid overwhelming the API
            if poems.count < count && attempts < maxAttempts {
                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            }
        }
        
        return poems
    }
    
    // Load initial poems for the view
    @MainActor
    func loadInitialPoems() async {
        isLoading = true
        error = nil
        
        let poems = await fetchMultiplePoems(count: 4)
        
        if poems.isEmpty {
            error = "Unable to load poems. Please check your internet connection."
        } else if let firstPoem = poems.first {
            currentPoem = firstPoem
        }
        
        isLoading = false
    }
    
    // Refresh with a new poem
    @MainActor
    func refreshPoem() async {
        isLoading = true
        error = nil
        
        if let newPoem = await fetchRandomPoem() {
            currentPoem = newPoem
        } else {
            error = "Unable to load a new poem. Please try again."
        }
        
        isLoading = false
    }
    
    // Clear used poems history
    func clearHistory() {
        usedPoemIds.removeAll()
    }
}
*/

