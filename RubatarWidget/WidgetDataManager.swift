//
//  WidgetDataManager.swift
//  RubatarWidget
//
//  Handles data sharing between main app and widget
//

import Foundation

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // App Group identifier (must match in both app and widget entitlements)
    private let appGroupIdentifier = "group.com.meghdad.Rubatar"
    
    private init() {}
    
    // Save daily poem to shared storage
    func saveDailyPoem(_ poem: PoemDisplayData) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ Failed to access shared UserDefaults")
            return
        }
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(poem) {
            sharedDefaults.set(encoded, forKey: "dailyPoem")
            sharedDefaults.set(Date(), forKey: "lastUpdated")
            print("✅ Saved daily poem to shared storage")
        } else {
            print("❌ Failed to encode poem data")
        }
    }
    
    // Load daily poem from shared storage
    func loadDailyPoem() -> PoemDisplayData? {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return nil
        }
        
        guard let data = sharedDefaults.data(forKey: "dailyPoem") else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(PoemDisplayData.self, from: data)
    }
    
    // Check if data needs refresh (e.g., after 24 hours)
    func shouldRefreshData() -> Bool {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let lastUpdated = sharedDefaults.object(forKey: "lastUpdated") as? Date else {
            return true
        }
        
        let hoursSinceUpdate = Calendar.current.dateComponents([.hour], from: lastUpdated, to: Date()).hour ?? 0
        return hoursSinceUpdate >= 24
    }
}

// MARK: - Extension to convert PoemData to PoemDisplayData
extension PoemDisplayData {
    static func from(_ poemData: PoemData, language: String = "English") -> PoemDisplayData {
        // Convert verses array to simple text
        let content = poemData.verses.flatMap { $0 }.joined(separator: "\n")
        
        return PoemDisplayData(
            title: language == "Farsi" ? poemData.title : (poemData.poem_name_en ?? poemData.title),
            content: content,
            poetName: poemData.poet.fullName,
            language: language,
            topic: poemData.topic,
            mood: poemData.mood
        )
    }
}

// MARK: - Note: This needs to be defined in both app and widget
// Moving PoemDisplayData here so it's available in widget bundle

