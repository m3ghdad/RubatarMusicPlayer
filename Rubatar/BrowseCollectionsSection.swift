import SwiftUI

struct BrowseCollectionsSection: View {
    let collections = [
        CollectionItem(
            badge: "New",
            title: "Nature Escapes",
            description: "Discover breathtaking landscapes and serene natural beauty",
            imageName: "forest",
            color: .green
        ),
        CollectionItem(
            badge: "Popular",
            title: "Urban Adventures",
            description: "Explore vibrant cityscapes and modern architecture",
            imageName: "building.2",
            color: .blue
        ),
        CollectionItem(
            badge: "Featured",
            title: "Ocean Views",
            description: "Immerse yourself in stunning coastal and marine scenes",
            imageName: "water.waves",
            color: .cyan
        ),
        CollectionItem(
            badge: "Trending",
            title: "Mountain Peaks",
            description: "Experience majestic mountain ranges and alpine vistas",
            imageName: "mountain.2",
            color: .orange
        ),
        CollectionItem(
            badge: "Editor's Pick",
            title: "Desert Landscapes",
            description: "Journey through vast deserts and golden dunes",
            imageName: "sun.max",
            color: .yellow
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SectionTitle")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Lectus sed pellentesque faucibus, urna lectus rutrum lorem, sit amet mattis orci lorem pretium nisl.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(16)
            
            VStack(spacing: 16) {
                ForEach(collections, id: \.title) { collection in
                    CollectionCard(collection: collection)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct CollectionCard: View {
    let collection: CollectionItem
    
    var body: some View {
        ZStack {
            if collection.title == "Nature Escapes" {
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1618005198919-d3d4b5a92ead?q=80&w=2748&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    collection.color.opacity(0.4),
                                    collection.color.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(height: 280)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                collection.color.opacity(0.4),
                                collection.color.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 280)
                
                Image(systemName: collection.imageName)
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.15))
                    .offset(x: 15, y: -10)
            }
            
            VStack(spacing: 0) {
                HStack {
                    Text(collection.badge)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.black.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.white.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                    
                    Text(collection.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [
                            .clear,
                            .black.opacity(0.4),
                            .black.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

struct CollectionItem {
    let badge: String
    let title: String
    let description: String
    let imageName: String
    let color: Color
}
