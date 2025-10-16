//
//  ProfileView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var showProfileSheet = false
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0
    
    var body: some View {
        ZStack {
            getBackgroundColors()[selectedBackgroundColor].gradient
                .ignoresSafeArea()
            
            NavigationView {
                VStack(spacing: 20) {
                    HStack {
                        Text("Rubatar")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        AvatarButtonView(action: {
                            showProfileSheet = true
                        })
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "apple.books.pages.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        Text("Rubatar")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Your music player")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.top, 20)
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