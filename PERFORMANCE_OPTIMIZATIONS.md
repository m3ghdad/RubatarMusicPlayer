# Performance Optimizations

This document describes all the performance optimizations implemented in the Rubatar app.

## 1. Caching Infrastructure

### Image Caching (`ImageCacheManager`)
- **Memory Cache**: NSCache with 100MB limit, stores up to 200 images
- **Disk Cache**: 500MB limit with LRU eviction policy
- **Cache Duration**: 7 days, automatically cleaned
- **Features**:
  - Automatic preloading of images
  - Async image loading with fallback
  - `CachedAsyncImage` SwiftUI view for easy integration

**Usage**:
```swift
// Load single image
let image = await ImageCacheManager.shared.loadImage(from: url)

// Preload multiple images
ImageCacheManager.shared.preloadImages(urls: [url1, url2, url3])

// Use in SwiftUI
CachedAsyncImage(url: artworkURL) { image in
    image.resizable().aspectRatio(contentMode: .fill)
}
```

### Network Caching (`NetworkCacheManager`)
- **URLCache Configuration**: 50MB memory, 200MB disk
- **HTTP/2 Support**: Enabled for faster connections
- **Connection Pooling**: Up to 6 connections per host
- **Cache Policy**: Returns cached data when available

## 2. Core Data Persistence

### Data Models
- **CachedPoem**: Stores poem data with metadata
- **CachedPlaylist**: Stores playlist information
- **CachedAlbum**: Stores album metadata
- **RecentlyPlayed**: Tracks listening history (last 100 items)
- **AppPreferences**: Stores app settings

### CoreDataManager Features
- Background context for non-blocking saves
- Automatic cache expiration (7 days for poems)
- Batch delete operations for efficiency
- Thread-safe operations

**Usage**:
```swift
// Cache poems
CoreDataManager.shared.cachePoems(poems)

// Fetch cached poems
let cachedPoems = CoreDataManager.shared.fetchCachedPoems(limit: 100)

// Record recently played
CoreDataManager.shared.addRecentlyPlayed(
    trackId: id,
    trackName: name,
    artistName: artist,
    artworkUrl: url
)
```

## 3. Poetry Service Optimization

### Cache-First Strategy
1. Checks Core Data cache first
2. Returns cached poems immediately
3. Fetches fresh data in background
4. Updates cache silently

### Offline Support
- Falls back to cached data when network fails
- Seamless offline experience

**Usage**:
```swift
// Fetch with caching (default)
let poems = await poetryService.fetchPoems(limit: 100)

// Force fresh fetch
let freshPoems = await poetryService.fetchPoems(useCache: false)
```

## 4. Music Player Enhancements

### Prefetching
- Automatically preloads next track artwork
- Preloads artwork when playlist selected
- Reduces perceived loading time

### Metadata Caching
- Caches playlist/album information
- Records play counts and last played date
- Tracks recently played songs (last 100)

**Automatic Features**:
- Next track artwork prefetched on track change
- Playlist metadata saved on selection
- Play history automatically tracked

## 5. Apple Music Authorization Caching

### MusicAuthCacheManager
- Caches authorization status for 1 hour
- Reduces redundant authorization checks
- Automatic cache invalidation

**Usage**:
```swift
// Get cached or fresh status
let status = await MusicAuthCacheManager.shared.getAuthStatus()

// Request authorization with caching
let status = await MusicAuthCacheManager.shared.requestAuthorization()
```

## 6. Background Processing

### BackgroundTaskManager
- Refreshes poems in background (every 4 hours)
- Preloads artwork during idle time
- Cleans old cache automatically

### Background Refresh Tasks
- Fetches 100 new poems
- Preloads first 10 artworks
- Cleans cache older than 7 days
- Operates within iOS 30-second limit

**Setup Required**:
1. Add background mode capability in Xcode
2. Add to Info.plist:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.meghdad.Rubatar.refresh</string>
</array>
```

## 7. Performance Best Practices

### Implemented
✅ Lazy loading with LazyVStack/LazyHStack
✅ Async/await for non-blocking operations
✅ Background context for Core Data operations
✅ Structured concurrency for parallel tasks
✅ Resource cleanup and memory management

### View Optimizations
✅ Image caching reduces network calls
✅ Prefetching reduces perceived latency
✅ Offline support improves reliability
✅ Background refresh keeps data fresh

## 8. Monitoring & Metrics

### Automatic Logging
- Cache hits/misses logged
- Network request timing
- Background task completion
- Error tracking

### Debug Output
Look for these emoji prefixes in console:
- 🎨 Image caching operations
- 📚 Poetry service operations
- ✅ Successful operations
- ❌ Errors and failures
- 🔄 Background refresh
- 💾 Data persistence
- 🔐 Authorization caching

## 9. Memory Management

### Cache Limits
- **Image Memory**: 100MB (200 images max)
- **Image Disk**: 500MB
- **URL Cache Memory**: 50MB
- **URL Cache Disk**: 200MB
- **Recently Played**: 100 items max

### Automatic Cleanup
- Old poems: Deleted after 7 days
- Image cache: LRU eviction when limit reached
- Recently played: Keeps only last 100

## 10. Integration Guide

### Minimum Changes Required

1. **Add Background Mode** (Xcode project settings):
   - Background fetch
   - Background processing

2. **Info.plist** (create if doesn't exist):
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.meghdad.Rubatar.refresh</string>
</array>
```

### Using CachedAsyncImage

Replace `AsyncImage` with `CachedAsyncImage`:
```swift
// Before
AsyncImage(url: artworkURL) { image in
    image.resizable()
}

// After
CachedAsyncImage(url: artworkURL) { image in
    image.resizable()
}
```

### Accessing Cached Data

All managers are singletons with `.shared`:
```swift
ImageCacheManager.shared
CoreDataManager.shared
MusicAuthCacheManager.shared
BackgroundTaskManager.shared
NetworkCacheManager.shared
```

## 11. Performance Gains

### Expected Improvements
- **App Launch**: 40-60% faster (cached poems)
- **Image Loading**: 70-90% faster (cached images)
- **Network Calls**: 50-70% reduction
- **Offline Experience**: 100% functional for viewing
- **Memory Usage**: Controlled with automatic limits
- **Battery Impact**: Minimal with background processing

### Metrics to Monitor
- Time to first poem display
- Image load times
- Cache hit rate
- Background task success rate
- Memory footprint

## 12. Troubleshooting

### If caching isn't working:
1. Check console for error messages (🔴 ❌)
2. Verify Core Data model is properly loaded
3. Check file permissions for cache directories
4. Verify URLCache configuration

### If background refresh isn't working:
1. Verify BGTaskScheduler registration
2. Check Info.plist configuration
3. Use debugging with `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.meghdad.Rubatar.refresh"]` in lldb
4. Check background mode capabilities

### Clear all caches:
```swift
ImageCacheManager.shared.clearCache()
MusicAuthCacheManager.shared.clearCache()
// Core Data cache is auto-managed
```

## 13. Content Preloading

### ContentPreloader
- Preloads content on app launch (max 2 seconds)
- Runs tasks in parallel for efficiency
- Shows skeleton loading during preload

### What Gets Preloaded
- **100 poems** from PoetryService (cached)
- **10 playlists** from Apple Music (if authorized)
- **10 albums** from Apple Music (if authorized)
- **First 5 artworks** from each category

### Benefits
- Instant content display (no waiting)
- Smooth user experience
- Cached data available immediately
- Background refresh keeps data fresh

### Integration
```swift
@StateObject private var contentPreloader = ContentPreloader()

// Preload on app start
Task {
    await contentPreloader.preloadContent()
}

// Use loading state
if contentPreloader.isLoading {
    SkeletonView()
}
```

## 14. Future Optimizations

Potential improvements for next phase:
- [ ] Batch API requests optimization
- [ ] Smart pagination for playlists
- [ ] Request throttling/debouncing
- [ ] Predictive prefetching based on user behavior
- [ ] Image size optimization (multiple resolutions)
- [ ] Memory pressure monitoring
- [ ] Analytics integration

---

**Last Updated**: October 26, 2025
**Performance Branch**: `performance`

