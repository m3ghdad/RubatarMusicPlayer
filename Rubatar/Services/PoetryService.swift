//
//  PoetryService.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import Foundation
import Combine

// MARK: - Line-by-Line Tafseer Model
struct LineByLineTafseer: Codable {
    let line: String
    let explanation: String
}

// MARK: - Supabase Poetry Models
struct SupabasePoem: Codable {
    let id: String
    let poet_id: String
    let poem_name_en: String
    let poem_name_fa: String
    let poem_number: Int?
    let poem_content_en: String
    let poem_content_fa: String
    let topic_id: Int?
    let form_fa: String?
    let form_en: String?
    let book_id: String?
    let language_original: String?
    let source_reference: String?
    let created_at: String
    let updated_at: String
    let tafseer_line_by_line_fa: [LineByLineTafseer]?
    let tafseer_line_by_line_en: [LineByLineTafseer]?
    let tafseer_fa: String?
    let tafseer_en: String?
}

struct SupabasePoet: Codable {
    let id: String
    let name_en: String
    let name_fa: String
    let nickname_en: String?
    let nickname_fa: String?
    let biography_en: String?
    let biography_fa: String?
    let birthdate: String?
    let passingdate: String?
    let birthplace_en: String?
    let birthplace_fa: String?
    let era_fa: String?
    let era_en: String?
    let image_url: String?
    let geographic_origin_en: String?
    let geographic_origin_fa: String?
    let languages_en: String?
    let languages_fa: String?
    let birth_place_en: String?
    let birth_place_fa: String?
    let death_place_en: String?
    let death_place_fa: String?
    let created_at: String
    let updated_at: String
}

struct SupabaseTopic: Codable {
    let id: Int
    let topic_en: String
    let topic_fa: String
    let description: String?
    let created_at: String
    let updated_at: String
}

struct SupabaseMood: Codable {
    let id: Int
    let mood_en: String
    let mood_fa: String
    let color_hex: String?
    let created_at: String
    let updated_at: String
}

struct SupabasePoemMood: Codable {
    let id: Int
    let poem_id: String
    let mood_id: Int
    let created_at: String
}

struct SupabaseBook: Codable {
    let id: String
    let poet_id: String?
    let name_fa: String
    let name_en: String
    let description_fa: String?
    let description_en: String?
    let created_at: String
    let updated_at: String
}

// MARK: - Poetry Service
class PoetryService: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var englishPoems: [Int: PoemData] = [:] // Cache: poem.id -> English poem
    @Published var farsiPoems: [Int: PoemData] = [:] // Cache: poem.id -> Farsi poem with tafseer
    
    private let baseURL = "https://pspybykovwrfdxpkjpzd.supabase.co"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzcHlieWtvdndyZmR4cGtqcHpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NDIyMDksImV4cCI6MjA3NTExODIwOX0.NV3irlmKEDcThTGYnHOLy4LRA5qjAxUC4XhkKf4QpKA"
    
    init() {
        // Initialize with your Supabase credentials
    }
    
    // Fetch poems with poet, topic, and mood information
    func fetchPoems(limit: Int = 100, offset: Int = 0, useCache: Bool = true) async -> [PoemData] {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        // Try to load from cache first if enabled
        if useCache && offset == 0 {
            let cachedPoems = CoreDataManager.shared.fetchCachedPoems(limit: limit)
            if !cachedPoems.isEmpty {
                print("📚 PoetryService: Loaded \(cachedPoems.count) poems from cache")
                await MainActor.run {
                    isLoading = false
                }
                
                // Fetch fresh data in background
                Task {
                    _ = await fetchPoems(limit: limit, offset: offset, useCache: false)
                }
                
                return cachedPoems
            }
        }
        
        do {
            // Fetch poems from Supabase
            print("📚 PoetryService: Starting to fetch poems from Supabase...")
            let poems = try await fetchPoemsFromSupabase(limit: limit, offset: offset)
            print("📚 PoetryService: Successfully fetched \(poems.count) poems")
            
            // Cache the poems if this is the first page
            if offset == 0 && !poems.isEmpty {
                CoreDataManager.shared.cachePoems(poems)
                print("📚 PoetryService: Cached \(poems.count) poems")
            }
            
            await MainActor.run {
                isLoading = false
            }
            
            return poems
            
        } catch {
            print("❌ PoetryService Error: \(error.localizedDescription)")
            print("❌ Full error: \(error)")
            await MainActor.run {
                isLoading = false
                self.error = error.localizedDescription
            }
            
            // If network fails, try to return cached data
            if useCache {
                let cachedPoems = CoreDataManager.shared.fetchCachedPoems(limit: limit)
                if !cachedPoems.isEmpty {
                    print("📚 PoetryService: Network failed, returning \(cachedPoems.count) cached poems")
                    return cachedPoems
                }
            }
            
            return []
        }
    }
    
    // Fetch poems from Supabase API
    private func fetchPoemsFromSupabase(limit: Int, offset: Int) async throws -> [PoemData] {
        print("📚 Fetching poems from: \(baseURL)/rest/v1/poems")
        
        // Fetch poems
        let poemsURL = "\(baseURL)/rest/v1/poems?select=*&limit=\(limit)&offset=\(offset)"
        let poemsResponse = try await makeRequest(url: poemsURL)
        let poemsData: [SupabasePoem] = try JSONDecoder().decode([SupabasePoem].self, from: poemsResponse)
        print("📚 Found \(poemsData.count) poems")
        
        // If no poems found, return empty array
        guard !poemsData.isEmpty else {
            print("⚠️ No poems found in database")
            return []
        }
        
        // Get unique poet IDs
        let poetIds = Set(poemsData.map { $0.poet_id })
        let poetIdsString = poetIds.map { "\"\($0)\"" }.joined(separator: ",")
        print("📚 Fetching poets: \(poetIds.count) unique poets")
        
        // Fetch poets
        let poetsURL = "\(baseURL)/rest/v1/poets?select=*&id=in.(\(poetIdsString))"
        let poetsResponse = try await makeRequest(url: poetsURL)
        let poetsData: [SupabasePoet] = try JSONDecoder().decode([SupabasePoet].self, from: poetsResponse)
        print("📚 Found \(poetsData.count) poets")
        
        // Get unique topic IDs
        let topicIds = Set(poemsData.compactMap { $0.topic_id })
        if !topicIds.isEmpty {
            let topicIdsString = topicIds.map { "\($0)" }.joined(separator: ",")
            print("📚 Fetching topics: \(topicIds.count) unique topics")
            
            // Fetch topics
            let topicsURL = "\(baseURL)/rest/v1/topics?select=*&id=in.(\(topicIdsString))"
            let topicsResponse = try await makeRequest(url: topicsURL)
            let topicsData: [SupabaseTopic] = try JSONDecoder().decode([SupabaseTopic].self, from: topicsResponse)
            print("📚 Found \(topicsData.count) topics")
        }
        
        let topicIds2 = Set(poemsData.compactMap { $0.topic_id })
        let topicIdsString = topicIds2.map { "\($0)" }.joined(separator: ",")
        let topicsURL = "\(baseURL)/rest/v1/topics?select=*&id=in.(\(topicIdsString))"
        let topicsResponse = try await makeRequest(url: topicsURL)
        let topicsData: [SupabaseTopic] = try JSONDecoder().decode([SupabaseTopic].self, from: topicsResponse)
        
        // Get poem IDs for mood lookup
        let poemIds = poemsData.map { $0.id }
        let poemIdsString = poemIds.map { "\"\($0)\"" }.joined(separator: ",")
        print("📚 Fetching moods for \(poemIds.count) poems")
        
        // Fetch poem-mood relationships
        let poemMoodsURL = "\(baseURL)/rest/v1/poem_moods?select=*&poem_id=in.(\(poemIdsString))"
        let poemMoodsResponse = try await makeRequest(url: poemMoodsURL)
        let poemMoodsData: [SupabasePoemMood] = try JSONDecoder().decode([SupabasePoemMood].self, from: poemMoodsResponse)
        print("📚 Found \(poemMoodsData.count) poem-mood relationships")
        
        // Get unique mood IDs
        let moodIds = Set(poemMoodsData.map { $0.mood_id })
        let moodIdsString = moodIds.map { "\($0)" }.joined(separator: ",")
        
        // Fetch moods
        let moodsURL = "\(baseURL)/rest/v1/moods?select=*&id=in.(\(moodIdsString))"
        let moodsResponse = try await makeRequest(url: moodsURL)
        let moodsData: [SupabaseMood] = try JSONDecoder().decode([SupabaseMood].self, from: moodsResponse)
        print("📚 Found \(moodsData.count) moods")
        
        // Get unique book IDs
        let bookIds = Set(poemsData.compactMap { $0.book_id })
        var booksData: [SupabaseBook] = []
        if !bookIds.isEmpty {
            let bookIdsString = bookIds.map { "\"\($0)\"" }.joined(separator: ",")
            print("📚 Fetching books: \(bookIds.count) unique books")
            
            // Fetch books
            let booksURL = "\(baseURL)/rest/v1/books?select=*&id=in.(\(bookIdsString))"
            let booksResponse = try await makeRequest(url: booksURL)
            booksData = try JSONDecoder().decode([SupabaseBook].self, from: booksResponse)
            print("📚 Found \(booksData.count) books")
        }
        
        // Convert to app models
        var convertedPoems: [PoemData] = []
        
        for poem in poemsData {
            guard let poet = poetsData.first(where: { $0.id == poem.poet_id }) else {
                print("⚠️ Poet not found for poem: \(poem.poem_name_fa)")
                continue
            }
            let topic = topicsData.first { $0.id == poem.topic_id }
            let poemMood = poemMoodsData.first { $0.poem_id == poem.id }
            let mood = poemMood != nil ? moodsData.first { $0.id == poemMood!.mood_id } : nil
            let book = poem.book_id != nil ? booksData.first { $0.id == poem.book_id } : nil
            
            print("✅ Converting poem: \(poem.poem_name_fa) by \(poet.name_fa)")
            if let eraFa = poet.era_fa, !eraFa.isEmpty {
                print("  📅 Poet era (Fa): \(eraFa)")
            }
            if let eraEn = poet.era_en, !eraEn.isEmpty {
                print("  📅 Poet era (En): \(eraEn)")
            }
            if let bioFa = poet.biography_fa, !bioFa.isEmpty {
                print("  📖 Poet biography (Fa) available: \(bioFa.prefix(50))...")
            }
            if let bioEn = poet.biography_en, !bioEn.isEmpty {
                print("  📖 Poet biography (En) available: \(bioEn.prefix(50))...")
            }
            
            let poemId = Int(poem.id.suffix(8), radix: 16) ?? 0
            
            // Create Farsi poem
            let farsiPoem = PoemData(
                id: poemId,
                title: poem.poem_name_fa,
                poet: PoetInfo(
                    id: Int(poet.id.suffix(8), radix: 16) ?? 0,
                    name: poet.nickname_fa ?? poet.name_fa,
                    fullName: poet.name_fa,
                    era: poet.era_fa,
                    biographyEn: poet.biography_en,
                    biographyFa: poet.biography_fa
                ),
                verses: parsePoemContent(poem.poem_content_fa),
                topic: topic?.topic_fa,
                mood: mood?.mood_fa,
                moodColor: mood?.color_hex,
                tafseerLineByLineFa: poem.tafseer_line_by_line_fa,
                tafseerLineByLineEn: poem.tafseer_line_by_line_en,
                tafseerFa: poem.tafseer_fa,
                tafseerEn: poem.tafseer_en,
                formFa: poem.form_fa,
                formEn: poem.form_en,
                bookNameFa: book?.name_fa,
                bookNameEn: book?.name_en
            )
            
            // Store Farsi poem in cache with tafseer data
            await MainActor.run {
                self.farsiPoems[poemId] = farsiPoem
            }
            print("✅ Cached Farsi poem with tafseer for poem \(poemId)")
            
            // Create English poem and store in cache
            if !poem.poem_content_en.isEmpty {
                let englishPoem = PoemData(
                    id: poemId,
                    title: poem.poem_name_en,
                    poet: PoetInfo(
                        id: Int(poet.id.suffix(8), radix: 16) ?? 0,
                        name: poet.nickname_en ?? poet.name_en,
                        fullName: poet.name_en,
                        era: poet.era_en,
                        biographyEn: poet.biography_en,
                        biographyFa: poet.biography_fa
                    ),
                    verses: parsePoemContent(poem.poem_content_en),
                    topic: topic?.topic_en,
                    mood: mood?.mood_en,
                    moodColor: mood?.color_hex,
                    tafseerLineByLineFa: poem.tafseer_line_by_line_fa,
                    tafseerLineByLineEn: poem.tafseer_line_by_line_en,
                    tafseerFa: poem.tafseer_fa,
                    tafseerEn: poem.tafseer_en,
                    formFa: poem.form_fa,
                    formEn: poem.form_en,
                    bookNameFa: book?.name_fa,
                    bookNameEn: book?.name_en
                )
                
                // Store English version in cache
                await MainActor.run {
                    self.englishPoems[poemId] = englishPoem
                }
                print("✅ Cached English translation for poem \(poemId)")
            }
            
            convertedPoems.append(farsiPoem)
        }
        
        print("📚 Successfully converted \(convertedPoems.count) poems")
        return convertedPoems
    }
    
    // Make HTTP request to Supabase
    private func makeRequest(url: String) async throws -> Data {
        guard let requestURL = URL(string: url) else {
            print("❌ Invalid URL: \(url)")
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        print("🌐 Making request to: \(url)")
        
        var request = URLRequest(url: requestURL)
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response data preview: \(responseString.prefix(200))...")
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
        }
        
        return data
    }
    
    
    // Parse poem content into verses (couplets)
    private func parsePoemContent(_ content: String) -> [[String]] {
        // Replace literal \n with actual newlines
        let cleanedContent = content.replacingOccurrences(of: "\\n", with: "\n")
        
        let lines = cleanedContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        print("📝 Parsing poem content: \(lines.count) lines found")
        
        var verses: [[String]] = []
        var currentVerse: [String] = []
        
        for line in lines {
            currentVerse.append(line)
            
            // For rubai (quatrains), each verse has 2 lines
            if currentVerse.count == 2 {
                verses.append(currentVerse)
                currentVerse = []
            }
        }
        
        // Add any remaining lines as a final verse
        if !currentVerse.isEmpty {
            verses.append(currentVerse)
        }
        
        print("📝 Created \(verses.count) verses")
        return verses
    }
}

