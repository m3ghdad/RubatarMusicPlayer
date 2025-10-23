//
//  ProfileBottomSheet.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import SwiftUI

struct ProfileBottomSheet: View {
    @Binding var isPresented: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header with Close Button
                HStack {
                    // Liquid Glass Close Button (48x48)
                    Button(action: {
                        isPresented = false
                    }) {
                        ZStack {
                            Circle()
                                .fill(.clear)
                                .frame(width: 48, height: 48)
                                .glassEffect(in: Circle())
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Profile Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Appearance Toggle
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "paintbrush.fill")
                                    .foregroundStyle(isDarkMode ? Color(hex: "E3B887") : Color(hex: "7A5C39"))
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Appearance")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Text(isDarkMode ? "Switch to light mode" : "Switch to dark mode")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $isDarkMode)
                                    .toggleStyle(SwitchToggleStyle(tint: isDarkMode ? Color(hex: "E3B887") : Color(hex: "7A5C39")))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
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
                        
                        // Settings Rows - Commented out
                        /*
                        VStack(spacing: 12) {
                            SettingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Manage your alerts")
                            SettingsRow(icon: "lock.fill", title: "Privacy", subtitle: "Control your data")
                            SettingsRow(icon: "gear", title: "General", subtitle: "App preferences")
                        }
                        .padding(.horizontal, 20)
                        */
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

#Preview {
    ProfileBottomSheet(isPresented: .constant(true))
}
