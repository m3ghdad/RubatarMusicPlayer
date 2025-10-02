# Apple Liquid Glass Tab Bar

A modern iOS app showcasing Apple's Liquid Glass design language with a beautiful tab bar interface and immersive modal experience.

## ✨ Features

### 🎯 Core UI Components

#### **Liquid Glass Tab Bar**
- **5 Tab Navigation**: Home, Search, Trips, Plan, Profile
- **SF Symbols Integration**: Native iOS icons for each tab
- **Apple HIG Compliance**: Follows official Human Interface Guidelines
- **Adaptive Theming**: Light and dark mode support
- **Liquid Glass Effects**: Translucent materials with proper blur and shadows

#### **Welcome Modal & Video Experience**
- **Full-Screen Video Experience**: Immersive background with scenic content
- **Apple Liquid Glass Play Button**: Authentic translucent play controller with `.glassEffect()`
- **Smart Dismissal**: Drag-to-dismiss transforms into mini player
- **Mini Player**: Persistent floating player above tab bar with liquid glass background
- **Video Card**: Expandable card in Home tab with rounded corners and play functionality
- **Smooth Animations**: Native iOS transitions with spring animations
- **Responsive Design**: Optimized for all iPhone sizes

#### **Background Customization**
- **5 Unique Color Themes**: Ocean, Forest, Sunset, Lavender, Midnight
- **Persistent Settings**: User preferences saved with `@AppStorage`
- **Real-Time Updates**: Dynamic background changes
- **Theme Synchronization**: Consistent across all views

### 🎨 Design System

#### **Liquid Glass Implementation**
```swift
// Authentic Apple Liquid Glass Material
.ultraThinMaterial
.background(.ultraThinMaterial, in: Circle())
.glassEffect(in: Circle()) // Official Apple Glass Effect
.shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
.shadow(color: .white.opacity(0.15), radius: 2, x: 0, y: -1)

// Video Card with Selective Corner Radius
.clipShape(
    .rect(
        topLeadingRadius: 12,
        bottomLeadingRadius: 0,
        bottomTrailingRadius: 0,
        topTrailingRadius: 12
    )
)
```

#### **Color Palette**
- **Ocean**: `#007AFF` - Calm and professional
- **Forest**: `#34C759` - Natural and refreshing  
- **Sunset**: `#FF9500` - Warm and energetic
- **Lavender**: `#AF52DE` - Creative and modern
- **Midnight**: `#1C1C1E` - Sophisticated and elegant

### 🛠 Technical Implementation

#### **SwiftUI Architecture**
- **Modern SwiftUI**: Built with iOS 17+ features
- **MVVM Pattern**: Clean separation of concerns
- **State Management**: `@State`, `@Binding`, `@AppStorage`
- **Reactive Updates**: Real-time UI synchronization

#### **Key Components**
```swift
// Tab Bar Implementation
TabView(selection: $selectedTab) {
    HomeView()
        .tabItem {
            Image(systemName: "house.fill")
            Text("Home")
        }
    // ... additional tabs
}

// Modal Presentation
.sheet(isPresented: $showWelcomeModal) {
    WelcomeModalView(isDarkMode: isDarkMode) {
        showWelcomeModal = false
    }
    .presentationDetents([.fraction(0.75)])
    .presentationDragIndicator(.visible)
}
```

### 📱 User Experience

#### **Navigation Flow**
1. **App Launch**: Welcome modal appears automatically with video content
2. **Modal Interaction**: Tap play button to engage, drag down to minimize
3. **Mini Player**: Persistent player above tab bar with play/dismiss controls
4. **Video Card**: Dismissing mini player creates expandable card in Home tab
5. **Tab Navigation**: Seamless switching between sections
6. **Theme Selection**: Profile tab for customization
7. **Search Integration**: Native iOS search functionality

#### **Accessibility**
- **VoiceOver Support**: Full accessibility compliance
- **Dynamic Type**: Respects user font size preferences
- **Color Contrast**: WCAG compliant color combinations
- **Touch Targets**: 44pt minimum touch areas

### 🚀 Getting Started

#### **Requirements**
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

#### **Installation**
1. Clone the repository:
```bash
git clone https://github.com/m3ghdad/AppleLiquidGlassTapBar.git
```

2. Open in Xcode:
```bash
cd AppleLiquidGlassTapBar
open AppleLiquidGlassTapBar.xcodeproj
```

3. Build and run on simulator or device

### 🎯 Key Features Showcase

#### **Advanced Video Experience**
- **Liquid Glass Play Button**: Official `.glassEffect()` for authentic Apple material
- **Multi-State Player**: Full modal → Mini player → Video card transitions
- **Smart Positioning**: Mini player floats above tab bar with 8px spacing
- **Gesture Recognition**: Drag-to-dismiss with smooth snap animations
- **Touch Optimization**: 44pt minimum tap targets for accessibility
- **Visual Hierarchy**: Selective corner radius and proper content padding

#### **Dynamic Theming**
- **System Integration**: Respects user's system theme
- **Custom Colors**: 5 unique background options
- **Persistent Storage**: Settings saved across app launches
- **Real-Time Updates**: Immediate visual feedback

#### **Interactive Modal System**
- **Full-Width Video**: Immersive content display with AsyncImage loading
- **Three-State Design**: Modal → Mini Player → Video Card workflow
- **Gesture Intelligence**: Distinguishes between drag-dismiss and button actions
- **Persistent State**: Mini player maintains position during navigation
- **Content Flexibility**: Easy text and image updates across all states
- **Spring Animations**: Smooth transitions with proper easing curves

### 🔧 Customization

#### **Adding New Tabs**
```swift
// In ContentView.swift
Tab("New Tab", systemImage: "icon.name") {
    NewTabView()
}
```

#### **Customizing Colors**
```swift
// In ProfileView.swift
let customColors = [
    Color.blue,    // Ocean
    Color.green,   // Forest
    Color.orange,  // Sunset
    Color.purple,  // Lavender
    Color.black   // Midnight
]
```

#### **Modal Content**
```swift
// Update WelcomeModalView
Text("Your Custom Title")
Text("Your custom description text...")
Button("Your CTA Text") { /* action */ }
```

#### **Video Card Implementation**
```swift
// VideoCardView with selective corner radius
struct VideoCardView: View {
    let onPlayTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Video thumbnail with top-only corner radius
            AsyncImage(url: URL(string: "your-image-url")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(.quaternary)
            }
            .frame(height: 180)
            .clipShape(.rect(
                topLeadingRadius: 12,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 12
            ))
            
            // Content with 24px vertical padding
            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Description text...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 24)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
```

### 📸 Screenshots

*Add screenshots of your app here to showcase the UI*

### 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### 🙏 Acknowledgments

- **Apple Design Guidelines**: For Liquid Glass design principles
- **SF Symbols**: For beautiful, consistent iconography
- **SwiftUI**: For modern, declarative UI framework
- **Unsplash**: For high-quality background images

---

**Built with ❤️ using SwiftUI and Apple's Liquid Glass design language**
