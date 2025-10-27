//
//  CategoryCard.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/27/25.
//

import SwiftUI

struct CategoryCard: View {
    let title: String
    let icon: String?
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
                    
                    VStack(spacing: 12) {
                        if let icon = icon {
                            Image(systemName: icon)
                                .font(.system(size: 32))
                                .foregroundColor(colorScheme == .dark ? Color(hex: "E3B887") : Color(hex: "7A5C39"))
                        }
                        
                        Text(title)
                            .font(.custom("Palatino", size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

