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
    @State private var currentPage = 0 // Current page within a poem (verse index)
    @State private var showMenu = false
    @StateObject private var apiManager = GanjoorAPIManager()
    
    // Multiple poems from API
    @State private var poems: [PoemData] = []
    @State private var translatedPoems: [Int: PoemData] = [:] // Cache: poem.id -> translated poem
    @State private var isTranslating = false
    
    // Translation manager
    private let translationManager = TranslationManager(apiKey: Config.openAIAPIKey)
    
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
    
    var body: some View {
        ZStack {
            // F4F4F4 background
            Color(red: 244/255, green: 244/255, blue: 244/255)
                .ignoresSafeArea()
            
            // Paging carousel with peek of adjacent cards
            VStack(spacing: 0) {
                if poems.isEmpty || translatedPoems.isEmpty {
                    // Show loading skeleton cards until translations are ready
                    PagingScrollView(pageCount: 3, content: { _ in
                        PoemCardView(
                            poem: nil,
                            isTranslated: false,
                            toFarsiNumber: toFarsiNumber,
                            showMenu: $showMenu
                        )
                    }, currentPage: $currentPage)
                } else {
                    // Show only translated poem cards
                    let translatedPoemsList = poems.compactMap { poem -> PoemData? in
                        translatedPoems[poem.id]
                    }
                    
                    if translatedPoemsList.isEmpty {
                        // Still translating, show skeleton
                        PagingScrollView(pageCount: 3, content: { _ in
                            PoemCardView(
                                poem: nil,
                                isTranslated: false,
                                toFarsiNumber: toFarsiNumber,
                                showMenu: $showMenu
                            )
                        }, currentPage: $currentPage)
                    } else {
                        // Show translated poems
                        PagingScrollView(pageCount: translatedPoemsList.count, content: { index in
                            PoemCardView(
                                poem: translatedPoemsList[index],
                                isTranslated: true,
                                toFarsiNumber: toFarsiNumber,
                                showMenu: $showMenu
                            )
                        }, currentPage: $currentPage)
                    }
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
            
            // Liquid Glass Menu Overlay
            if showMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showMenu = false
                    }
                
                VStack {
                    HStack {
                        Spacer()
                        LiquidGlassMenu(
                            isPresented: $showMenu,
                            onSave: {
                                print("Save tapped")
                            },
                            onShare: {
                                print("Share tapped")
                            },
                            onRefresh: {
                                print("Refresh tapped")
                            },
                            onGoToPoet: {
                                print("Go to poet tapped")
                            },
                            onInterpretation: {
                                print("Interpretation tapped")
                            },
                            onLanguage: {
                                print("Language tapped")
                            },
                            onConfigure: {
                                print("Configure tapped")
                            },
                            onThemes: {
                                print("Themes tapped")
                            }
                        )
                        .padding(.trailing, 24)
                    }
                    .padding(.top, 58)
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)))
            }
        }
        .navigationBarHidden(true)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showMenu)
        .onAppear {
            // Load initial poems from Ganjoor API
            Task {
                let initialPoems = await apiManager.fetchMultiplePoems(count: 10)
                if !initialPoems.isEmpty {
                    poems = initialPoems
                    currentPage = 0
                    
                    // Automatically translate poems
                    translatePoemsIfNeeded()
                }
            }
        }
    }
}

// Animated Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0), location: 0.0),
                        .init(color: Color.white.opacity(0.2), location: 0.3),
                        .init(color: Color.white.opacity(0.6), location: 0.5),
                        .init(color: Color.white.opacity(0.2), location: 0.7),
                        .init(color: Color.white.opacity(0), location: 1.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 500
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// Skeleton Loading View
struct SkeletonLoadingView: View {
    var body: some View {
        VStack(spacing: 8) {
            // Header with skeleton
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            // Title placeholder
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 246/255, green: 242/255, blue: 242/255))
                                .frame(width: 135, height: 32)
                                .shimmer()
                            
                            // Poet name placeholder
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 246/255, green: 242/255, blue: 242/255))
                                .frame(width: 87, height: 16)
                                .shimmer()
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: {}) {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {}) {
                                Image(systemName: "bookmark")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 48)
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
            }
            
            // Pages section with skeleton lines
            VStack(spacing: 10) {
                VStack(spacing: 8) {
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 209, height: 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 228, height: 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 162, height: 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 125, height: 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .shimmer()
                    }
                }
                .padding(.vertical, 16)
                
                VStack(spacing: 8) {
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 209, height: 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 228, height: 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 162, height: 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .shimmer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 246/255, green: 242/255, blue: 242/255))
                            .frame(width: 125, height: 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .shimmer()
                    }
                }
                .padding(.vertical, 16)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            
        }
        .background(Color(red: 244/255, green: 244/255, blue: 244/255))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// Individual Poem Card Component
struct PoemCardView: View {
    let poem: PoemData?
    let isTranslated: Bool
    let toFarsiNumber: (Int) -> String
    @Binding var showMenu: Bool
    
    @State private var versePage = 0 // Current verse page within the poem
    
    var body: some View {
        // Show skeleton if no poem data
        if poem == nil {
            SkeletonLoadingView()
        } else {
            actualPoemView
        }
    }
    
    private var actualPoemView: some View {
        let poemData = poem! // Force unwrap since we checked for nil
        
        return VStack(spacing: 8) {
            // Header
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(poemData.title)
                                .font(.custom("Palatino-Roman", size: 24))
                                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 67/255, opacity: 0.6))
                                .kerning(-0.43)
                                .lineSpacing(22)
                            
                            Text(poemData.poet.name)
                                .font(.custom("Palatino-Roman", size: 16))
                                .foregroundColor(Color(red: 122/255, green: 92/255, blue: 57/255))
                                .kerning(-0.23)
                                .lineSpacing(20)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: {}) {
                                Image(systemName: "bookmark")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                showMenu.toggle()
                            }) {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 48)
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
            }
            
            // Pages section with page curl
            if !poemData.verses.isEmpty {
                let beytsPerPage = 4
                let totalPages = (poemData.verses.count + beytsPerPage - 1) / beytsPerPage
                
                PageCurlView(currentPage: $versePage, pageCount: totalPages) { pageIndex in
                    VStack(alignment: .center, spacing: 0) {
                        let startBeytIndex = pageIndex * beytsPerPage
                        let endBeytIndex = min(startBeytIndex + beytsPerPage, poemData.verses.count)
                        
                        ForEach(startBeytIndex..<endBeytIndex, id: \.self) { beytIndex in
                            if beytIndex < poemData.verses.count {
                                let beyt = poemData.verses[beytIndex]
                                
                                VStack(alignment: .center, spacing: 10) {
                                    // First line of beyt
                                    if beyt.count > 0 {
                                        Text(beyt[0])
                                            .font(isTranslated ? .custom("Palatino-Roman", size: 16) : .system(size: 14))
                                            .foregroundColor(.black)
                                            .lineSpacing(isTranslated ? 4 : 14 * 2.66)
                                            .kerning(1)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .multilineTextAlignment(.center)
                                    }
                                    
                                    // Second line of beyt
                                    if beyt.count > 1 {
                                        Text(beyt[1])
                                            .font(isTranslated ? .custom("Palatino-Roman", size: 16) : .system(size: 14))
                                            .foregroundColor(.black)
                                            .lineSpacing(isTranslated ? 4 : 14 * 2.66)
                                            .kerning(1)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding(.bottom, beytIndex < endBeytIndex - 1 ? 24 : 0)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color.white)
                    .cornerRadius(totalPages > 1 ? 0 : 12, corners: [.bottomLeft, .bottomRight])
                }
                .id(poemData.id)
            } else {
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
            
            // Page control with bottom corners rounded (only show if more than 1 page)
            let beytsPerPage = 4
            let totalPages = (poemData.verses.count + beytsPerPage - 1) / beytsPerPage
            
            if totalPages > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { pageIndex in
                        Circle()
                            .fill(pageIndex == versePage ? Color.black : Color.black.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.white)
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            }
        }
        .background(Color(red: 244/255, green: 244/255, blue: 244/255))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    ProfileView()
}
