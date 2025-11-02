//
//  DailyPoemWidget.swift
//  RubatarWidget
//
//  Created for Rubatar Widget Extension
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct DailyPoemEntry: TimelineEntry {
    let date: Date
    let poem: PoemDisplayData?
    let error: String?
    
    static var placeholder: DailyPoemEntry {
        DailyPoemEntry(
            date: Date(),
            poem: PoemDisplayData(
                title: "Sample Poem",
                content: "This is a sample poem\nFor demonstration purposes",
                poetName: "Sample Poet",
                language: "English"
            ),
            error: nil
        )
    }
}

// MARK: - Poem Display Data (simplified for widget)
struct PoemDisplayData: Codable {
    let title: String
    let content: String  // Simplified text without verses structure
    let poetName: String
    let language: String
    let topic: String?
    let mood: String?
}

// MARK: - Timeline Provider
struct DailyPoemProvider: TimelineProvider {
    typealias Entry = DailyPoemEntry
    
    func placeholder(in context: Context) -> Entry {
        DailyPoemEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        // For quick preview
        completion(DailyPoemEntry.placeholder)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // Fetch poems from shared app data
        let currentDate = Date()
        
        Task {
            // Try to fetch from shared UserDefaults or disk
            if let poemData = loadDailyPoemFromSharedStorage() {
                let entry = DailyPoemEntry(date: currentDate, poem: poemData, error: nil)
                let nextUpdate = Calendar.current.date(byAdding: .hour, value: 12, to: currentDate)!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } else {
                // Try to fetch fresh data
                if let poem = await fetchDailyPoem() {
                    let entry = DailyPoemEntry(date: currentDate, poem: poem, error: nil)
                    // Next update in 12 hours
                    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 12, to: currentDate)!
                    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                    completion(timeline)
                } else {
                    // Show error
                    let entry = DailyPoemEntry(date: currentDate, poem: nil, error: "Unable to load poem")
                    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
                    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                    completion(timeline)
                }
            }
        }
    }
    
    // Load from shared UserDefaults
    private func loadDailyPoemFromSharedStorage() -> PoemDisplayData? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.meghdad.Rubatar") else {
            return nil
        }
        
        guard let data = sharedDefaults.data(forKey: "dailyPoem") else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(PoemDisplayData.self, from: data)
    }
    
    // Fetch from API (simplified, would need access to PoetryService or direct API call)
    private func fetchDailyPoem() async -> PoemDisplayData? {
        // This is a placeholder - in production, you'd need to either:
        // 1. Make direct API calls from the widget
        // 2. Have the main app fetch and save to shared storage
        // 3. Use a background task
        
        // For now, return nil to rely on shared storage
        return nil
    }
}

// MARK: - Main Widget
struct DailyPoemWidget: Widget {
    let kind: String = "DailyPoemWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyPoemProvider()) { entry in
            DailyPoemWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Poem")
        .description("Get inspired with a daily Persian poem.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Entry View
struct DailyPoemWidgetEntryView: View {
    var entry: DailyPoemEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (compact)
struct SmallWidgetView: View {
    var entry: DailyPoemEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let poem = entry.poem {
                // Poet name
                Text(poem.poetName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // First line of poem
                Text(firstLine(of: poem.content))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(4)
                
                Spacer()
                
                // Rubatar branding
                Label("Rubatar", systemImage: "music.note")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text(entry.error ?? "No poem available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private func firstLine(of text: String) -> String {
        text.components(separatedBy: .newlines).first ?? text
    }
}

// MARK: - Medium Widget (more content)
struct MediumWidgetView: View {
    var entry: DailyPoemEntry
    
    var body: some View {
        HStack(spacing: 12) {
            if let poem = entry.poem {
                VStack(alignment: .leading, spacing: 8) {
                    // Poet name
                    Text(poem.poetName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Poem title
                    Text(poem.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // Poem content (truncated)
                    Text(truncatedContent(of: poem.content))
                        .font(.subheadline)
                        .lineLimit(6)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Rubatar branding
                    Label("Daily Poem", systemImage: "music.note")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            } else {
                Text(entry.error ?? "No poem available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private func truncatedContent(of text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        return lines.prefix(6).joined(separator: "\n")
    }
}

// MARK: - Large Widget (full poem)
struct LargeWidgetView: View {
    var entry: DailyPoemEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let poem = entry.poem {
                // Poet name
                Text(poem.poetName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Poem title
                Text(poem.title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                // Full poem content
                Text(poem.content)
                    .font(.body)
                    .lineSpacing(4)
                
                // Metadata if available
                if let topic = poem.topic {
                    Text("Topic: \(topic)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Rubatar branding
                HStack {
                    Label("Rubatar Daily Poem", systemImage: "music.note")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(Date(), style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(entry.error ?? "No poem available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    DailyPoemWidget()
} timeline: {
    DailyPoemEntry.placeholder
}

