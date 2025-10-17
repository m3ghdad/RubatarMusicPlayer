//
//  TranslationManager.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/17/25.
//

import Foundation

class TranslationManager {
    private let openAIAPIKey: String
    
    init(apiKey: String) {
        self.openAIAPIKey = apiKey
    }
    
    // Translate a poem to English using OpenAI
    func translatePoem(_ poem: PoemData) async -> PoemData? {
        // Prepare the poem text for translation
        let poemText = poem.verses.map { couplet in
            couplet.joined(separator: "\n")
        }.joined(separator: "\n\n")
        
        let prompt = """
        You are an expert translator of Persian poetry to English. Translate the following Persian poem.
        
        Title: \(poem.title)
        Poet: \(poem.poet.name)
        
        Persian Poem:
        \(poemText)
        
        INSTRUCTIONS:
        1. First line: Translate the title to English
        2. Following lines: Translate the poem verses, maintaining the structure
        3. Maintain poetic beauty, metaphors, and rhythm
        4. Make it feel like authentic English poetry
        5. Keep the same number of verse lines as the original
        
        Format your response as:
        [Translated Title]
        [First line of verse 1]
        [Second line of verse 1]
        
        [First line of verse 2]
        [Second line of verse 2]
        ... and so on
        """
        
        do {
            // Create the API request
            guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                print("❌ Invalid OpenAI API URL")
                return nil
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30.0
            
            let requestBody: [String: Any] = [
                "model": Config.translationModel,
                "messages": [
                    [
                        "role": "system",
                        "content": "You are an expert translator of Persian poetry, specializing in maintaining poetic beauty and metaphorical depth in English translations."
                    ],
                    [
                        "role": "user",
                        "content": prompt
                    ]
                ],
                "temperature": Config.translationTemperature,
                "max_tokens": Config.translationMaxTokens
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Make the API call
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                return nil
            }
            
            if httpResponse.statusCode != 200 {
                print("❌ OpenAI API returned status \(httpResponse.statusCode)")
                
                // Try to get error message from response
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("   Error: \(message)")
                }
                
                return nil
            }
            
            // Parse the response
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = jsonResponse["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let translatedText = message["content"] as? String else {
                print("❌ Failed to parse OpenAI response")
                return nil
            }
            
            // Parse the translated text to extract title and verses
            let trimmedText = translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
            let (translatedTitle, translatedVerses) = parseTranslatedTextWithTitle(trimmedText, originalTitle: poem.title)
            
            // Translate poet name
            let translatedPoetName = translatePoetName(poem.poet.name)
            
            // Create translated poem
            let translatedPoem = PoemData(
                id: poem.id + 100000, // Offset ID for translated version
                title: translatedTitle,
                poet: PoetInfo(
                    id: poem.poet.id,
                    name: translatedPoetName,
                    fullName: translatedPoetName
                ),
                verses: translatedVerses
            )
            
            print("✓ Translated poem: '\(poem.title)' → '\(translatedTitle)' by \(translatedPoetName)")
            return translatedPoem
            
        } catch {
            print("❌ Translation error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Parse translated text with title extraction
    private func parseTranslatedTextWithTitle(_ text: String, originalTitle: String) -> (String, [[String]]) {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            return (originalTitle, [])
        }
        
        // First line is the translated title
        let translatedTitle = lines[0]
        
        // Remaining lines are the poem verses
        let verseLines = Array(lines.dropFirst())
        
        // Group into pairs (couplets/beyts)
        var verses: [[String]] = []
        for i in stride(from: 0, to: verseLines.count, by: 2) {
            if i + 1 < verseLines.count {
                verses.append([verseLines[i], verseLines[i + 1]])
            } else {
                verses.append([verseLines[i]])
            }
        }
        
        return (translatedTitle, verses)
    }
    
    // Parse translated text back into verse structure (legacy method)
    private func parseTranslatedText(_ text: String) -> [[String]] {
        // Split by double newlines to get couplets
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Group into pairs (couplets/beyts)
        var verses: [[String]] = []
        for i in stride(from: 0, to: lines.count, by: 2) {
            if i + 1 < lines.count {
                verses.append([lines[i], lines[i + 1]])
            } else {
                verses.append([lines[i]])
            }
        }
        
        return verses
    }
    
    // Translate common Persian poet names to English
    private func translatePoetName(_ persianName: String) -> String {
        let commonTranslations: [String: String] = [
            "حافظ": "Hafez",
            "خیام": "Khayyam",
            "عمر خیام": "Omar Khayyam",
            "سعدی": "Saadi",
            "مولانا": "Rumi",
            "جلال‌الدین محمد بلخی": "Rumi",
            "فردوسی": "Ferdowsi",
            "نظامی": "Nizami",
            "رودکی": "Rudaki",
            "اوحدی": "Ouhadi",
            "امیرخسرو دهلوی": "Amir Khusrau",
            "محتشم کاشانی": "Mohtasham Kashani",
            "سلمان ساوجی": "Salman Savoji",
            "ابوسعید ابوالخیر": "Abu-Said Abulkheir"
        ]
        
        return commonTranslations[persianName] ?? persianName
    }
}

