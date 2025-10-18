# OpenAI Translation Setup

## Overview
The app now automatically translates Persian poems to English using OpenAI's GPT-4 API. Translations happen in the background as poems are loaded.

## Setup Instructions

### 1. Get Your OpenAI API Key
1. Go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy the key (starts with `sk-...`)

### 2. Add API Key to Config
Open `Rubatar/Config.swift` and replace:
```swift
static let openAIAPIKey = "YOUR_OPENAI_API_KEY_HERE"
```

With your actual key:
```swift
static let openAIAPIKey = "sk-your-actual-key-here"
```

### 3. Important Security Note
⚠️ **DO NOT commit your API key to Git!**

Add `Config.swift` to `.gitignore`:
```bash
echo "Rubatar/Config.swift" >> .gitignore
```

Or use environment variables in production.

## How It Works

### Automatic Translation Flow
1. **Load Poems**: App fetches 4 Persian poems from Ganjoor API
2. **Trigger Translation**: Automatically calls `translatePoemsIfNeeded()`
3. **OpenAI Translation**: Each poem is sent to GPT-4 for poetic translation
4. **Cache Results**: Translations are stored in `translatedPoems` dictionary
5. **Display**: UI automatically shows translated version once available

### Translation Features
- ✅ **Poetic Translation**: Maintains metaphors, rhythm, and literary beauty
- ✅ **Automatic Format**: Numbers change to English (1, 2, 3...)
- ✅ **LTR Layout**: Text automatically switches to left-to-right
- ✅ **Caching**: Each poem is only translated once
- ✅ **Background Processing**: Doesn't block UI while translating
- ✅ **Poet Name Translation**: Common Persian poets automatically translated (Hafez, Rumi, etc.)

### Cost Estimation
Using **GPT-4**:
- Average poem: ~200 tokens input + ~300 tokens output = 500 tokens
- Cost: ~$0.015 per poem ($0.03/1K input + $0.06/1K output)
- 100 poems ≈ $1.50

Using **GPT-3.5-Turbo** (cheaper, faster):
- Same poem: ~$0.0007 per poem
- 100 poems ≈ $0.07

To use GPT-3.5-Turbo instead, update `Config.swift`:
```swift
static let translationModel = "gpt-3.5-turbo"
```

## Translation Prompt
The system uses a specialized prompt that:
- Instructs GPT to maintain poetic structure
- Preserves metaphors and imagery
- Keeps emotional tone and literary beauty
- Translates as authentic English poetry (not literal)
- Maintains the same number of lines

Example translation:
```
Persian:
روی ترش کرده به یاران مبین
سرکه فروشی مکن ای انگبین

English Translation:
Do not show your friends a sour face
O honey, do not sell vinegar in place
```

## Customization

### Adjust Translation Quality
In `Config.swift`:
```swift
static let translationTemperature = 0.7 // Higher = more creative (0.0-1.0)
static let translationMaxTokens = 1000  // Longer poems need more tokens
```

### Change Translation Model
```swift
static let translationModel = "gpt-4"           // Best quality
// or
static let translationModel = "gpt-3.5-turbo"  // Faster & cheaper
// or
static let translationModel = "gpt-4-turbo"    // Balance of both
```

## Troubleshooting

### "Failed to translate" errors
- Check your API key is correct
- Ensure you have API credits
- Check internet connection
- Verify OpenAI API status

### Translations not appearing
- Check console logs for errors
- Ensure `translatePoemsIfNeeded()` is being called
- Verify API key starts with `sk-`

### Slow translations
- Switch to `gpt-3.5-turbo` for faster results
- Reduce `translationMaxTokens` if poems are short
- Consider pre-translating popular poems

## Future Enhancements

### Optional Features to Add:
1. **Translation Toggle**: Let users switch between Persian and English
2. **Offline Caching**: Save translations to CoreData
3. **Pre-translated Database**: Store popular poems pre-translated
4. **Multiple Engines**: Add Google Translate as backup
5. **Quality Rating**: Let users rate translation quality

## API Reference

### TranslationManager
Located in `Rubatar/Models/TranslationManager.swift`

```swift
class TranslationManager {
    init(apiKey: String)
    
    // Translate a Persian poem to English
    func translatePoem(_ poem: PoemData) async -> PoemData?
}
```

### Poet Name Translations
Common poets are automatically translated:
- حافظ → Hafez
- خیام → Khayyam / Omar Khayyam
- مولانا → Rumi
- سعدی → Saadi
- فردوسی → Ferdowsi
- نظامی → Nizami

Add more in `TranslationManager.translatePoetName()`

