//
//  ToastView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/17/25.
//

import SwiftUI

struct ToastView: View {
    let message: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated quill icon
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 227/255, green: 184/255, blue: 135/255))
            
            Text(message)
                .font(.custom("Palatino-Roman", size: 16))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            ZStack {
                // Liquid glass background
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: colorScheme == .dark ? [
                                        Color.white.opacity(0.05),
                                        Color.white.opacity(0.02)
                                    ] : [
                                        Color.white.opacity(0.7),
                                        Color.white.opacity(0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: colorScheme == .dark ? [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ] : [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.4)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 15, x: 0, y: 5)
            }
        )
    }
}

// Toast modifier for showing toast messages
struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                VStack {
                    Spacer()
                    ToastView(message: message)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 50)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isShowing)
            }
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message))
    }
}

