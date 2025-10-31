//
//  DeepAnalysisBottomSheet.swift
//  Rubatar
//
//  Created on 10/17/25.
//

import SwiftUI

struct DeepAnalysisBottomSheet: View {
    let tafseerText: String
    let selectedLanguage: AppLanguage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: selectedLanguage == .farsi ? .trailing : .leading, spacing: 16) {
                // Title
                Text(selectedLanguage == .farsi ? "تفسیر" : "Interpretation")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
                    .padding(.bottom, 8)
                
                // Tafseer text
                Text(tafseerText)
                    .font(.system(size: 17))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineSpacing(8)
                    .multilineTextAlignment(selectedLanguage == .farsi ? .trailing : .leading)
                    .frame(maxWidth: .infinity, alignment: selectedLanguage == .farsi ? .trailing : .leading)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

