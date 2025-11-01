# Localization Guide for RTL/LTR Layout

This guide explains how the app handles right-to-left (RTL) and left-to-right (LTR) layout direction for Farsi and English languages.

## Overview

Instead of manually checking `selectedLanguage == .farsi` throughout the codebase, we use SwiftUI's built-in layout direction system with a centralized `AppLanguage` enum that provides convenience properties.

## Implementation

### 1. AppLanguage Enum Extensions

The `AppLanguage` enum includes convenience properties that map languages to their corresponding layout properties:

```swift
enum AppLanguage: String {
    case english = "English"
    case farsi = "Farsi"
    
    /// Returns the SwiftUI layout direction for this language
    var layoutDirection: LayoutDirection {
        switch self {
        case .farsi: return .rightToLeft
        case .english: return .leftToRight
        }
    }
    
    /// Returns the horizontal alignment for this language (for VStack/HStack)
    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .farsi: return .trailing
        case .english: return .leading
        }
    }
    
    /// Returns the text alignment for this language
    var textAlignment: TextAlignment {
        switch self {
        case .farsi: return .trailing
        case .english: return .leading
        }
    }
    
    /// Returns the frame alignment for this language (for .frame(alignment:))
    var frameAlignment: Alignment {
        switch self {
        case .farsi: return .trailing
        case .english: return .leading
        }
    }
}
```

### 2. Setting Layout Direction at Root Level

In `ProfileView`, we set the layout direction environment at the root level:

```swift
var body: some View {
    ZStack {
        // ... content ...
    }
    .environment(\.layoutDirection, selectedLanguage.layoutDirection)
    // ... other modifiers ...
}
```

This ensures that all child views automatically respect the layout direction.

### 3. Using Convenience Properties

Instead of:
```swift
VStack(alignment: selectedLanguage == .farsi ? .trailing : .leading, spacing: 20)
```

Use:
```swift
VStack(alignment: selectedLanguage.horizontalAlignment, spacing: 20)
```

Instead of:
```swift
.environment(\.layoutDirection, selectedLanguage == .farsi ? .rightToLeft : .leftToRight)
```

Use:
```swift
.environment(\.layoutDirection, selectedLanguage.layoutDirection)
```

Instead of:
```swift
.frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
```

Use:
```swift
.frame(maxWidth: .infinity, alignment: selectedLanguage.frameAlignment)
```

Instead of:
```swift
.multilineTextAlignment(selectedLanguage == .farsi ? .trailing : .leading)
```

Use:
```swift
.multilineTextAlignment(selectedLanguage.textAlignment)
```

## Benefits

1. **Centralized Logic**: All layout direction logic is in one place (`AppLanguage` enum)
2. **Type Safety**: Properties are strongly typed, reducing errors
3. **Maintainability**: Easy to update alignment logic for all languages
4. **SwiftUI Integration**: Leverages SwiftUI's built-in layout direction system
5. **Consistency**: Ensures consistent alignment across all views

## Future Enhancements

If you want to use Apple's standard localization system:

1. **Add Localization Files**: Create `.lproj` folders (`en.lproj`, `fa.lproj`) with `Localizable.strings` files
2. **Use NSLocalizedString**: Replace hardcoded strings with `NSLocalizedString("key", comment: "")`
3. **Set App Language**: Use `Locale` and `Bundle` to set the app's language
4. **Automatic Layout Direction**: SwiftUI will automatically set layout direction based on the locale

However, since your app uses a custom language selection system (not tied to system locale), the current approach with `AppLanguage` enum is the most appropriate solution.

## References

- [Apple's Localization Documentation](https://developer.apple.com/documentation/SwiftUI/Preparing-views-for-localization)
- [SwiftUI LayoutDirection](https://developer.apple.com/documentation/swiftui/layoutdirection)

