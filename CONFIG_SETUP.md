# 🔑 Config.swift Setup for Local Development

## Issue Fixed
The "Cannot find 'Config' in scope" error has been resolved. `Config.swift` is now included in the repository.

## ⚠️ Important: OpenAI API Key Required

### For Local Development:
The OpenAI API key is **not** included in the repository for security reasons.

**To enable poem translation locally:**

1. Open `Rubatar/Config.swift`
2. Replace `YOUR_OPENAI_API_KEY_HERE` with your actual OpenAI API key
3. Get your key at: https://platform.openai.com/api-keys

```swift
static let openAIAPIKey = "sk-proj-YOUR_ACTUAL_KEY_HERE"
```

### For App Store Connect / Xcode Cloud Builds:

The app will build successfully **without** the OpenAI key, but poem translation will be disabled.

**To enable translation in production:**

**Option 1: Xcode Cloud Environment Variables (Recommended)**
1. Go to App Store Connect → Xcode Cloud
2. Add environment variable: `OPENAI_API_KEY`
3. Set value to your OpenAI API key
4. Reference it in code using `ProcessInfo.processInfo.environment["OPENAI_API_KEY"]`

**Option 2: Manual Replacement**
- Replace the placeholder in `Config.swift` before archiving
- **Remember to revert before committing!**

## 🔓 Supabase Keys (Already Configured)

✅ Supabase URL and anon key are **already included** and safe to commit.

These are client-side public keys designed to be embedded in your app:
- `supabaseURL`: `https://pspybykovwrfdxpkjpzd.supabase.co`
- `supabaseAnonKey`: Public anon key (safe in client-side code)

Supabase Row Level Security (RLS) policies protect your data, not the anon key.

## 📋 What Works Without OpenAI Key:

✅ **App Store Connect builds** - Will compile successfully  
✅ **All music features** - Full Apple Music integration  
✅ **Poetry display** - Rubaiyat from Supabase backend  
✅ **All UI features** - Dark mode, animations, etc.

❌ **Poem translation** - Will fail silently (English translations won't load)

## 🚀 Quick Start:

```bash
# 1. Clone the repo
git clone https://github.com/m3ghdad/RubatarMusicPlayer.git

# 2. Open in Xcode
open Rubatar.xcodeproj

# 3. (Optional) Add your OpenAI key in Rubatar/Config.swift

# 4. Build and run!
```

## 📱 App Store Submission Ready

The app is **ready to submit to App Store Connect** as-is. The missing OpenAI key will not prevent:
- ✅ Building/archiving
- ✅ TestFlight distribution
- ✅ App Store submission
- ✅ Core app functionality

Translation is an optional feature that can be added later.

---

**Need help?** Check `APP_STORE_SETUP.md` for detailed submission instructions.

