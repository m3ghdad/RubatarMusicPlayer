//
//  PoetService.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/27/25.
//

import Foundation
import Combine

// MARK: - Supabase Poet Model
struct SupabasePoetDetail: Codable, Identifiable, Hashable {
    let id: String
    let name_fa: String
    let name_en: String?
    let nickname_fa: String?
    let nickname_en: String?
    let era: String?
    let birthdate: String?
    let passingdate: String?
    
    var displayNameFa: String {
        nickname_fa ?? name_fa
    }
    
    var displayNameEn: String {
        nickname_en ?? name_en ?? name_fa
    }
}

// MARK: - Poet Service
class PoetService: ObservableObject {
    @Published var poets: [SupabasePoetDetail] = []
    @Published var isLoading = false
    
    private let baseURL = Config.supabaseURL
    private let apiKey = Config.supabaseAnonKey
    
    // Fetch all poets from Supabase
    func fetchPoets() async {
        await MainActor.run { isLoading = true }
        
        do {
            let url = "\(baseURL)/rest/v1/poets?select=id,name_fa,name_en,nickname_fa,nickname_en,era,birthdate,passingdate&order=name_fa.asc"
            
            guard let requestURL = URL(string: url) else {
                print("❌ Invalid URL")
                await MainActor.run { isLoading = false }
                return
            }
            
            var request = URLRequest(url: requestURL)
            request.setValue(apiKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response")
                await MainActor.run { isLoading = false }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Error response: \(errorString)")
                }
                await MainActor.run { isLoading = false }
                return
            }
            
            let decoder = JSONDecoder()
            let fetchedPoets = try decoder.decode([SupabasePoetDetail].self, from: data)
            
            await MainActor.run {
                self.poets = fetchedPoets
                self.isLoading = false
                print("✅ Fetched \(fetchedPoets.count) poets")
            }
            
        } catch {
            print("❌ PoetService Error: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

