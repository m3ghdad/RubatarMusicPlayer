//
//  Album.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import Foundation
import MusicKit

// Custom artwork type for our sample data
struct CustomArtwork: Hashable, Equatable {
    let url: URL
    
    func url(width: Int, height: Int) -> URL? {
        return url
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    // Equatable conformance
    static func == (lhs: CustomArtwork, rhs: CustomArtwork) -> Bool {
        return lhs.url == rhs.url
    }
}

struct Album: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let artwork: CustomArtwork?
    let trackCount: Int
    let releaseDate: Date
    
    var formattedReleaseDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: releaseDate)
    }
    
    var artworkURL: URL? {
        artwork?.url(width: 300, height: 300)
    }
}

struct Playlist: Identifiable, Hashable {
    let id: String
    let title: String
    let curatorName: String
    let artwork: CustomArtwork?
    let trackCount: Int
    let description: String
    
    var artworkURL: URL? {
        artwork?.url(width: 300, height: 300)
    }
}
