import SwiftUI

struct PlayBackView: View {
    let onTap: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let currentTrack: String
    let currentArtist: String
    let currentArtwork: URL?
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: currentArtwork) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            .frame(width: 32, height: 32)
            .cornerRadius(8)
            .clipped()
            .onTapGesture { onTap() }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(currentTrack)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(currentArtist)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture { onTap() }
            
            HStack(spacing: 8) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .highPriorityGesture(TapGesture().onEnded { onPlayPause() })
                
                Image(systemName: "forward.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .highPriorityGesture(TapGesture().onEnded { onNext() })
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.separator, lineWidth: 0.5)
                )
        )
    }
}
