import SwiftUI
import AVFoundation
import MediaPlayer

struct EnhancedMusicPlayer: View {
    @Binding var show: Bool
    @Binding var hideMiniPlayer: Bool
    
    // Pass the existing audio player from ContentView
    @EnvironmentObject var audioPlayer: AudioPlayer
    
    // View Properties
    @State private var expandPlayer: Bool = true // Start expanded when opened from PlayBackView
    @State private var offsetY: CGFloat = 0
    @State private var mainWindow: UIWindow?
    @State private var windowProgress: CGFloat = 0
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
    
    // Bottom Tab Selection
    @State private var selectedBottomTab: BottomTab = .booklet
    
    // Segmented Control Selection
    @State private var selectedSegment: SegmentTab = .listeningGuide
    
    @Namespace private var animation
    
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
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            let cornerRadius: CGFloat = expandPlayer ? 0 : 15
            
            ZStack(alignment: .top) {
                // Background with Liquid Glass Effect
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                    
                    Rectangle()
                        .fill(gradient)
                        .opacity(expandPlayer ? 1 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(.rect(cornerRadius: cornerRadius))
                .glassEffect(.regular.tint(.blue.opacity(0.3)), 
                            in: .rect(cornerRadius: cornerRadius))
                .shadow(color: .primary.opacity(0.06), radius: 5, x: 5, y: 5)
                .shadow(color: .primary.opacity(0.05), radius: 5, x: -5, y: -5)
                
                MiniPlayer()
                    .opacity(expandPlayer ? 0 : 1)
                
                ExpandedPlayer(size, safeArea)
                    .opacity(expandPlayer ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, expandPlayer ? 0 : safeArea.bottom + 55)
            .padding(.horizontal, expandPlayer ? 0 : 15)
            .ignoresSafeArea(.all)
            .offset(y: offsetY)
            .gesture(
                PanGesture({ value in
                    guard expandPlayer && !isAnimating else { return }
                    
                    let translation = rubberBand(value.translation.y)
                    let clampedTranslation = max(translation, 0)
                    offsetY = clampedTranslation
                    
                    let progress = dragProgress(for: clampedTranslation, height: size.height)
                    windowProgress = progress
                    resizeWindow(0.1 - windowProgress)
                }, onEnd: { value in
                    guard expandPlayer && !isAnimating else { return }
                    
                    let translation = rubberBand(value.translation.y)
                    let clampedTranslation = max(translation, 0)
                    let velocity = value.velocity.y
                    
                    // Use projected position for better velocity handling
                    let projected = clampedTranslation + 0.25 * velocity
                    let shouldClose = projected > size.height * 0.45
                    
                    withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                        if shouldClose {
                            // Closing View with haptic feedback
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            expandPlayer = false
                            windowProgress = 0
                            show = false
                            resetWindowWithAnimation()
                            // Show mini player again when enhanced player is dismissed
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                // This will be handled by ContentView
                            }
                        } else {
                            // Reset Window To 0.1 With Animation
                            UIView.animate(withDuration: 0.3) {
                                resizeWindow(0.1)
                            }
                        }
                        offsetY = 0
                    }
                })
            )
            .offset(y: hideMiniPlayer && !expandPlayer ? safeArea.bottom + 200 : 0)
        }
        .onAppear {
            if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow, mainWindow == nil {
                mainWindow = window
                gradient = Color(audioPlayer.currentArtwork?.absoluteString.isEmpty == false ? .systemPurple : .systemBlue).gradient
            }
            
            // Apply window resize immediately since we start expanded
            DispatchQueue.main.async {
                resizeWindow(0.1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if expandPlayer {
                mainWindow?.subviews.first?.transform = .identity
            }
        }
    }
    
    // MARK: - Mini Player
    @ViewBuilder
    func MiniPlayer() -> some View {
        HStack(spacing: 12) {
            ZStack {
                if !expandPlayer {
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
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            )
                    }
                    .clipShape(.rect(cornerRadius: 10))
                    .matchedGeometryEffect(id: "Artwork", in: animation)
                }
            }
            .frame(width: 45, height: 45)
            
            Text(audioPlayer.currentTrack != "No track selected" ? audioPlayer.currentTrack : "Calm Down")
                .lineLimit(1)
            
            Spacer(minLength: 0)
            
            // Control buttons with high priority gestures only
            Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                .font(.title3)
                .foregroundStyle(Color.primary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .highPriorityGesture(
                    TapGesture().onEnded {
                        audioPlayer.togglePlayPause()
                    }
                )
            
            Image(systemName: "forward.fill")
                .font(.title3)
                .foregroundStyle(Color.primary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .highPriorityGesture(
                    TapGesture().onEnded {
                        audioPlayer.playNextTrack()
                    }
                )
        }
        .padding(.horizontal, 10)
        .frame(height: 55)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isAnimating else { return }
            isAnimating = true
            
            show = true
            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                expandPlayer = true
            }
            
            // Resizing Window When Opening Player
            UIView.animate(withDuration: 0.3, animations: {
                resizeWindow(0.1)
            }, completion: { _ in
                isAnimating = false
            })
        }
    }
    
    // MARK: - Expanded Player
    @ViewBuilder
    func ExpandedPlayer(_ size: CGSize, _ safeArea: EdgeInsets) -> some View {
        VStack(spacing: 0) {
            // Drag Handle
            Capsule()
                .fill(.white.secondary)
                .frame(width: 35, height: 5)
                .padding(.top, 10)
            
            // Header with Album Art and Info
            HStack(spacing: 12) {
                ZStack {
                    if expandPlayer {
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
                        .clipShape(.rect(cornerRadius: 10))
                        .matchedGeometryEffect(id: "Artwork", in: animation)
                    }
                }
                .frame(width: 80, height: 80)
                
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
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: {
                        // Favorite action
                    }) {
                        Image(systemName: "heart")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    .frame(width: 44, height: 44)
                    .background(.clear)
                    .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .circle)
                    
                    Button(action: {
                        // More options
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    .frame(width: 44, height: 44)
                    .background(.clear)
                    .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .circle)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            
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
                        audioPlayer.seekTo(currentTime)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow, mainWindow == nil {
                mainWindow = window
                // Generate gradient from current artwork or use default
                if let artworkURL = audioPlayer.currentArtwork,
                   let imageData = try? Data(contentsOf: artworkURL),
                   let image = UIImage(data: imageData) {
                    gradient = Color(image.averageColor ?? .systemPurple).gradient
                } else {
                    gradient = Color(.systemPurple).gradient
                }
            }
            
            // Initialize volume from system volume
            initializeSystemVolume()
            
            // Set up volume observation using notifications
            setupVolumeObservation()
            
            // Start timer for progress simulation - only if not using MusicKit
            if !audioPlayer.usingMusicKit {
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    Task { @MainActor in
                        if audioPlayer.isPlaying && currentTime < totalTime && !isSeekingTime {
                            currentTime += 1.0
                        } else if currentTime >= totalTime {
                            currentTime = 0
                            // Note: You may want to call audioPlayer.pause() here instead
                            // audioPlayer.pause()
                        }
                    }
                }
            }
        }
        .onDisappear {
            // Clean up volume observation
            if let observer = volumeObserver {
                NotificationCenter.default.removeObserver(observer)
                volumeObserver = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if expandPlayer {
                mainWindow?.subviews.first?.transform = .identity
            }
        }
        .accessibilityAction(named: "Expand Player") {
            if !expandPlayer {
                isAnimating = true
                show = true
                withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                    expandPlayer = true
                }
                UIView.animate(withDuration: 0.3, animations: {
                    resizeWindow(0.1)
                }, completion: { _ in
                    isAnimating = false
                })
            }
        }
        .accessibilityAction(named: "Collapse Player") {
            if expandPlayer {
                withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                    expandPlayer = false
                    windowProgress = 0
                    show = false
                    resetWindowWithAnimation()
                }
            }
        }
        .accessibilityLabel(expandPlayer ? "Expanded Music Player" : "Mini Music Player")
        .accessibilityHint(expandPlayer ? "Swipe down to collapse or tap to control playback" : "Tap to expand music player")
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
        // Set up AVAudioSession for volume monitoring (without conflicting with audio playback)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            
            // Observe volume changes via notification
            volumeObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
                object: nil,
                queue: .main
            ) { notification in
                if !self.isAdjustingVolume {
                    if let volumeValue = notification.userInfo?["AVSystemController_AudioVolumeNotificationParameter"] as? Float {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.volume = Double(volumeValue)
                        }
                    }
                }
            }
        } catch {
            print("Failed to set up volume observation: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Window Control
    func resizeWindow(_ progress: CGFloat) {
        if let mainWindow = mainWindow?.subviews.first {
            let offsetY = (mainWindow.frame.height * progress) / 2
            
            mainWindow.layer.cornerRadius = (progress / 0.1) * 30
            mainWindow.layer.masksToBounds = true
            
            mainWindow.transform = .identity.scaledBy(x: 1 - progress, y: 1 - progress).translatedBy(x: 0, y: offsetY)
        }
    }
    
    func resetWindowWithAnimation() {
        if let mainWindow = mainWindow?.subviews.first {
            UIView.animate(withDuration: 0.3) {
                mainWindow.layer.cornerRadius = 0
                mainWindow.transform = .identity
            }
        }
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
