//
//  CoreDataManager.swift
//  Rubatar
//
//  Core Data persistence manager
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RubatarDataModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error.localizedDescription)")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Failed to save context: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Poem Caching
    
    func cachePoems(_ poems: [PoemData]) {
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            // Clear existing cache first
            let deleteRequest: NSFetchRequest<NSFetchRequestResult> = CachedPoem.fetchRequest()
            let batchDelete = NSBatchDeleteRequest(fetchRequest: deleteRequest)
            _ = try? context.execute(batchDelete)
            
            for poem in poems {
                let cachedPoem = CachedPoem(context: context)
                cachedPoem.id = Int64(poem.id)
                cachedPoem.poemText = poem.verses.flatMap { $0 }.joined(separator: "\n")
                cachedPoem.poemTextEn = poem.poem_text_en
                cachedPoem.poemNameFa = poem.title
                cachedPoem.poemNameEn = poem.poem_name_en
                cachedPoem.poetNameFa = poem.poet.fullName
                cachedPoem.poetNameEn = poem.poet_name_en
                cachedPoem.topicNameFa = poem.topic
                cachedPoem.topicNameEn = poem.topic_name_en
                cachedPoem.playlistId = poem.playlist_id
                cachedPoem.playlistName = poem.playlist_name
                cachedPoem.curatorName = poem.curator_name
                cachedPoem.artworkUrl = poem.artwork_url
                cachedPoem.cacheDate = Date()
            }
            
            do {
                try context.save()
                print("✅ Successfully cached \(poems.count) poems")
            } catch {
                print("❌ Failed to cache poems: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchCachedPoems(limit: Int = 100) -> [PoemData] {
        let request: NSFetchRequest<CachedPoem> = CachedPoem.fetchRequest()
        request.fetchLimit = limit
        request.sortDescriptors = [NSSortDescriptor(key: "cacheDate", ascending: false)]
        
        do {
            let cachedPoems = try context.fetch(request)
            return cachedPoems.compactMap { cachedPoem -> PoemData? in
                guard let poemText = cachedPoem.poemText,
                      let poetName = cachedPoem.poetNameFa,
                      let poemTitle = cachedPoem.poemNameFa else { return nil }
                
                // Parse poem text back into verses (couplets of 2 lines)
                let lines = poemText.components(separatedBy: "\n").filter { !$0.isEmpty }
                var verses: [[String]] = []
                var currentVerse: [String] = []
                
                for line in lines {
                    currentVerse.append(line)
                    if currentVerse.count == 2 {
                        verses.append(currentVerse)
                        currentVerse = []
                    }
                }
                if !currentVerse.isEmpty {
                    verses.append(currentVerse)
                }
                
                let poet = PoetInfo(
                    id: Int(cachedPoem.id),
                    name: poetName,
                    fullName: poetName
                )
                
                return PoemData(
                    id: Int(cachedPoem.id),
                    title: poemTitle,
                    poet: poet,
                    verses: verses,
                    topic: cachedPoem.topicNameFa,
                    mood: nil,
                    moodColor: nil,
                    poem_text_en: cachedPoem.poemTextEn,
                    poem_name_en: cachedPoem.poemNameEn,
                    poet_name_en: cachedPoem.poetNameEn,
                    topic_name_en: cachedPoem.topicNameEn,
                    playlist_id: cachedPoem.playlistId,
                    playlist_name: cachedPoem.playlistName,
                    curator_name: cachedPoem.curatorName,
                    artwork_url: cachedPoem.artworkUrl
                )
            }
        } catch {
            print("❌ Failed to fetch cached poems: \(error.localizedDescription)")
            return []
        }
    }
    
    func clearOldPoems(olderThan days: Int = 7) {
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            let request: NSFetchRequest<NSFetchRequestResult> = CachedPoem.fetchRequest()
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
            request.predicate = NSPredicate(format: "cacheDate < %@", cutoffDate as NSDate)
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print("❌ Failed to clear old poems: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Playlist Caching
    
    func cachePlaylist(id: String, name: String?, curator: String?, artworkUrl: String?) {
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            let request: NSFetchRequest<CachedPlaylist> = CachedPlaylist.fetchRequest()
            request.predicate = NSPredicate(format: "playlistId == %@", id)
            
            let playlist: CachedPlaylist
            if let existing = try? context.fetch(request).first {
                playlist = existing
            } else {
                playlist = CachedPlaylist(context: context)
                playlist.playlistId = id
            }
            
            playlist.playlistName = name
            playlist.curatorName = curator
            playlist.artworkUrl = artworkUrl
            playlist.cacheDate = Date()
            
            do {
                try context.save()
            } catch {
                print("❌ Failed to cache playlist: \(error.localizedDescription)")
            }
        }
    }
    
    func recordPlaylistPlay(id: String) {
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            let request: NSFetchRequest<CachedPlaylist> = CachedPlaylist.fetchRequest()
            request.predicate = NSPredicate(format: "playlistId == %@", id)
            
            if let playlist = try? context.fetch(request).first {
                playlist.lastPlayed = Date()
                playlist.playCount += 1
                
                try? context.save()
            }
        }
    }
    
    // MARK: - Album Caching
    
    func cacheAlbum(id: String, name: String?, artist: String?, artworkUrl: String?) {
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            let request: NSFetchRequest<CachedAlbum> = CachedAlbum.fetchRequest()
            request.predicate = NSPredicate(format: "albumId == %@", id)
            
            let album: CachedAlbum
            if let existing = try? context.fetch(request).first {
                album = existing
            } else {
                album = CachedAlbum(context: context)
                album.albumId = id
            }
            
            album.albumName = name
            album.artistName = artist
            album.artworkUrl = artworkUrl
            album.cacheDate = Date()
            
            do {
                try context.save()
            } catch {
                print("❌ Failed to cache album: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Recently Played
    
    func addRecentlyPlayed(trackId: String?, trackName: String?, artistName: String?, artworkUrl: String?, playlistId: String? = nil, albumId: String? = nil) {
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            let recent = RecentlyPlayed(context: context)
            recent.playedAt = Date()
            recent.trackId = trackId
            recent.trackName = trackName
            recent.artistName = artistName
            recent.artworkUrl = artworkUrl
            recent.playlistId = playlistId
            recent.albumId = albumId
            
            do {
                try context.save()
                
                // Keep only last 100 items
                let request: NSFetchRequest<NSFetchRequestResult> = RecentlyPlayed.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: "playedAt", ascending: false)]
                request.fetchOffset = 100
                
                if let old = try? context.fetch(request) as? [RecentlyPlayed] {
                    old.forEach { context.delete($0) }
                    try? context.save()
                }
            } catch {
                print("❌ Failed to add recently played: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchRecentlyPlayed(limit: Int = 20) -> [(trackName: String, artistName: String, artworkUrl: String?, playedAt: Date)] {
        let request: NSFetchRequest<RecentlyPlayed> = RecentlyPlayed.fetchRequest()
        request.fetchLimit = limit
        request.sortDescriptors = [NSSortDescriptor(key: "playedAt", ascending: false)]
        
        do {
            let items = try context.fetch(request)
            return items.compactMap { item in
                guard let trackName = item.trackName, let artistName = item.artistName else {
                    return nil
                }
                return (trackName: trackName, artistName: artistName, artworkUrl: item.artworkUrl, playedAt: item.playedAt!)
            }
        } catch {
            print("❌ Failed to fetch recently played: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Preferences
    
    func setPreference(key: String, value: String) {
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            let request: NSFetchRequest<AppPreferences> = AppPreferences.fetchRequest()
            request.predicate = NSPredicate(format: "key == %@", key)
            
            let preference: AppPreferences
            if let existing = try? context.fetch(request).first {
                preference = existing
            } else {
                preference = AppPreferences(context: context)
                preference.key = key
            }
            
            preference.value = value
            preference.updatedAt = Date()
            
            try? context.save()
        }
    }
    
    func getPreference(key: String) -> String? {
        let request: NSFetchRequest<AppPreferences> = AppPreferences.fetchRequest()
        request.predicate = NSPredicate(format: "key == %@", key)
        
        return try? context.fetch(request).first?.value
    }
}

// MARK: - Core Data Entities

@objc(CachedPoem)
public class CachedPoem: NSManagedObject {
    @NSManaged public var id: Int64
    @NSManaged public var cacheDate: Date
    @NSManaged public var poemText: String?
    @NSManaged public var poemTextEn: String?
    @NSManaged public var poemNameFa: String?
    @NSManaged public var poemNameEn: String?
    @NSManaged public var poetNameFa: String?
    @NSManaged public var poetNameEn: String?
    @NSManaged public var topicNameFa: String?
    @NSManaged public var topicNameEn: String?
    @NSManaged public var playlistId: String?
    @NSManaged public var playlistName: String?
    @NSManaged public var curatorName: String?
    @NSManaged public var artworkUrl: String?
}

extension CachedPoem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedPoem> {
        return NSFetchRequest<CachedPoem>(entityName: "CachedPoem")
    }
}

@objc(CachedPlaylist)
public class CachedPlaylist: NSManagedObject {
    @NSManaged public var playlistId: String
    @NSManaged public var cacheDate: Date
    @NSManaged public var playlistName: String?
    @NSManaged public var curatorName: String?
    @NSManaged public var artworkUrl: String?
    @NSManaged public var trackCount: Int32
    @NSManaged public var category: String?
    @NSManaged public var lastPlayed: Date?
    @NSManaged public var playCount: Int32
}

extension CachedPlaylist {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedPlaylist> {
        return NSFetchRequest<CachedPlaylist>(entityName: "CachedPlaylist")
    }
}

@objc(CachedAlbum)
public class CachedAlbum: NSManagedObject {
    @NSManaged public var albumId: String
    @NSManaged public var cacheDate: Date
    @NSManaged public var albumName: String?
    @NSManaged public var artistName: String?
    @NSManaged public var artworkUrl: String?
    @NSManaged public var trackCount: Int32
    @NSManaged public var releaseDate: Date?
    @NSManaged public var lastPlayed: Date?
    @NSManaged public var playCount: Int32
}

extension CachedAlbum {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedAlbum> {
        return NSFetchRequest<CachedAlbum>(entityName: "CachedAlbum")
    }
}

@objc(RecentlyPlayed)
public class RecentlyPlayed: NSManagedObject {
    @NSManaged public var playedAt: Date
    @NSManaged public var trackId: String?
    @NSManaged public var trackName: String?
    @NSManaged public var artistName: String?
    @NSManaged public var artworkUrl: String?
    @NSManaged public var playlistId: String?
    @NSManaged public var albumId: String?
}

extension RecentlyPlayed {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecentlyPlayed> {
        return NSFetchRequest<RecentlyPlayed>(entityName: "RecentlyPlayed")
    }
}

@objc(AppPreferences)
public class AppPreferences: NSManagedObject {
    @NSManaged public var key: String
    @NSManaged public var value: String?
    @NSManaged public var updatedAt: Date
}

extension AppPreferences {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppPreferences> {
        return NSFetchRequest<AppPreferences>(entityName: "AppPreferences")
    }
}

