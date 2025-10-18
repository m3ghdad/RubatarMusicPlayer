//
//  Poem.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/1/25.
//

import Foundation

struct Poem: Identifiable, Codable {
    let id: Int
    let title: String?
    let verses: [Verse]
    
    struct Verse: Identifiable, Codable {
        let id: Int
        let text: String
        let position: Int
    }
}

struct Poet: Identifiable, Codable {
    let id: Int
    let name: String
    let nickname: String
    let imageUrl: String?
    let birthYear: Int?
    let deathYear: Int?
    let birthPlace: String?
}
