import SwiftUI

struct PlayBackView: View {
    let onTap: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let currentTrack: String
    let currentArtist: String
    let currentArtwork: URL?
    let isPlaying: Bool
    let isLoading: Bool // Add loading state parameter
    
    var body: some View {
        if isLoading {
            MiniPlayerSkeletonView(
                onPlayPause: onPlayPause,
                onNext: onNext,
                isPlaying: isPlaying
            )
        } else {
        HStack(spacing: 12) {
            CachedAsyncImage(url: currentArtwork) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "music.note")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 32, height: 32)
            .cornerRadius(8)
            .clipped()
            
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
            
            HStack(spacing: 8) {
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        }
    }
}

// MARK: - Mini Player Skeleton
struct MiniPlayerSkeletonView: View {
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let isPlaying: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Album artwork skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(skeletonColor)
                .frame(width: 32, height: 32)
            
            // Track info skeleton
            VStack(alignment: .leading, spacing: 2) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(width: 100, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(skeletonColor)
                    .frame(width: 60, height: 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Real control buttons (not skeleton)
            HStack(spacing: 8) {
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(in: RoundedRectangle(cornerRadius: 8))
    }
    
    private var skeletonColor: Color {
        isDarkMode ?
            Color(red: 0.3, green: 0.3, blue: 0.3) :
            Color(red: 0.85, green: 0.85, blue: 0.85)
    }
}
