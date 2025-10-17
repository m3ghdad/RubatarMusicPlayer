# Translation Guide for Rubatar Poetry Display

## Current Implementation (Persian/Farsi)

The app currently displays Persian poetry from the Ganjoor API with:
- Persian text with RTL (Right-to-Left) layout
- Farsi numerals (۱، ۲، ۳...)
- Persian loading text ("در حال بارگذاری...")

## Adding English Translation Support

### 1. Add Language State
In `ProfileView.swift`, add a state variable to track the current language:

```swift
@State private var currentLanguage: String = "fa" // "fa" for Farsi, "en" for English
```

### 2. Create Translation Model
Create a new file `Rubatar/Models/TranslationManager.swift`:

```swift
class TranslationManager {
    // Translate poem using an API or local service
    func translatePoem(_ poem: PoemData, to language: String) async -> PoemData? {
        // Your translation logic here
        // Options:
        // 1. Google Translate API
        // 2. OpenAI API (as in your React app)
        // 3. Pre-translated database
        return translatedPoem
    }
}
```

### 3. Update UI Based on Language
In `ProfileView.swift`, modify the poem display:

```swift
// Number formatting
private func formatNumber(_ number: Int) -> String {
    if currentLanguage == "fa" {
        return toFarsiNumber(number)
    } else {
        return String(number)
    }
}

// Text alignment
private var textAlignment: TextAlignment {
    currentLanguage == "fa" ? .trailing : .leading
}

// Layout direction
private var layoutDirection: LayoutDirection {
    currentLanguage == "fa" ? .rightToLeft : .leftToRight
}
```

### 4. Update Text Display
Replace hardcoded RTL settings with dynamic ones:

```swift
Text(couplet[0])
    .font(.system(size: 14))
    .foregroundColor(.black)
    .multilineTextAlignment(textAlignment)
    .environment(\.layoutDirection, layoutDirection)

Text(formatNumber(index * 2 + 1) + ".")
    .font(.system(size: 12))
```

### 5. Add Language Toggle Button
Add a button to switch between Persian and English:

```swift
Button(action: {
    currentLanguage = currentLanguage == "fa" ? "en" : "fa"
    // Reload or translate current poems
}) {
    Image(systemName: "globe")
        .font(.system(size: 20))
}
```

### 6. Loading State Localization
Create a localized strings file or use a simple dictionary:

```swift
private func localizedString(_ key: String) -> String {
    let strings: [String: [String: String]] = [
        "loading": [
            "fa": "در حال بارگذاری...",
            "en": "Loading..."
        ]
    ]
    return strings[key]?[currentLanguage] ?? key
}
```

## Translation Strategy Options

### Option 1: Pre-translated Database
- Pros: Fast, no API costs
- Cons: Limited poems, requires manual translation

### Option 2: Real-time API Translation
- Pros: Works with all poems
- Cons: API costs, slower
- Example: OpenAI API (as in your React app)

### Option 3: Hybrid Approach
- Keep popular poems pre-translated
- Use API for rare poems
- Cache translations locally

## Recommended Approach

Based on your React app implementation, I recommend:

1. **Fetch Persian poem** from Ganjoor API
2. **Store it** in the poems array
3. **On language toggle**, call translation API:
   - Send poem text to OpenAI/Google Translate
   - Receive translated text
   - Update the display
4. **Cache translations** to avoid re-translating

## Code Structure

```
Rubatar/
├── Models/
│   ├── GanjoorAPI.swift (✓ Done)
│   ├── TranslationManager.swift (To be created)
│   └── PoemData.swift (Add translation field)
├── Views/
│   └── ProfileView.swift (Add language toggle)
```

## PoemData Enhancement

Update `PoemData` to support translations:

```swift
struct PoemData: Identifiable {
    let id: Int
    let title: String
    let poet: PoetInfo
    let verses: [[String]]
    var translatedTitle: String?
    var translatedPoet: String?
    var translatedVerses: [[String]]?
}
```

This keeps both original and translated versions available for quick switching.

