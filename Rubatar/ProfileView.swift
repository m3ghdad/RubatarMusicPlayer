//
//  ProfileView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import SwiftUI

// Custom dashed line shape
struct DashedLine: Shape {
    let dashCount: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let dashWidth = rect.width / CGFloat(dashCount * 2 - 1)
        
        for i in 0..<dashCount {
            let x = CGFloat(i * 2) * dashWidth
            path.move(to: CGPoint(x: x, y: rect.midY))
            path.addLine(to: CGPoint(x: x + dashWidth, y: rect.midY))
        }
        
        return path
    }
}

struct ProfileView: View {
    @State private var showProfileSheet = false
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0
    @State private var currentPage = 0 // Current page within a poem (verse index)
    @State private var currentPoemIndex = 0 // Current poem index in the poems array
    @StateObject private var apiManager = GanjoorAPIManager()
    
    // Multiple poems from API
    @State private var poems: [PoemData] = []
    @State private var translatedPoems: [Int: PoemData] = [:] // Cache: poem.id -> translated poem
    @State private var isTranslating = false
    
    // Translation manager
    private let translationManager = TranslationManager(apiKey: Config.openAIAPIKey)
    
    // Computed property for current poem (returns translated version if available)
    private var currentPoem: PoemData? {
        guard !poems.isEmpty, currentPoemIndex < poems.count else { return nil }
        let originalPoem = poems[currentPoemIndex]
        
        // Return translated version if available, otherwise original
        return translatedPoems[originalPoem.id] ?? originalPoem
    }
    
    // Helper function to convert numbers to Farsi numerals
    private func toFarsiNumber(_ number: Int) -> String {
        let farsiDigits = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]
        return String(number).compactMap { char in
            guard let digit = Int(String(char)) else { return String(char) }
            return farsiDigits[digit]
        }.joined()
    }
    
    // Translate poems automatically
    private func translatePoemsIfNeeded() {
        Task {
            for poem in poems {
                // Skip if already translated
                guard translatedPoems[poem.id] == nil else { continue }
                
                isTranslating = true
                
                if let translated = await translationManager.translatePoem(poem) {
                    translatedPoems[poem.id] = translated
                }
                
                isTranslating = false
            }
        }
    }
    
    // Check if current poem is translated (for formatting)
    private var isCurrentPoemTranslated: Bool {
        guard !poems.isEmpty, currentPoemIndex < poems.count else { return false }
        let originalPoem = poems[currentPoemIndex]
        return translatedPoems[originalPoem.id] != nil
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            getBackgroundColors()[selectedBackgroundColor].gradient
                .ignoresSafeArea()
            
        NavigationView {
                VStack(spacing: 0) {
                    // Header
                HStack {
                        Text("Rubatar")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                        AvatarButtonView(action: {
                            showProfileSheet = true
                        })
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 27.5)
                    .padding(.bottom, 16)
                    
                    // Main content area (F4F4F4 background)
                    // Main container with exact Figma spacing
                    VStack(spacing: 24) {
                        // Poem card container with 8px spacing between all sections
                        VStack(spacing: 8) {
                            // Header section - fixed with dashed bottom border
                            VStack(spacing: 10) {
                                VStack(spacing: 4) {
                                    // Title and buttons row
                                    HStack(alignment: .top, spacing: 0) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(currentPoem?.title ?? "Loading...")
                                                .font(.custom("Palatino-Roman", size: 24))
                                                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 67/255, opacity: 0.6))
                                                .kerning(-0.43)
                                                .lineSpacing(22)
                                            
                                            Text(currentPoem?.poet.name ?? "")
                                                .font(.custom("Palatino-Roman", size: 16))
                                                .foregroundColor(Color(red: 122/255, green: 92/255, blue: 57/255))
                                                .kerning(-0.23)
                                                .lineSpacing(20)
                        }
                        
                        Spacer()
                        
                                        HStack(spacing: 8) {
                                            Button(action: {}) {
                                                Image(systemName: "book.closed")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(.primary)
                                                    .frame(width: 28, height: 28)
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Button(action: {}) {
                                                Image(systemName: "heart")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(.primary)
                                                    .frame(width: 28, height: 28)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.top, 48)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                            .background(Color.white)
                            .overlay(
                                VStack {
                                    Spacer()
                                    DashedLine(dashCount: 12)
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                        .frame(height: 1)
                                }
                            )
                            
                            // Pages section with page curl - fills available space
                            if let poem = currentPoem, !poem.verses.isEmpty {
                                // Show 2 beyts per page (4 lines total)
                                let beytsPerPage = 2
                                let totalPages = (poem.verses.count + beytsPerPage - 1) / beytsPerPage
                                
                                    PageCurlView(currentPage: $currentPage, pageCount: totalPages) { pageIndex in
                                    VStack(alignment: isCurrentPoemTranslated ? .leading : .trailing, spacing: 0) {
                                        // Calculate which beyts to show on this page
                                        let startBeytIndex = pageIndex * beytsPerPage
                                        let endBeytIndex = min(startBeytIndex + beytsPerPage, poem.verses.count)
                                        
                                        ForEach(startBeytIndex..<endBeytIndex, id: \.self) { beytIndex in
                                            if beytIndex < poem.verses.count {
                                                let beyt = poem.verses[beytIndex]
                                                let beytNumber = beytIndex + 1 // Beyt number (1, 2, 3, ...)
                                                
                                                VStack(alignment: isCurrentPoemTranslated ? .leading : .trailing, spacing: 10) {
                                                    // First line of beyt
                                                    if beyt.count > 0 {
                                                        HStack(alignment: .top, spacing: 10) {
                                                            // For English (LTR): Number on left
                                                            if isCurrentPoemTranslated {
                                                                Text(String(beytNumber) + ".")
                                                                    .font(.system(size: 12))
                                                                    .foregroundColor(.black)
                                                                    .lineSpacing(16 * 1.66)
                                                                    .kerning(1)
                                                                    .frame(width: 20, alignment: .leading)
                                                            } else {
                                                                Spacer()
                                                            }
                                                            
                                                            Text(beyt[0])
                                                                .font(isCurrentPoemTranslated ? .custom("Palatino-Roman", size: 16) : .system(size: 16))
                                                                .foregroundColor(.black)
                                                                .lineSpacing(16 * 1.66)
                                                                .kerning(1)
                                                                .lineLimit(nil)
                                                                .fixedSize(horizontal: false, vertical: true)
                                                                .multilineTextAlignment(isCurrentPoemTranslated ? .leading : .trailing)
                                                                .environment(\.layoutDirection, isCurrentPoemTranslated ? .leftToRight : .rightToLeft)
                                                            
                                                            // For Farsi (RTL): Number on right
                                                            if !isCurrentPoemTranslated {
                                                                Text("." + toFarsiNumber(beytNumber))
                                                                    .font(.system(size: 12))
                                                                    .foregroundColor(.black)
                                                                    .lineSpacing(16 * 1.66)
                                                                    .kerning(1)
                                                                    .frame(width: 20, alignment: .trailing)
                                                            } else {
                                                                Spacer()
                                                            }
                                                        }
                                                    }
                                                    
                                                    // Second line of beyt (no number, same beyt)
                                                    if beyt.count > 1 {
                                                        HStack(alignment: .top, spacing: 10) {
                                                            // For English (LTR): Empty space on left
                                                            if isCurrentPoemTranslated {
                                                                Text("")
                                                                    .font(.system(size: 12))
                                                                    .frame(width: 20)
                                                            } else {
                                                                Spacer()
                                                            }
                                                            
                                                            Text(beyt[1])
                                                                .font(isCurrentPoemTranslated ? .custom("Palatino-Roman", size: 16) : .system(size: 16))
                                                                .foregroundColor(.black)
                                                                .lineSpacing(16 * 1.66)
                                                                .kerning(1)
                                                                .lineLimit(nil)
                                                                .fixedSize(horizontal: false, vertical: true)
                                                                .multilineTextAlignment(isCurrentPoemTranslated ? .leading : .trailing)
                                                                .environment(\.layoutDirection, isCurrentPoemTranslated ? .leftToRight : .rightToLeft)
                                                            
                                                            // For Farsi (RTL): Empty space on right
                                                            if !isCurrentPoemTranslated {
                                                                Text("")
                                                                    .font(.system(size: 12))
                                                                    .frame(width: 20)
                                                            } else {
                                                                Spacer()
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(.bottom, beytIndex < endBeytIndex - 1 ? 20 : 0) // Space between beyts
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                    .background(Color.white)
                                    .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                                }
                                .id(poem.id) // Force recreation when poem changes
                            } else {
                                // Loading state
                                VStack(spacing: 16) {
                                    ProgressView()
                                    Text("در حال بارگذاری...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .frame(height: 300)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                            }
                            
                                // Page control (separate, fixed at bottom of poem card)
                                HStack(spacing: 8) {
                                    let beytsPerPage = 2
                                    let totalPages = ((currentPoem?.verses.count ?? 0) + beytsPerPage - 1) / beytsPerPage
                                    ForEach(0..<totalPages, id: \.self) { pageIndex in
                                        Circle()
                                            .fill(pageIndex == currentPage ? Color.black : Color.black.opacity(0.3))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .background(Color(red: 244/255, green: 244/255, blue: 244/255))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                                
                            // Navigation buttons (previous, refresh, next)
                            HStack(spacing: 0) {
                                // Previous button - go to previous poem
                                LiquidGlassButton(icon: "chevron.left.circle.fill", action: {
                                    if currentPoemIndex > 0 {
                                        currentPoemIndex -= 1
                                        currentPage = 0 // Reset to first page of new poem
                                    }
                                })
                                .opacity(currentPoemIndex > 0 ? 1.0 : 0.3)
                                .disabled(currentPoemIndex == 0)
                                
                                Spacer()
                                
                                // Refresh button - load new poems
                                LiquidGlassButton(icon: "arrow.clockwise", action: {
                                    Task {
                                        currentPage = 0
                                        currentPoemIndex = 0
                                        translatedPoems.removeAll() // Clear translation cache
                                        let newPoems = await apiManager.fetchMultiplePoems(count: 4)
                                        if !newPoems.isEmpty {
                                            poems = newPoems
                                            translatePoemsIfNeeded() // Translate new poems
                                        }
                                    }
                                })
                            
                            Spacer()
                            
                            // Next button - go to next poem (or load more if at end)
                            LiquidGlassButton(icon: "chevron.right.circle.fill", action: {
                                if currentPoemIndex < poems.count - 1 {
                                    currentPoemIndex += 1
                                    currentPage = 0 // Reset to first page of new poem
                                } else {
                                    // Load more poems
                                    Task {
                                        let newPoems = await apiManager.fetchMultiplePoems(count: 4)
                                        if !newPoems.isEmpty {
                                            poems.append(contentsOf: newPoems)
                                            currentPoemIndex += 1
                                            currentPage = 0
                                            translatePoemsIfNeeded() // Translate newly loaded poems
                                        }
                                    }
                                }
                            })
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                    .background(Color(red: 244/255, green: 244/255, blue: 244/255))
                }
                .navigationBarHidden(true)
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileBottomSheet(isPresented: $showProfileSheet)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(16)
        }
        .onAppear {
            // Load initial poems from Ganjoor API
            Task {
                let initialPoems = await apiManager.fetchMultiplePoems(count: 4)
                if !initialPoems.isEmpty {
                    poems = initialPoems
                    currentPoemIndex = 0
                    currentPage = 0
                    
                    // Automatically translate poems
                    translatePoemsIfNeeded()
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}

