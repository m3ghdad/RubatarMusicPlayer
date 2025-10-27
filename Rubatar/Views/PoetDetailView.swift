//
//  PoetDetailView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/27/25.
//

import SwiftUI

struct PoetDetailView: View {
    let poetName: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background matching app theme
            (colorScheme == .dark ? Color.black : Color(red: 244/255, green: 244/255, blue: 244/255))
                .ignoresSafeArea()
            
            Text("")
        }
        .navigationTitle(poetName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // Custom back button with glass effect
                BackButtonView()
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                // Action buttons with glass effect
                HStack(spacing: 8) {
                    Button(action: {
                        // Share action
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                    }
                    
                    Button(action: {
                        // More options action
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                    }
                }
                .glassEffect(in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Back Button with Glass Effect
struct BackButtonView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
        }
        .glassEffect(in: Circle())
    }
}

#Preview {
    NavigationStack {
        PoetDetailView(poetName: "حافظ")
    }
}



