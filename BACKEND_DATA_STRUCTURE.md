# Backend Data Structure Analysis

## Current Supabase Data Returned (from PoetryService.swift)

### 1. **SupabasePoem** - Main Poem Data
```swift
struct SupabasePoem {
    id: String
    poet_id: String
    poem_name_en: String
    poem_name_fa: String
    poem_number: Int?
    poem_content_en: String
    poem_content_fa: String
    topic_id: Int?              // Foreign key to topics table
    form: String?                // ⚠️ Single form field (not form_fa/form_en)
    language_original: String?
    source_reference: String?
    created_at: String
    updated_at: String
    tafseer_line_by_line_fa: [LineByLineTafseer]?
    tafseer_line_by_line_en: [LineByLineTafseer]?
    tafseer_fa: String?
    tafseer_en: String?
    
    // ❌ MISSING: book_id
    // ❌ MISSING: form_fa and form_en (only has single "form")
}
```

### 2. **SupabasePoet** - Poet Information
```swift
struct SupabasePoet {
    id: String
    name_en: String
    name_fa: String
    nickname_en: String?
    nickname_fa: String?
    biography_en: String?        // ✅ Available
    biography_fa: String?        // ✅ Available
    era: String?                 // ✅ Available
    // ... other fields
}
```

### 3. **SupabaseTopic** - Topic Information
```swift
struct SupabaseTopic {
    id: Int
    topic_en: String
    topic_fa: String
    description: String?
}
```

### 4. **SupabaseMood** - Mood Information
```swift
struct SupabaseMood {
    id: Int
    mood_en: String
    mood_fa: String
    color_hex: String?
}
```

### 5. **SupabasePoemMood** - Junction Table
```swift
struct SupabasePoemMood {
    id: Int
    poem_id: String
    mood_id: Int
    created_at: String
}
```

## What PoetryService Currently Fetches

1. ✅ **Poems** - from `/rest/v1/poems`
2. ✅ **Poets** - from `/rest/v1/poets` (by poet_id)
3. ✅ **Topics** - from `/rest/v1/topics` (by topic_id)
4. ✅ **Moods** - from `/rest/v1/moods` (via poem_moods junction table)
5. ✅ **Tafseer** - Already in SupabasePoem (tafseer_fa, tafseer_en, tafseer_line_by_line_fa, tafseer_line_by_line_en)

## What PoetryService Currently Maps to PoemData

```swift
PoemData {
    id: Int
    title: String (from poem_name_fa or poem_name_en)
    poet: PoetInfo (from SupabasePoet)
    verses: [[String]] (parsed from poem_content_fa or poem_content_en)
    topic: String? (from SupabaseTopic.topic_fa or topic_en) ✅
    mood: String? (from SupabaseMood.mood_fa or mood_en) ✅
    moodColor: String? (from SupabaseMood.color_hex) ✅
    tafseerLineByLineFa: [LineByLineTafseer]? ✅
    tafseerLineByLineEn: [LineByLineTafseer]? ✅
    tafseerFa: String? ✅
    tafseerEn: String? ✅
    
    // ❌ MISSING: formFa, formEn (form field exists but not language-specific)
    // ❌ MISSING: bookNameFa, bookNameEn (book_id not in SupabasePoem)
}
```

## Missing Fields for Deep Analysis Feature

To display Book, Mood, Topic, and Form in the Deep Analysis bottom sheet:

1. **Book**: 
   - ❌ `book_id` field is NOT in `SupabasePoem` struct
   - ❌ `SupabaseBook` struct doesn't exist
   - ❌ No fetch for books table

2. **Form**:
   - ⚠️ `form` field exists but is single String (not `form_fa`/`form_en`)
   - ❌ Not mapped to `PoemData.formFa`/`formEn`

3. **Mood**:
   - ✅ Already fetched and mapped correctly

4. **Topic**:
   - ✅ Already fetched and mapped correctly

## Sample Backend Response Structure

### Example Poem JSON from Supabase:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "poet_id": "660e8400-e29b-41d4-a716-446655440001",
  "poem_name_en": "Rubaiyat",
  "poem_name_fa": "رباعیات",
  "poem_content_en": "Wake! For the Sun...",
  "poem_content_fa": "برخیز که آفتاب...",
  "topic_id": 1,
  "form": "Quatrain",  // ⚠️ Only single value, not language-specific
  "tafseer_fa": "تفسیر فارسی...",
  "tafseer_en": "English interpretation...",
  "tafseer_line_by_line_fa": [
    {"line": "برخیز", "explanation": "برخاستن و بیدار شدن"}
  ],
  "tafseer_line_by_line_en": [
    {"line": "Wake", "explanation": "To arise and wake up"}
  ]
  // ❌ NO book_id field
}
```

### Example Poet JSON:
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "name_en": "Omar Khayyam",
  "name_fa": "عمر خیام",
  "biography_en": "Persian polymath...",
  "biography_fa": "دانشمند ایرانی...",
  "era": "11th-12th century"
}
```

### Example Mood (via poem_moods):
```json
// First from poem_moods table:
{
  "poem_id": "550e8400-e29b-41d4-a716-446655440000",
  "mood_id": 3
}

// Then from moods table:
{
  "id": 3,
  "mood_en": "Melancholic",
  "mood_fa": "غمگین",
  "color_hex": "#8B4513"
}
```

## Summary

**PoetryService handles:**
- ✅ Poems, Poets, Topics, Moods (via junction table)
- ✅ Tafseer (both line-by-line and full text) in Farsi and English
- ✅ Maps all of this to PoemData correctly

**PoetryService does NOT handle:**
- ❌ Book information (book_id missing from SupabasePoem)
- ❌ Form in language-specific format (only has single "form" field)

**To fix Deep Analysis:**
1. Backend needs to add `book_id` to `poems` table (or confirm it exists)
2. Backend needs to add `form_fa` and `form_en` to `poems` table (or use existing fields)
3. Need to create `SupabaseBook` struct and fetch from `books` table
4. Need to map these fields to `PoemData`

