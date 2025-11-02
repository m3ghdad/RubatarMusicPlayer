# Daily Poem Widget Setup Guide

This guide will help you set up the Daily Poem widget for Rubatar.

## Files Created

1. `DailyPoemWidget.swift` - Main widget implementation with timeline provider
2. `WidgetDataManager.swift` - Data sharing between app and widget
3. `Info.plist` - Widget bundle configuration

## Required Manual Steps in Xcode

### 1. Add Widget Extension Target

1. In Xcode, go to **File → New → Target**
2. Select **Widget Extension**
3. Product Name: `RubatarWidget`
4. Organization Identifier: `com.meghdad`
5. Language: **Swift**
6. Include Configuration Intent: ❌ (uncheck)
7. Click **Finish**
8. **DO NOT** activate the scheme when prompted

### 2. Configure Widget Extension

1. Select the `RubatarWidget` target in Xcode
2. Go to **General** tab
3. Set **Deployment Info** to **iOS 26.0** (matching main app)
4. Set **Bundle Identifier** to `com.meghdad.RubatarWidget`

### 3. Add App Groups Entitlement

1. Select the `RubatarWidget` target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Check the box for `group.com.meghdad.Rubatar`
6. Ensure this matches the main app's App Group

### 4. Replace Default Widget Files

1. Delete the auto-generated files:
   - `RubatarWidget.swift` (default template)
   - `Assets.xcassets` (if generated)
   - `Preview Content` folder

2. Add the provided files:
   - Drag `DailyPoemWidget.swift` into the `RubatarWidget` folder
   - Drag `WidgetDataManager.swift` into the `RubatarWidget` folder
   - Replace the `Info.plist` with the provided one

### 5. Build Configuration

1. Select the `RubatarWidget` target
2. Go to **Build Settings**
3. Set **Swift Version** to **Swift 5**
4. Ensure **Base SDK** is **iOS 26.0**

### 6. Link Widget to Main App

1. Select the main `Rubatar` target
2. Go to **Build Phases**
3. Expand **Dependencies**
4. Add `RubatarWidget` as a dependency (if needed for shared code)

### 7. Update Main App to Save Widget Data

Add this to your `ProfileView.swift` or wherever poems are loaded:

```swift
import WidgetKit

// After loading a poem successfully
Task {
    if let poem = loadedPoem {
        let displayData = PoemDisplayData.from(poem, language: selectedLanguage.rawValue)
        WidgetDataManager.shared.saveDailyPoem(displayData)
    }
}
```

## Widget Features

### Small Widget
- Shows poet name
- First 4 lines of poem
- Rubatar branding

### Medium Widget
- Poet name and title
- 6 lines of poem content
- Daily poem label

### Large Widget
- Full poem display
- Poet information
- Topic metadata (if available)
- Date display

## Data Flow

1. **Main App** fetches poems from Supabase
2. **WidgetDataManager** saves selected poem to shared `UserDefaults`
3. **Widget** reads from shared storage on timeline refresh
4. Widget updates **every 12 hours** automatically

## Testing

1. Build and run the main `Rubatar` app
2. Build and run the `RubatarWidget` target
3. On the home screen, long-press and tap **+** to add widgets
4. Search for "Rubatar" or "Daily Poem"
5. Select size (Small, Medium, or Large)
6. Add to home screen

## Troubleshooting

### Widget Shows "No poem available"
- Ensure main app has fetched and saved a poem
- Check App Groups configuration matches in both targets
- Verify `group.com.meghdad.Rubatar` is enabled in both entitlements

### Widget Not Updating
- Check timeline policy (currently set to 12 hours)
- Manually reload: `WidgetCenter.shared.reloadAllTimelines()` in debug
- Verify `WidgetDataManager.saveDailyPoem()` is being called

### Build Errors
- Ensure `PoemDisplayData` is accessible to widget
- Check that `PoetryService` or necessary types are imported
- Verify deployment targets match (iOS 26.0)

## Next Steps

- [ ] Add widget configuration options (language preference, update frequency)
- [ ] Implement background refresh for daily poem updates
- [ ] Add deep linking to open full poem in app
- [ ] Support Farsi font rendering in widget
- [ ] Add widget statistics tracking

## Resources

- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [Human Interface Guidelines for Widgets](https://developer.apple.com/design/human-interface-guidelines/components/system-experiences/widgets/)
- [App Groups Documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)

