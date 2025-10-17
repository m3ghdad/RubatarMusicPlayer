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
        
        IMPORTANT INSTRUCTIONS:
        1. First line: Translate the title to English (remove any brackets [] or asterisks **)
        2. Following lines: Translate the poem verses, maintaining the structure
        3. Maintain poetic beauty, metaphors, and rhythm
        4. Make it feel like authentic English poetry
        5. Keep the same number of verse lines as the original
        6. Do NOT include any brackets, asterisks, or formatting marks in your response
        
        Format your response as plain text:
        Translated Title
        First line of verse 1
        Second line of verse 1
        
        First line of verse 2
        Second line of verse 2
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
            
            // Clean up the translated title (remove brackets and asterisks)
            let cleanedTitle = cleanTitle(translatedTitle)
            
            // Translate poet name (check dictionary first, then use AI if needed)
            var translatedPoetName = translatePoetName(poem.poet.name)
            
            // If still in Persian, use AI to translate
            let isPersian = translatedPoetName.range(of: "[\\u0600-\\u06FF]", options: .regularExpression) != nil
            if isPersian {
                translatedPoetName = await translatePoetNameWithAI(translatedPoetName)
            }
            
            // Create translated poem
            let translatedPoem = PoemData(
                id: poem.id + 100000, // Offset ID for translated version
                title: cleanedTitle,
                poet: PoetInfo(
                    id: poem.poet.id,
                    name: translatedPoetName,
                    fullName: translatedPoetName
                ),
                verses: translatedVerses
            )
            
            print("✓ Translated poem: '\(poem.title)' → '\(cleanedTitle)' by \(translatedPoetName)")
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
    
    // Clean title by removing brackets and asterisks
    private func cleanTitle(_ title: String) -> String {
        var cleaned = title
        
        // Remove square brackets and their contents at start/end
        cleaned = cleaned.replacingOccurrences(of: "^\\[.*?\\]\\s*", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\s*\\[.*?\\]$", with: "", options: .regularExpression)
        
        // Remove asterisks
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        cleaned = cleaned.replacingOccurrences(of: "*", with: "")
        
        // Remove any remaining brackets
        cleaned = cleaned.replacingOccurrences(of: "[", with: "")
        cleaned = cleaned.replacingOccurrences(of: "]", with: "")
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Translate common Persian poet names to English
    private func translatePoetName(_ persianName: String) -> String {
        // Check for exact match first
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
            "ابوسعید ابوالخیر": "Abu-Said Abulkheir",
            "بابا طاهر": "Baba Taher",
            "عطار نیشابوری": "Attar",
            "سنایی": "Sanai",
            "انوری": "Anvari",
            "منوچهری": "Manuchehri",
            "ناصرخسرو": "Nasir Khusraw",
            "پروین اعتصامی": "Parvin Etesami",
            "فروغ فرخزاد": "Forough Farrokhzad",
            "شهریار": "Shahriar",
            "اقبال لاهوری": "Allama Iqbal"
        ]
        
        // Return translation if found
        if let translation = commonTranslations[persianName] {
            return translation
        }
        
        // If the name contains Persian characters, it needs translation
        let isPersian = persianName.range(of: "[\\u0600-\\u06FF]", options: .regularExpression) != nil
        
        if isPersian {
            // If it's Persian but not in our dictionary, try extracting from the prompt
            // The AI was given the poet name, so we should have gotten it from the full title
            return persianName // This will be translated via API in the next step
        } else {
            // Already in English or unknown
            return persianName
        }
    }
    
    // Translate poet name using OpenAI API for unknown Persian names
    func translatePoetNameWithAI(_ persianName: String) async -> String {
        // Check if already translated
        let isPersian = persianName.range(of: "[\\u0600-\\u06FF]", options: .regularExpression) != nil
        
        if !isPersian {
            return persianName
        }
        
        let prompt = """
        Translate this Persian poet's name to English. Respond with ONLY the English name, nothing else.
        
        Persian name: \(persianName)
        
        Examples:
        - حافظ → Hafez
        - خیام → Khayyam
        - سعدی → Saadi
        
        Just provide the English name:
        """
        
        do {
            guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                print("❌ Invalid OpenAI API URL")
                return persianName
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10.0
            
            let requestBody: [String: Any] = [
                "model": "gpt-4o-mini",
                "messages": [
                    [
                        "role": "system",
                        "content": "You are a translator of Persian names to English. Respond with only the translated name, nothing else."
                    ],
                    [
                        "role": "user",
                        "content": prompt
                    ]
                ],
                "temperature": 0.3,
                "max_tokens": 50
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = jsonResponse["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let translatedName = message["content"] as? String else {
                print("❌ Failed to translate poet name via AI")
                return persianName
            }
            
            let cleanedName = translatedName.trimmingCharacters(in: .whitespacesAndNewlines)
            print("✓ Translated poet name: '\(persianName)' → '\(cleanedName)'")
            return cleanedName
            
        } catch {
            print("❌ Error translating poet name: \(error.localizedDescription)")
            return persianName
        }
    }
}

