//
//  LiquidGlassMenu.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/17/25.
//

import SwiftUI

struct LiquidGlassMenu: View {
    @Binding var isPresented: Bool
    let selectedLanguage: AppLanguage
    @Binding var showLanguageMenu: Bool
    let onSave: () -> Void
    let onShare: () -> Void
    let onSelectText: () -> Void
    let onRefresh: () -> Void
    let onGoToPoet: () -> Void
    let onInterpretation: () -> Void
    let onLanguage: () -> Void
    let onSelectLanguage: (AppLanguage) -> Void
    let onConfigure: () -> Void
    let onThemes: () -> Void
    
    @State private var hoveredItem: String? = nil
    @State private var dragLocation: CGPoint? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Quick Actions - Top Section
            HStack(spacing: 6) {
                // Save Quick Action
                QuickActionButton(
                    id: "save",
                    icon: "bookmark",
                    title: "Save",
                    isHovered: hoveredItem == "save"
                )
                
                // Share Quick Action
                QuickActionButton(
                    id: "share",
                    icon: "square.and.arrow.up",
                    title: "Share",
                    isHovered: hoveredItem == "share"
                )
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 0)
            
            // Menu Items
            VStack(spacing: 0) {
                // Separator
                HStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color(hex: "E6E6E6"))
                        .frame(height: 1)
                }
                .frame(height: 21)
                .padding(.horizontal, 24)
                
                // Select text
                MenuItemView(
                    id: "selecttext",
                    icon: "document.on.clipboard",
                    title: "Select text",
                    isHovered: hoveredItem == "selecttext"
                )
                
                // Refresh
                MenuItemView(
                    id: "refresh",
                    icon: "arrow.clockwise",
                    title: "Refresh",
                    isHovered: hoveredItem == "refresh"
                )
                
                // Go to poet
                MenuItemView(
                    id: "poet",
                    icon: "text.page.badge.magnifyingglass",
                    title: "Go to poet",
                    isHovered: hoveredItem == "poet"
                )
                
                // Separator
                HStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color(hex: "E6E6E6"))
                        .frame(height: 1)
                }
                .frame(height: 21)
                .padding(.horizontal, 24)
                
                // Interpretation
                MenuItemView(
                    id: "interpretation",
                    icon: "book.pages",
                    title: "Interpretation",
                    isHovered: hoveredItem == "interpretation"
                )
                
                // Separator
                HStack {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color(hex: "E6E6E6"))
                        .frame(height: 1)
                }
                .frame(height: 21)
                .padding(.horizontal, 24)
                
                // Language
                MenuItemView(
                    id: "language",
                    icon: "globe.fill",
                    title: "Language",
                    subtitle: selectedLanguage.rawValue,
                    hasChevron: true,
                    chevronDown: showLanguageMenu,
                    isHovered: hoveredItem == "language"
                )
                
                // Expandable language options
                if showLanguageMenu {
                    VStack(spacing: 0) {
                        // English option
                        Button(action: {
                            onSelectLanguage(.english)
                        }) {
                            HStack(spacing: 8) {
                                // Checkmark (24x24 frame with centered icon)
                                ZStack {
                                    if selectedLanguage == .english {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                                    }
                                }
                                .frame(width: 24, height: 22)
                                
                                // Label
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("English")
                                        .font(.system(size: 17))
                                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .padding(.leading, 28) // Indent for sub-items
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(hoveredItem == "english" ? (colorScheme == .dark ? Color.white.opacity(0.15) : Color(hex: "EDEDED")) : Color.clear)
                                    .padding(.horizontal, 8)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        // Farsi option
                        Button(action: {
                            onSelectLanguage(.farsi)
                        }) {
                            HStack(spacing: 8) {
                                // Checkmark (24x24 frame with centered icon)
                                ZStack {
                                    if selectedLanguage == .farsi {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                                    }
                                }
                                .frame(width: 24, height: 22)
                                
                                // Label
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Farsi")
                                        .font(.system(size: 17))
                                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .padding(.leading, 28) // Indent for sub-items
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(hoveredItem == "farsi" ? (colorScheme == .dark ? Color.white.opacity(0.15) : Color(hex: "EDEDED")) : Color.clear)
                                    .padding(.horizontal, 8)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Configure
                MenuItemView(
                    id: "configure",
                    icon: "textformat",
                    title: "Configure",
                    hasChevron: true,
                    isHovered: hoveredItem == "configure"
                )
                
                // Themes
                MenuItemView(
                    id: "themes",
                    icon: "square.text.square",
                    title: "Themes",
                    hasChevron: true,
                    isHovered: hoveredItem == "themes"
                )
            }
            .padding(.bottom, 10)
        }
        .frame(width: 238)
        .background(
            LiquidGlassBackground(cornerRadius: 34)
        )
        .coordinateSpace(name: "menu")
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("menu"))
                .onChanged { value in
                    dragLocation = value.location
                    updateHoveredItem(at: value.location)
                }
                .onEnded { value in
                    // Only execute action if we end on a valid item
                    if let item = hoveredItem {
                        executeAction(for: item)
                    }
                    hoveredItem = nil
                    dragLocation = nil
                    isPresented = false
                }
        )
    }
    
    private func updateHoveredItem(at location: CGPoint) {
        // Quick Actions area (top section)
        if location.y >= 10 && location.y <= 76 { // 10 top padding + 56 height + 10 spacing
            if location.x < 119 { // Half of 238
                setHoveredItem("save")
            } else {
                setHoveredItem("share")
            }
        }
        // Menu items area (starting after quick actions + separator)
        else if location.y > 97 { // After separator
            let menuY = location.y - 97
            
            // Select text: 0-40
            if menuY >= 0 && menuY < 40 {
                setHoveredItem("selecttext")
            }
            // Refresh: 40-80
            else if menuY >= 40 && menuY < 80 {
                setHoveredItem("refresh")
            }
            // Go to poet: 80-120
            else if menuY >= 80 && menuY < 120 {
                setHoveredItem("poet")
            }
            // Separator + Interpretation: 141-181
            else if menuY >= 141 && menuY < 181 {
                setHoveredItem("interpretation")
            }
            // Language: 202-242
            else if menuY >= 202 && menuY < 242 {
                setHoveredItem("language")
            }
            // Configure: 242-282
            else if menuY >= 242 && menuY < 282 {
                setHoveredItem("configure")
            }
            // Themes: 282-322
            else if menuY >= 282 && menuY < 322 {
                setHoveredItem("themes")
            }
            else {
                hoveredItem = nil
            }
        } else {
            hoveredItem = nil
        }
    }
    
    private func setHoveredItem(_ item: String) {
        if hoveredItem != item {
            // Trigger haptic feedback immediately when hovering over a new item
            DispatchQueue.main.async {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.prepare() // Prepare for immediate response
                impact.impactOccurred()
            }
            hoveredItem = item
        }
    }
    
    private func executeAction(for item: String) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        switch item {
        case "save":
            onSave()
        case "share":
            onShare()
        case "selecttext":
            onSelectText()
        case "refresh":
            onRefresh()
        case "poet":
            onGoToPoet()
        case "interpretation":
            onInterpretation()
        case "language":
            onLanguage()
        case "configure":
            onConfigure()
        case "themes":
            onThemes()
        default:
            break
        }
    }
}

struct MenuItemView: View {
    let id: String
    let icon: String
    let title: String
    var subtitle: String? = nil
    var hasChevron: Bool = false
    var chevronDown: Bool = false
    var isHovered: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                .frame(width: 28, alignment: .center)
            
            // Label and Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(colorScheme == .dark ? Color(hex: "CCCCCC") : Color(hex: "999999"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Chevron
            if hasChevron {
                Image(systemName: chevronDown ? "chevron.down" : "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    .frame(width: 14)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? (colorScheme == .dark ? Color.white.opacity(0.15) : Color(hex: "EDEDED")) : Color.clear)
                .padding(.horizontal, 8) // 8px padding from edges
        )
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}

struct QuickActionButton: View {
    let id: String
    let icon: String
    let title: String
    var isHovered: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                .frame(height: 22)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isHovered ? (colorScheme == .dark ? Color.white.opacity(0.15) : Color(hex: "EDEDED")) : Color.clear)
                .padding(.horizontal, 8) // 8px padding from edges
        )
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}

struct LiquidGlassBackground: View {
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        // Figma-exact Liquid Glass Effect
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        colorScheme == .dark ?
                        Color(red: 44/255, green: 44/255, blue: 46/255).opacity(0.8) :
                        Color(red: 245/255, green: 245/255, blue: 245/255).opacity(0.6)
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                radius: 20,
                x: 0,
                y: 10
            )
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        
        LiquidGlassMenu(
            isPresented: .constant(true),
            selectedLanguage: .english,
            showLanguageMenu: .constant(false),
            onSave: {},
            onShare: {},
            onSelectText: {},
            onRefresh: {},
            onGoToPoet: {},
            onInterpretation: {},
            onLanguage: {},
            onSelectLanguage: { _ in },
            onConfigure: {},
            onThemes: {}
        )
    }
}

