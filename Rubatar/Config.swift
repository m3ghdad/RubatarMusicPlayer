//
//  Config.swift
//  Rubatar
//
//  Configuration file for API keys and settings
//
//  Created by Meghdad Abbaszadegan on 10/17/25.
//

import Foundation

struct Config {
    // MARK: - OpenAI Configuration
    // OpenAI API Key for poem translation
    // IMPORTANT: Replace with your actual key or use Xcode Cloud environment variables
    static let openAIAPIKey = "YOUR_OPENAI_API_KEY_HERE"
    
    // Translation settings
    static let translationModel = "gpt-4o-mini"
    static let translationTemperature = 0.7
    static let translationMaxTokens = 1000
    
    // MARK: - Supabase Configuration
    // These keys are safe to commit (client-side public keys)
    static let supabaseURL = "https://pspybykovwrfdxpkjpzd.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzcHlieWtvdndyZmR4cGtqcHpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk1NDIyMDksImV4cCI6MjA3NTExODIwOX0.NV3irlmKEDcThTGYnHOLy4LRA5qjAxUC4XhkKf4QpKA"
}

