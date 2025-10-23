import SwiftUI

struct AvatarButtonView: View {
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                )
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                .accessibilityLabel("Profile")
        }
        // .buttonStyle(.plain)
        .glassEffect(in: Circle())
    }
}
