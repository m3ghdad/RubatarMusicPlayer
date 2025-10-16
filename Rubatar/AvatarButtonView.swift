import SwiftUI

struct AvatarButtonView: View {
    var body: some View {
        Button(action: {
            // TODO: Handle avatar tap (e.g., navigate to profile)
        }) {
            AsyncImage(url: URL(string: "https://i.ibb.co/TDWzY83h/IMG-3079.jpgformat&fit=crop")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_):
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                        .foregroundColor(.secondary)
                        .background(Color.secondary.opacity(0.15))
                case .empty:
                    ZStack {
                        Color.secondary.opacity(0.1)
                        ProgressView()
                    }
                @unknown default:
                    Color.secondary.opacity(0.1)
                }
            }
            .frame(width: 34, height: 34)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
            .accessibilityLabel("Profile")
        }
        .buttonStyle(.plain)
    }
}
