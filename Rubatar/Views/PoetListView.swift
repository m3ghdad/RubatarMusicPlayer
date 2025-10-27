//
//  PoetListView.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/27/25.
//

import SwiftUI

struct PoetListView: View {
    @StateObject private var poetService = PoetService()
    @AppStorage("selectedLanguage") private var selectedLanguageRaw = AppLanguage.english.rawValue
    @Environment(\.colorScheme) var colorScheme
    
    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: selectedLanguageRaw) ?? .english
    }
    
    var sortedPoets: [SupabasePoetDetail] {
        if selectedLanguage == .farsi {
            return poetService.poets.sorted { $0.displayNameFa < $1.displayNameFa }
        } else {
            return poetService.poets.sorted { $0.displayNameEn < $1.displayNameEn }
        }
    }

    var body: some View {
        ZStack {
            // Dynamic background that adapts to light/dark mode
            (colorScheme == .dark ? Color.black : Color(red: 244/255, green: 244/255, blue: 244/255))
                .ignoresSafeArea(.all)
            
            if poetService.isLoading {
                ProgressView("Loading poets...")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            } else if poetService.poets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.text.rectangle")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("No poets found")
                        .font(.custom("Palatino", size: 20))
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(sortedPoets) { poet in
                        NavigationLink(value: ContentView.PoetRoute(name: selectedLanguage == .farsi ? poet.displayNameFa : poet.displayNameEn)) {
                            HStack(spacing: 16) {
                                if selectedLanguage == .farsi {
                                    // Farsi: Right-to-left layout - text first, then avatar
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(poet.displayNameFa)
                                            .font(.custom("Palatino", size: 17))
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        
                                        Text("شاعر")
                                            .font(.custom("Palatino", size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    
                                    // Avatar placeholder
                                    Circle()
                                        .fill(colorScheme == .dark ? Color(hex: "E3B887").opacity(0.2) : Color(hex: "7A5C39").opacity(0.1))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(String(poet.displayNameFa.prefix(1)))
                                                .font(.custom("Palatino", size: 20))
                                                .fontWeight(.semibold)
                                                .foregroundColor(colorScheme == .dark ? Color(hex: "E3B887") : Color(hex: "7A5C39"))
                                        )
                                } else {
                                    // English: Left-to-right layout - avatar first, then text
                                    Circle()
                                        .fill(colorScheme == .dark ? Color(hex: "E3B887").opacity(0.2) : Color(hex: "7A5C39").opacity(0.1))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(String(poet.displayNameEn.prefix(1)))
                                                .font(.custom("Palatino", size: 20))
                                                .fontWeight(.semibold)
                                                .foregroundColor(colorScheme == .dark ? Color(hex: "E3B887") : Color(hex: "7A5C39"))
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(poet.displayNameEn)
                                            .font(.custom("Palatino", size: 17))
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        
                                        Text("Poet")
                                            .font(.custom("Palatino", size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Poets")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: ContentView.PoetRoute.self) { route in
            PoetDetailView(poetName: route.name)
        }
        .onAppear {
            if poetService.poets.isEmpty {
                Task {
                    await poetService.fetchPoets()
                }
            }
        }
    }
}
