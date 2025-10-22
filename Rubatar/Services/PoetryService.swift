//
//  PoetryService.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import Foundation
import Combine

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
    let form: String?
    let language_original: String?
    let source_reference: String?
    let created_at: String
    let updated_at: String
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
    let era: String?
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

// MARK: - Poetry Service
class PoetryService: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    private let baseURL = "https://pspybykovwrfdxpkjpzd.supabase.co"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzcHlieWtvdndyZmR4cGtqcHpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NDIyMDksImV4cCI6MjA3NTExODIwOX0.NV3irlmKEDcThTGYnHOLy4LRA5qjAxUC4XhkKf4QpKA"
    
    init() {
        // Initialize with your Supabase credentials
    }
    
    // Fetch poems with poet, topic, and mood information
    func fetchPoems(limit: Int = 10) async -> [PoemData] {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Fetch poems from Supabase
            print("📚 PoetryService: Starting to fetch poems from Supabase...")
            let poems = try await fetchPoemsFromSupabase(limit: limit)
            print("📚 PoetryService: Successfully fetched \(poems.count) poems")
            
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
            // Return empty array on error
            return []
        }
    }
    
    // Fetch poems from Supabase API
    private func fetchPoemsFromSupabase(limit: Int) async throws -> [PoemData] {
        print("📚 Fetching poems from: \(baseURL)/rest/v1/poems")
        
        // Fetch poems
        let poemsURL = "\(baseURL)/rest/v1/poems?select=*&limit=\(limit)"
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
        
        // Convert to app models
        let convertedPoems = poemsData.compactMap { poem -> PoemData? in
            guard let poet = poetsData.first(where: { $0.id == poem.poet_id }) else {
                print("⚠️ Poet not found for poem: \(poem.poem_name_fa)")
                return nil
            }
            let topic = topicsData.first { $0.id == poem.topic_id }
            let poemMood = poemMoodsData.first { $0.poem_id == poem.id }
            let mood = poemMood != nil ? moodsData.first { $0.id == poemMood!.mood_id } : nil
            
            print("✅ Converting poem: \(poem.poem_name_fa) by \(poet.name_fa)")
            
            return PoemData(
                id: Int(poem.id.suffix(8), radix: 16) ?? 0, // Convert UUID to Int
                title: poem.poem_name_fa,
                poet: PoetInfo(
                    id: Int(poet.id.suffix(8), radix: 16) ?? 0,
                    name: poet.nickname_fa ?? poet.name_fa,
                    fullName: poet.name_fa
                ),
                verses: parsePoemContent(poem.poem_content_fa),
                topic: topic?.topic_fa,
                mood: mood?.mood_fa,
                moodColor: mood?.color_hex
            )
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

