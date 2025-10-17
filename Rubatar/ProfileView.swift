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
                PagingScrollView(pageCount: poems.count, content: { index in
                    PoemCardView(
                        poem: translatedPoems[poems[index].id] ?? poems[index],
                        isTranslated: translatedPoems[poems[index].id] != nil,
                        toFarsiNumber: toFarsiNumber
                    )
                }, currentPage: $currentPage)
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .navigationBarHidden(true)
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

// Individual Poem Card Component
struct PoemCardView: View {
    let poem: PoemData
    let isTranslated: Bool
    let toFarsiNumber: (Int) -> String
    
    @State private var versePage = 0 // Current verse page within the poem
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(poem.title)
                                .font(.custom("Palatino-Roman", size: 24))
                                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 67/255, opacity: 0.6))
                                .kerning(-0.43)
                                .lineSpacing(22)
                            
                            Text(poem.poet.name)
                                .font(.custom("Palatino-Roman", size: 16))
                                .foregroundColor(Color(red: 122/255, green: 92/255, blue: 57/255))
                                .kerning(-0.23)
                                .lineSpacing(20)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
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
            if !poem.verses.isEmpty {
                let beytsPerPage = 2
                let totalPages = (poem.verses.count + beytsPerPage - 1) / beytsPerPage
                
                PageCurlView(currentPage: $versePage, pageCount: totalPages) { pageIndex in
                    VStack(alignment: isTranslated ? .leading : .trailing, spacing: 0) {
                        let startBeytIndex = pageIndex * beytsPerPage
                        let endBeytIndex = min(startBeytIndex + beytsPerPage, poem.verses.count)
                        
                        ForEach(startBeytIndex..<endBeytIndex, id: \.self) { beytIndex in
                            if beytIndex < poem.verses.count {
                                let beyt = poem.verses[beytIndex]
                                let beytNumber = beytIndex + 1
                                
                                VStack(alignment: isTranslated ? .leading : .trailing, spacing: 10) {
                                    // First line of beyt
                                    if beyt.count > 0 {
                                        HStack(alignment: .top, spacing: 10) {
                                            if isTranslated {
                                                Text(String(beytNumber) + ".")
                                                    .font(.custom("Palatino-Roman", size: 12))
                                                    .foregroundColor(.black)
                                                    .lineSpacing(14 * 2.66)
                                                    .kerning(1)
                                                    .frame(width: 20, alignment: .leading)
                                            } else {
                                                Spacer()
                                            }
                                            
                                            Text(beyt[0])
                                                .font(isTranslated ? .custom("Palatino-Roman", size: 14) : .system(size: 14))
                                                .foregroundColor(.black)
                                                .lineSpacing(14 * 2.66)
                                                .kerning(1)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .multilineTextAlignment(isTranslated ? .leading : .trailing)
                                                .environment(\.layoutDirection, isTranslated ? .leftToRight : .rightToLeft)
                                            
                                            if !isTranslated {
                                                Text("." + toFarsiNumber(beytNumber))
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.black)
                                                    .lineSpacing(14 * 2.66)
                                                    .kerning(1)
                                                    .frame(width: 20, alignment: .trailing)
                                            } else {
                                                Spacer()
                                            }
                                        }
                                    }
                                    
                                    // Second line of beyt (no number)
                                    if beyt.count > 1 {
                                        HStack(alignment: .top, spacing: 10) {
                                            if isTranslated {
                                                Text("")
                                                    .font(.system(size: 12))
                                                    .frame(width: 20)
                                            } else {
                                                Spacer()
                                            }
                                            
                                            Text(beyt[1])
                                                .font(isTranslated ? .custom("Palatino-Roman", size: 14) : .system(size: 14))
                                                .foregroundColor(.black)
                                                .lineSpacing(14 * 2.66)
                                                .kerning(1)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .multilineTextAlignment(isTranslated ? .leading : .trailing)
                                                .environment(\.layoutDirection, isTranslated ? .leftToRight : .rightToLeft)
                                            
                                            if !isTranslated {
                                                Text("")
                                                    .font(.system(size: 12))
                                                    .frame(width: 20)
                                            } else {
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding(.bottom, beytIndex < endBeytIndex - 1 ? 8 : 0)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.white)
                }
                .id(poem.id)
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
            }
            
            // Page control with bottom corners rounded
            HStack(spacing: 8) {
                let beytsPerPage = 2
                let totalPages = (poem.verses.count + beytsPerPage - 1) / beytsPerPage
                ForEach(0..<totalPages, id: \.self) { pageIndex in
                    Circle()
                        .fill(pageIndex == versePage ? Color.black : Color.black.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            
            // Explanation button
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 15, weight: .regular))
                    Text("Explanation")
                        .font(.system(size: 15, weight: .regular))
                        .tracking(-0.23)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.black)
                .cornerRadius(1000)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .background(Color(red: 244/255, green: 244/255, blue: 244/255))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    ProfileView()
}
