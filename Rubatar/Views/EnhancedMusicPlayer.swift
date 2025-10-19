import SwiftUI
import AVFoundation
import MediaPlayer
import MusicKit
import Combine

struct EnhancedMusicPlayer: View {
    @Binding var show: Bool
    @Binding var hideMiniPlayer: Bool
    var animation: Namespace.ID
    
    // Pass the existing audio player from ContentView
    @EnvironmentObject var audioPlayer: AudioPlayer
    
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("LastPlaybackPositions") private var lastPlaybackPositionsData: Data = Data()
    @AppStorage("WasPlayingOnBackground") private var wasPlayingOnBackground: Bool = false
    
    // View Properties
    @State private var expandPlayer: Bool = true
    @State private var offsetY: CGFloat = 0
    @State private var gradient: AnyGradient = Color.clear.gradient
    
    // Animation Properties
    @State private var animationProgress: CGFloat = 0
    @State private var isAnimating: Bool = false
    
    // Player Controls State
    @State private var currentTime: Double = 0.0
    @State private var totalTime: Double = 240.0 // 4 minutes example
    @State private var volume: Double = 0.7
    @State private var isSeekingTime: Bool = false
    @State private var isAdjustingVolume: Bool = false
    @State private var volumeObserver: NSObjectProtocol?
    @State private var volumeTimer: Timer?
    @State private var lastKnownVolume: Float = 0.0
    @State private var isRestoringPlaybackPosition: Bool = false
    @State private var shouldRestoreOnReturn: Bool = false
    
    private var lastPlaybackPositions: [String: Double] {
        get {
            guard let dict = try? JSONDecoder().decode([String: Double].self, from: lastPlaybackPositionsData) else { return [:] }
            return dict
        }
        set {
            lastPlaybackPositionsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    private func trackKey() -> String? {
        // Use the MusicKit Song id if available, otherwise fall back to track name+artist
        let player = ApplicationMusicPlayer.shared
        if let entry = player.queue.currentEntry, let song = entry.item as? Song {
            if let id = song.id.rawValue as String? { return id }
        }
        let title = audioPlayer.currentTrack
        let artist = audioPlayer.currentArtist
        guard !title.isEmpty || !artist.isEmpty else { return nil }
        return "\(title)|\(artist)"
    }
    
    private func getCurrentPlaybackPosition() -> Double {
        let player = ApplicationMusicPlayer.shared
        let actualTime = player.playbackTime
        
        // If we have actual playback time or we're playing, use it
        if actualTime > 0 || audioPlayer.isPlaying {
            return actualTime
        }
        
        // If paused and no playback time, show saved position
        let savedTime = UserDefaults.standard.double(forKey: "ap_lastPlaybackTime")
        let backupTime = UserDefaults.standard.double(forKey: "ap_lastValidPlaybackTime")
        let pendingTime = UserDefaults.standard.double(forKey: "ap_pendingSeekTime")
        
        if pendingTime > 0 {
            return pendingTime
        } else if savedTime > 0 {
            return savedTime
        } else if backupTime > 0 {
            return backupTime
        }
        
        return actualTime
    }
    
    private func saveCurrentPlaybackPosition() {
        guard let key = trackKey() else { return }

        // Read existing positions directly from UserDefaults
        let defaults = UserDefaults.standard
        let data = defaults.data(forKey: "LastPlaybackPositions") ?? Data()
        var dict = (try? JSONDecoder().decode([String: Double].self, from: data)) ?? [:]

        // Current live time from MusicKit
        let liveTime = ApplicationMusicPlayer.shared.playbackTime

        // Avoid saving clearly invalid/zero values
        guard liveTime > 0 else {
            // Keep the previous saved time if any
            return
        }

        // Only overwrite if we’re moving forward significantly to avoid regressions
        let previous = dict[key] ?? 0
        if liveTime >= previous + 0.25 {
            dict[key] = liveTime
            if let newData = try? JSONEncoder().encode(dict) {
                defaults.set(newData, forKey: "LastPlaybackPositions")
            }
        }
    }
    
    private func restorePlaybackPositionIfAvailable() {
        guard let key = trackKey() else { return }
        // Read positions directly from UserDefaults to avoid mutating self
        let defaults = UserDefaults.standard
        let data = defaults.data(forKey: "LastPlaybackPositions") ?? Data()
        let dict = (try? JSONDecoder().decode([String: Double].self, from: data)) ?? [:]
        guard let t = dict[key], t > 0 else { return }

        // Update UI immediately
        self.currentTime = t

        // Seek directly on ApplicationMusicPlayer to avoid wrapper-induced resets
        let player = ApplicationMusicPlayer.shared
        player.playbackTime = t

        // Retry a couple of times to outlast any late resets from the player
        let retries = [0.05, 0.15, 0.30]
        for delay in retries {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                ApplicationMusicPlayer.shared.playbackTime = t
            }
        }
    }
    
    // Timer publisher for updating playback progress
    private let _timeTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    // Bottom Tab Selection
    @State private var selectedBottomTab: BottomTab = .booklet
    
    // Segmented Control Selection
    @State private var selectedSegment: SegmentTab = .listeningGuide
    
    
    enum BottomTab: String, CaseIterable {
        case booklet = "Booklet"
        case airplay = "AirPlay"
        case list = "List"
        
        var iconName: String {
            switch self {
            case .booklet: return "book.fill"
            case .airplay: return "airplayvideo"
            case .list: return "list.bullet"
            }
        }
    }
    
    enum SegmentTab: String, CaseIterable {
        case listeningGuide = "Listening Guide"
        case credits = "Credits"
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let safeArea = geometry.safeAreaInsets
            
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Spacer(minLength: safeArea.top + 16)
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                        Rectangle()
                            .fill(gradient)
                    }
                    .clipShape(.rect(cornerRadius: 24))
                    .overlay(
                        ExpandedPlayer(size, safeArea)
                            .clipShape(.rect(cornerRadius: 24))
                    )
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .offset(y: offsetY)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let translation = max(value.translation.height, 0)
                        offsetY = translation
                    }
                    .onEnded { value in
                        let translation = max(value.translation.height, 0)
                        let velocity = value.velocity.height / 5
                        
                        withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                            if (translation + velocity) > (size.height * 0.5) {
                                // Closing View - dismiss fullScreenCover
                                show = false
                            }
                            offsetY = 0
                        }
                    }
            )
        }
        .ignoresSafeArea(.all)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background, .inactive:
                // Save current position and mark that we should restore on next activation
                saveCurrentPlaybackPosition()
                wasPlayingOnBackground = audioPlayer.isPlaying
                shouldRestoreOnReturn = true
            case .active:
                // Only restore when returning to the app, once
                guard shouldRestoreOnReturn else { return }
                shouldRestoreOnReturn = false
                isRestoringPlaybackPosition = true
                // Defer slightly to allow the player to settle, then restore
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    // Ensure we have a current entry before restoring
                    let player = ApplicationMusicPlayer.shared
                    guard player.queue.currentEntry != nil else {
                        // Try again a bit later if not ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            restorePlaybackPositionIfAvailable()
                            // Reinforce once
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                // Optionally resume playback if it was playing before background
                                if wasPlayingOnBackground {
                                    Task { try? await ApplicationMusicPlayer.shared.play() }
                                }
                                isRestoringPlaybackPosition = false
                            }
                        }
                        return
                    }

                    restorePlaybackPositionIfAvailable()
                    // Reinforce once
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Optionally resume playback if it was playing before background
                        if wasPlayingOnBackground {
                            Task { try? await ApplicationMusicPlayer.shared.play() }
                        }
                        isRestoringPlaybackPosition = false
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    
    // MARK: - Expanded Player
    @ViewBuilder
    func ExpandedPlayer(_ size: CGSize, _ safeArea: EdgeInsets) -> some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(.white.secondary)
                .frame(width: 35, height: 5)
                .padding(.top, 12)
            
            // Header with Album Art and Info
            HStack(spacing: 12) {
                AsyncImage(url: audioPlayer.currentArtwork) { image in
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
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(.rect(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(audioPlayer.currentTrack != "No track selected" ? audioPlayer.currentTrack : "Calm Down")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(audioPlayer.currentArtist.isEmpty ? "Rema, Selena Gomez" : audioPlayer.currentArtist)
                        .font(.caption2)
                        .foregroundStyle(.white.secondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
                
                HStack(spacing: 0) {
                    Button("", systemImage: "heart.circle.fill") {
                        // Favorite action
                    }
                    
                    Button("", systemImage: "ellipsis.circle.fill") {
                        // More options
                    }
                }
                .foregroundStyle(.white, .white.tertiary)
                .font(.title2)
            }
            .padding(.top, 8)
            
            // Conditional Segmented Control - Only show for booklet
            if selectedBottomTab == .booklet {
                Picker("Content", selection: $selectedSegment) {
                    ForEach(SegmentTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            // Content Area
            ScrollView {
                VStack {
                    switch selectedBottomTab {
                    case .booklet:
                        BookletContent(selectedSegment: selectedSegment)
                    case .airplay:
                        AirPlayContent()
                    case .list:
                        ListContent()
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
            
            // Progress Bar
            VStack(spacing: 8) {
                Slider(value: $currentTime, in: 0...totalTime) { isEditing in
                    isSeekingTime = isEditing
                    if !isEditing {
                        // Seek directly on MusicKit player so timer reflects immediately
                        let player = ApplicationMusicPlayer.shared
                        player.playbackTime = currentTime
                        // Reinforce on next runloop to avoid quick resets
                        DispatchQueue.main.async {
                            ApplicationMusicPlayer.shared.playbackTime = currentTime
                        }
                        // Mirror to your audioPlayer for non-MusicKit sources
                        audioPlayer.seekTo(currentTime)
                        saveCurrentPlaybackPosition()
                    }
                }
                .tint(.white)
                
                HStack {
                    Text(timeString(currentTime))
                        .font(.caption2)
                        .foregroundStyle(.white.secondary)
                    
                    Spacer()
                    
                    Text("-\(timeString(totalTime - currentTime))")
                        .font(.caption2)
                        .foregroundStyle(.white.secondary)
                }
            }
            .onReceive(_timeTimer) { _ in
                // Update slider even when paused, but don't fight user while dragging
                guard !isSeekingTime, !isRestoringPlaybackPosition else { return }
                
                // Always use actual player time for timer updates
                self.currentTime = getCurrentPlaybackPosition()
                
                // Try updating totalTime from current song if available
                let player = ApplicationMusicPlayer.shared
                if let entry = player.queue.currentEntry, let song = entry.item as? Song, let duration = song.duration {
                    self.totalTime = duration
                }
            }
            .onAppear {
                let player = ApplicationMusicPlayer.shared
                self.currentTime = getCurrentPlaybackPosition()
                if let entry = player.queue.currentEntry, let song = entry.item as? Song, let duration = song.duration {
                    self.totalTime = duration
                }
                
                // Initialize volume and set up observation
                self.initializeSystemVolume()
                self.setupVolumeObservation()
            }
            .onChange(of: audioPlayer.currentTrack) { _, _ in
                let player = ApplicationMusicPlayer.shared
                if let entry = player.queue.currentEntry, let song = entry.item as? Song, let duration = song.duration {
                    self.totalTime = duration
                }
                self.currentTime = getCurrentPlaybackPosition()
            }
            .onDisappear {
                // Clean up volume observer and timer
                if let observer = self.volumeObserver {
                    NotificationCenter.default.removeObserver(observer)
                    self.volumeObserver = nil
                }
                self.stopVolumeMonitoring()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
            
            // Playback Controls with Glass Container
            GlassEffectContainer(spacing: 40.0) {
                HStack(spacing: 40) {
                    Button(action: {
                        audioPlayer.playPreviousTrack()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    .frame(width: 54, height: 54)
                    .background(.clear)
                    .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .circle)
                    
                    Button(action: {
                        audioPlayer.togglePlayPause()
                        if !audioPlayer.isPlaying { saveCurrentPlaybackPosition() }
                    }) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 80, height: 80)
                    .background(.clear)
                    .glassEffect(.regular.tint(.white.opacity(0.15)).interactive(), in: .circle)
                    
                    Button(action: {
                        audioPlayer.playNextTrack()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    .frame(width: 54, height: 54)
                    .background(.clear)
                    .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .circle)
                }
            }
            .padding(.bottom, 15)
            
            // Volume Control - Enhanced implementation
            VStack(spacing: 8) {
                HStack(spacing: 15) {
                    Button(action: {
                        // Mute/unmute functionality
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if volume > 0 {
                                volume = 0
                            } else {
                                volume = 0.7 // Default volume
                            }
                            setSystemVolume(Float(volume))
                        }
                    }) {
                        Image(systemName: volume <= 0 ? "speaker.slash.fill" : (volume < 0.3 ? "speaker.fill" : (volume < 0.7 ? "speaker.wave.1.fill" : "speaker.wave.3.fill")))
                            .foregroundStyle(.white.secondary)
                            .font(.caption)
                    }
                    
                    Slider(value: $volume, in: 0...1, onEditingChanged: { isEditing in
                        isAdjustingVolume = isEditing
                        // Always update system volume during dragging
                        setSystemVolume(Float(volume))
                        if !isEditing {
                            print("🔊 Final volume set to: \(volume)")
                        }
                    })
                    .tint(.white)
                    .onChange(of: volume) { oldValue, newValue in
                        // Update system volume whenever slider changes
                        if isAdjustingVolume {
                            setSystemVolume(Float(newValue))
                        }
                    }
                    
                    Button(action: {
                        // Quick volume boost with haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.easeInOut(duration: 0.2)) {
                            volume = min(volume + 0.2, 1.0)
                            setSystemVolume(Float(volume))
                        }
                    }) {
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(.white.secondary)
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
            
            // Bottom Tab Buttons - Enhanced Liquid Glass
            HStack(spacing: 0) {
                ForEach(BottomTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedBottomTab = tab
                    }) {
                        Image(systemName: tab.iconName)
                            .font(.title2)
                            .foregroundStyle(selectedBottomTab == tab ? .white : .gray)
                            .frame(width: 50, height: 50)
                    }
                    .frame(maxWidth: .infinity)
                    .glassEffect(.regular.tint(selectedBottomTab == tab ? .white.opacity(0.15) : .white.opacity(0.05)).interactive(), in: .circle)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, safeArea.bottom + 10)
        }
        .padding(15)
        .padding(.top, safeArea.top + 12)
    }
    
    // MARK: - Content Views
    @ViewBuilder
    func BookletContent(selectedSegment: SegmentTab) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            if selectedSegment == .listeningGuide {
                Text("Album Booklet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("COMPOSER")
                        .font(.caption)
                        .foregroundStyle(.white.secondary)
                    
                    Text("Rema, Selena Gomez")
                        .foregroundStyle(.white)
                    
                    Text("WORK")
                        .font(.caption)
                        .foregroundStyle(.white.secondary)
                        .padding(.top, 8)
                    
                    Text("Calm Down")
                        .foregroundStyle(.white)
                    
                    Text("CATALOG NUMBER")
                        .font(.caption)
                        .foregroundStyle(.white.secondary)
                        .padding(.top, 8)
                    
                    Text("MAVIN001")
                        .foregroundStyle(.white)
                }
            } else {
                Text("Credits")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("PERFORMERS")
                        .font(.caption)
                        .foregroundStyle(.white.secondary)
                    
                    Text("Rema - Vocals, Writer")
                        .foregroundStyle(.white)
                    
                    Text("Selena Gomez - Featured Artist, Vocals")
                        .foregroundStyle(.white)
                    
                    Text("PRODUCTION")
                        .font(.caption)
                        .foregroundStyle(.white.secondary)
                        .padding(.top, 8)
                    
                    Text("Kel-P - Producer")
                        .foregroundStyle(.white)
                    
                    Text("Mixed by - John Doe")
                        .foregroundStyle(.white)
                    
                    Text("Mastered by - Jane Smith")
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func AirPlayContent() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "airplayvideo")
                .font(.system(size: 60))
                .foregroundStyle(.white.secondary)
            
            Text("AirPlay")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            Text("Select speakers or displays to play audio and video")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.secondary)
            
            Button("Choose AirPlay Device") {
                // AirPlay selection
            }
            .buttonStyle(.glass)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    func ListContent() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Queue")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            VStack(spacing: 12) {
                ForEach(0..<5) { index in
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(.rect(cornerRadius: 6))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Track \(index + 1)")
                                .foregroundStyle(.white)
                            Text("Artist Name")
                                .font(.caption)
                                .foregroundStyle(.white.secondary)
                        }
                        
                        Spacer()
                        
                        Text("3:42")
                            .font(.caption)
                            .foregroundStyle(.white.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    if index < 4 {
                        Divider()
                            .background(.white.opacity(0.2))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helper Functions
    func loadArtworkGradient(from url: URL) {
        // Fetch image data asynchronously to avoid blocking the main thread
        Task.detached(priority: .utility) {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    await MainActor.run { self.gradient = Color.clear.gradient }
                    return
                }
                guard let avgColor = await self.computeAverageColor(from: data) else {
                    await MainActor.run { self.gradient = Color.clear.gradient }
                    return
                }
                await MainActor.run {
                    self.gradient = Color(avgColor).gradient
                }
            } catch {
                // On failure, fall back to clear gradient
                await MainActor.run { self.gradient = Color.clear.gradient }
            }
        }
    }
    
    /// Computes the average color for the given image data using Core Image, safe to call off the main actor.
    private func computeAverageColor(from data: Data) -> UIColor? {
        // Create a CIImage from data; avoid UIImage to keep this off the main actor
        guard let ciImage = CIImage(data: data) else { return nil }
        let extent = ciImage.extent
        guard !extent.isEmpty else { return nil }

        // Use CIAreaAverage to compute the mean color
        let extentVector = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: extentVector]),
              let outputImage = filter.outputImage else {
            return nil
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: nil)
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255.0,
                       green: CGFloat(bitmap[1]) / 255.0,
                       blue: CGFloat(bitmap[2]) / 255.0,
                       alpha: CGFloat(bitmap[3]) / 255.0)
    }
    
    func timeString(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Animation Helper Functions
    @inline(__always) func clamped(_ x: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat { 
        max(min(x, b), a) 
    }
    
    func dragProgress(for translation: CGFloat, height: CGFloat) -> CGFloat {
        let p = clamped(translation / height, 0, 1)
        return p * 0.1 // max window scale fraction
    }
    
    func rubberBand(_ x: CGFloat) -> CGFloat {
        // small resistance above zero
        x >= 0 ? x : 0.2 * atan(x)
    }
    
    // MARK: - System Volume Control
    func setSystemVolume(_ volume: Float) {
        // Use MPVolumeView to control system volume
        let volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 100, height: 100))
        volumeView.showsVolumeSlider = true
        
        // Add to a temporary window to make it work
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let tempWindow = UIWindow(windowScene: windowScene)
            tempWindow.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
            tempWindow.alpha = 0.01
            tempWindow.makeKeyAndVisible()
            tempWindow.addSubview(volumeView)
        
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
                    slider.value = volume
                }
                
                // Clean up
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    tempWindow.isHidden = true
                }
            }
        }
    }
    
    func getSystemVolume() -> Float {
        // Try to get system volume with proper session configuration
        let session = AVAudioSession.sharedInstance()
        
        do {
            // Configure the session before activating
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
            return session.outputVolume
        } catch {
            print("Failed to get system volume, using fallback: \(error.localizedDescription)")
            // Fallback to a reasonable default
            return 0.5
        }
    }
    
    func initializeSystemVolume() {
        let systemVolume = getSystemVolume()
        volume = Double(systemVolume)
        print("🔊 Initialized volume to: \(volume)")
    }
    
    func setupVolumeObservation() {
        // Set up AVAudioSession for volume monitoring
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            
            // Get initial volume from system
            let initialVolume = session.outputVolume
            volume = Double(initialVolume)
            lastKnownVolume = initialVolume
            print("🔊 Initial volume: \(volume)")
            
            // Start timer-based volume monitoring (more reliable on physical devices)
            startVolumeMonitoring()
            
            // Also try the notification approach as backup
            volumeObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
                object: nil,
                queue: .main
            ) { notification in
                if !self.isAdjustingVolume {
                    let currentVolume = AVAudioSession.sharedInstance().outputVolume
                    print("🔊 System volume changed via notification to: \(currentVolume)")
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.volume = Double(currentVolume)
                        self.lastKnownVolume = currentVolume
                    }
                }
            }
            
        } catch {
            print("Failed to set up volume observation: \(error.localizedDescription)")
        }
    }
    
    private func startVolumeMonitoring() {
        // Stop any existing timer
        volumeTimer?.invalidate()
        
        // Start new timer to check volume every 0.1 seconds
        volumeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if !self.isAdjustingVolume {
                let currentVolume = AVAudioSession.sharedInstance().outputVolume
                
                // Only update if volume actually changed (to avoid unnecessary animations)
                if abs(currentVolume - self.lastKnownVolume) > 0.01 {
                    print("🔊 Volume changed from \(self.lastKnownVolume) to \(currentVolume)")
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.volume = Double(currentVolume)
                        }
                    }
                    self.lastKnownVolume = currentVolume
                }
            }
        }
    }
    
    private func stopVolumeMonitoring() {
        volumeTimer?.invalidate()
        volumeTimer = nil
    }
    
}

// MARK: - Extensions
extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

struct PanGesture: UIGestureRecognizerRepresentable {
    struct Value {
        let translation: CGPoint
        let velocity: CGPoint
    }

    var onChange: (Value) -> Void
    var onEnd: (Value) -> Void

    init(_ onChange: @escaping (Value) -> Void, onEnd: @escaping (Value) -> Void) {
        self.onChange = onChange
        self.onEnd = onEnd
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        return gesture
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        // No dynamic updates needed per state; coordinator handles events.
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: PanGesture

        init(_ parent: PanGesture) {
            self.parent = parent
        }

        @objc func handlePan(_ sender: UIPanGestureRecognizer) {
            // Use the recognizer's view to compute translation and velocity in the correct coordinate space.
            let inView = sender.view
            let translation = sender.translation(in: inView)
            let velocity = sender.velocity(in: inView)
            let value = Value(translation: translation, velocity: velocity)

            switch sender.state {
            case .changed:
                parent.onChange(value)
            case .ended, .cancelled, .failed:
                parent.onEnd(value)
            default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
}

