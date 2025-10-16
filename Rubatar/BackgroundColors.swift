import SwiftUI

// MARK: - Background Colors Helper
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
