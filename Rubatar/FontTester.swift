//
//  FontTester.swift
//  Rubatar
//
//  Created by Meghdad Abbaszadegan on 10/16/25.
//

import SwiftUI
import UIKit

struct FontTester: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Available Fonts:")
                    .font(.headline)
                    .padding()
                
                // List all available font families
                ForEach(UIFont.familyNames.sorted(), id: \.self) { familyName in
                    VStack(alignment: .leading) {
                        Text(familyName)
                            .font(.title3)
                            .bold()
                        
                        ForEach(UIFont.fontNames(forFamilyName: familyName), id: \.self) { fontName in
                            Text(fontName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Divider()
                    .padding()
                
                Text("Gideon Roman Test:")
                    .font(.headline)
                
                Text("Test with 'Gideon Roman'")
                    .font(.custom("Gideon Roman", size: 20))
                
                Text("Test with 'GideonRoman-Regular'")
                    .font(.custom("GideonRoman-Regular", size: 20))
                
                Text("The quick brown fox jumps")
                    .font(.custom("GideonRoman-Regular", size: 18))
            }
            .padding()
        }
    }
}

#Preview {
    FontTester()
}
