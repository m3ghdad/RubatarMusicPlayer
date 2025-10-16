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
    @State private var currentPage = 0
    
    // Sample poem data
    private let poemTitle = "Quatrain No. 127"
    private let poetName = "Khayam"
    
    // Array of poems as couplets (two sections each)
    private let poems: [([String], [String])] = [
        (
            ["Let not your heart linger on the day that is gone",
             "Nor raise a cry for the morrow not yet born"],
            ["Build no foundations on what has fled or what has not arrived",
             "Dwell in this moment, and do not cast your life to the wind."]
        ),
        (
            ["The secrets which my book of love has bred,",
             "Cannot be told for fear of loss of head;"],
            ["Since none is fit to learn, or cares to know,",
             "'Tis likely then, with me, the truth will go."]
        ),
        (
            ["Ah, fill the Cup: what boots it to repeat",
             "How Time is slipping underneath our Feet:"],
            ["Unborn To-morrow, and dead Yesterday,",
             "Why fret about them if To-day be sweet!"]
        ),
        (
            ["Come, fill the Cup, and in the Fire of Spring",
             "The Winter Garment of Repentance fling:"],
            ["The Bird of Time has but a little way",
             "To fly—and Lo! the Bird is on the Wing."]
        )
    ]
    
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
                    ZStack(alignment: .center) {
                        // Main container background (no border radius)
                        Rectangle()
                            .fill(Color(red: 244/255, green: 244/255, blue: 244/255))
                        
                        VStack(spacing: 24) {
                            // Poem card container
                            ZStack {
                                // Card background - white with subtle shadow
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                            
                                VStack(spacing: 0) {
                                    // Poem title, poet name, and action buttons (all in one row)
                                    HStack(alignment: .top, spacing: 0) {
                                        // Left side: Title and poet
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(poemTitle)
                                                .font(.custom("Palatino-Roman", size: 24))
                                                .foregroundColor(Color(red: 60/255, green: 60/255, blue: 67/255, opacity: 0.6))
                                                .kerning(-0.43)
                                                .lineSpacing(22)
                                            
                                            Text(poetName)
                                                .font(.custom("Palatino-Roman", size: 16))
                                                .foregroundColor(Color(red: 122/255, green: 92/255, blue: 57/255))
                                                .kerning(-0.23)
                                                .lineSpacing(20)
                                        }
                                        
                                        Spacer()
                                        
                                        // Right side: Action buttons (28x28)
                                        HStack(spacing: 8) {
                                            // Book button
                                            Button(action: {}) {
                                                Image(systemName: "book.closed")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(.primary)
                                                    .frame(width: 28, height: 28)
                                            }
                                            .buttonStyle(.plain)
                                            
                                            // Heart button
                                            Button(action: {}) {
                                                Image(systemName: "heart")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(.primary)
                                                    .frame(width: 28, height: 28)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.bottom, 4)
                                    
                                    // Separator line under header (dashed)
                                    DashedLine(dashCount: 12)
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                        .frame(height: 1)
                                    
                                    // Swipeable poem carousel with numbered verses
                                    TabView(selection: $currentPage) {
                                        ForEach(0..<poems.count, id: \.self) { index in
                                            VStack(spacing: 2) {
                                                // First verse (numbered - continues from previous page)
                                                HStack(alignment: .top, spacing: 10) {
                                                    Text("\(index * 2 + 1).")
                                                        .font(.custom("Palatino-Roman", size: 12))
                                                        .foregroundColor(.black)
                                                        .lineSpacing(14 * 1.66) // 2.66 line height = 14px * 1.66 extra spacing
                                                        .kerning(1)
                                                    
                                                    VStack(alignment: .leading, spacing: 10) {
                                                        ForEach(poems[index].0, id: \.self) { line in
                                                            Text(line)
                                                                .font(.custom("Palatino-Roman", size: 14))
                                                                .foregroundColor(.black)
                                                                .lineSpacing(14 * 1.66) // 2.66 line height = 14px * 1.66 extra spacing
                                                                .kerning(1)
                                                                .lineLimit(nil)
                                                                .fixedSize(horizontal: false, vertical: true)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                        }
                                                    }
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 24)
                                                            .fill(Color(red: 244/255, green: 244/255, blue: 244/255, opacity: 0.2))
                                                    )
                                                }
                                                
                                                // Separator line (dashed) with padding
                                                VStack(spacing: 0) {
                                                    DashedLine(dashCount: 12)
                                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                                        .frame(height: 1)
                                                }
                                                .padding(.vertical, 12)
                                                
                                                // Second verse (numbered - continues from previous page)
                                                HStack(alignment: .top, spacing: 10) {
                                                    Text("\(index * 2 + 2).")
                                                        .font(.custom("Palatino-Roman", size: 12))
                                                        .foregroundColor(.black)
                                                        .lineSpacing(14 * 1.66) // 2.66 line height = 14px * 1.66 extra spacing
                                                        .kerning(1)
                                                    
                                                    VStack(alignment: .leading, spacing: 10) {
                                                        ForEach(poems[index].1, id: \.self) { line in
                                                            Text(line)
                                                                .font(.custom("Palatino-Roman", size: 14))
                                                                .foregroundColor(.black)
                                                                .lineSpacing(14 * 1.66) // 2.66 line height = 14px * 1.66 extra spacing
                                                                .kerning(1)
                                                                .lineLimit(nil)
                                                                .fixedSize(horizontal: false, vertical: true)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                        }
                                                    }
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 24)
                                                            .fill(Color(red: 244/255, green: 244/255, blue: 244/255, opacity: 0.2))
                                                    )
                                                }
                                            }
                                            .padding(.vertical, 16)
                                            .tag(index)
                                        }
                                    }
                                    .tabViewStyle(.page(indexDisplayMode: .never))
                                    .frame(maxWidth: .infinity)
                                    
                                    // Page control
                                    HStack(spacing: 8) {
                                        ForEach(0..<poems.count, id: \.self) { index in
                                            Circle()
                                                .fill(index == currentPage ? Color.black : Color.black.opacity(0.3))
                                                .frame(width: 8, height: 8)
                                        }
                                    }
                                    .padding(.bottom, 8)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 48)
                                .padding(.bottom, 36)
                            }
                            .frame(height: 549)
                            .padding(.horizontal, 30)
                            
                            // Navigation buttons (previous, refresh, next)
                            HStack(spacing: 0) {
                                // Previous button (no action - swipe to navigate)
                                LiquidGlassButton(icon: "chevron.left.circle.fill", action: {})
                                
                                Spacer()
                                
                                // Refresh button
                                LiquidGlassButton(icon: "arrow.clockwise", action: {})
                                
                                Spacer()
                                
                                // Next button (no action - swipe to navigate)
                                LiquidGlassButton(icon: "chevron.right.circle.fill", action: {})
                            }
                            .padding(.horizontal, 30)
                        }
                    }
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
    }
}

#Preview {
    ProfileView()
}

