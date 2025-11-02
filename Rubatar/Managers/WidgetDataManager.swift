//
//  WidgetDataManager.swift
//  Rubatar
//
//  Handles saving data to shared storage for widget display
//

import Foundation
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // App Group identifier (must match in both app and widget entitlements)
    private let appGroupIdentifier = "group.com.meghdad.Rubatar"
    
    private init() {}
    
    // Save daily poem to shared storage
    func saveDailyPoem(_ poem: PoemDisplayData) {
        print("📝 App: Attempting to save poem '\(poem.title)' to widget...")
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ App: Failed to access shared UserDefaults with suiteName: \(appGroupIdentifier)")
            return
        }
        
        print("✅ App: Successfully accessed shared UserDefaults")
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(poem) {
            sharedDefaults.set(encoded, forKey: "dailyPoem")
            sharedDefaults.set(Date(), forKey: "lastUpdated")
            print("✅ App: Saved daily poem '\(poem.title)' to shared storage (\(encoded.count) bytes)")
            
            // Verify it was saved
            if let savedData = sharedDefaults.data(forKey: "dailyPoem") {
                print("✅ App: Verified poem data saved (read back \(savedData.count) bytes)")
            } else {
                print("❌ App: Poem data not found after saving!")
            }
            
            // Notify widget to reload
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ App: Notified widget to reload timelines")
        } else {
            print("❌ App: Failed to encode poem data")
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

// MARK: - Poem Display Data (shared between app and widget)
struct PoemDisplayData: Codable {
    let title: String
    let content: String  // Simplified text without verses structure
    let poetName: String
    let language: String
    let topic: String?
    let mood: String?
    
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
