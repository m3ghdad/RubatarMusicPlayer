//
//  BackgroundColorManager.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import SwiftUI
import Combine

// MARK: - Shared Background Color Manager
class BackgroundColorManager: ObservableObject {
    @Published var selectedColor: Int = 0 // Default to Ocean
    
    static let shared = BackgroundColorManager()
    
    private init() {}
    
    func getBackgroundColors() -> [(name: String, gradient: LinearGradient)] {
        return [
            ("Ocean", LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue,
                    Color.cyan,
                    Color.teal
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )),
            ("Sunset", LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange,
                    Color.pink,
                    Color.purple
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )),
            ("Forest", LinearGradient(
                gradient: Gradient(colors: [
                    Color.green,
                    Color.mint,
                    Color.blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )),
            ("Lavender", LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple,
                    Color.indigo,
                    Color.blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )),
            ("Classic", LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.blue,
                    Color.purple
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        ]
    }
}
