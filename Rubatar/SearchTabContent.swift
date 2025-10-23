import SwiftUI

struct SearchTabContent: View {
    var searchText: String
    @State private var currentPoemIndex = 0
    @State private var currentLanguage: Language = .farsi
    @State private var displayedText = ""
    @State private var currentCharIndex = 0
    @State private var isTyping = false
    @Environment(\.colorScheme) var colorScheme
    
    enum Language {
        case farsi, english
    }
    
    let patiencePoems = [
        // Saadi
        (farsi: "صبوری کن که تلخی‌ها گذارد\nکه بعد از هر شبی روزی برآید", english: "Be patient, for bitterness will pass —\nAfter every night, a day will rise."),
        // Hafez
        (farsi: "صبوری می‌کنم تا کام دل یابم، ولی دانم\nکه این دریا به خون دل، شدن آسان نمی‌گردد", english: "I am patient till my heart's desire I gain —\nBut I know this sea won't calm without the blood of pain."),
        // Rumi
        (farsi: "صبر کن ای دل که در پایان شب\nصبح امیدت دمَد از آفتاب", english: "Be patient, my heart —\nAt the night's end, the sun of hope will rise."),
        // Ferdowsi
        (farsi: "به صبر اندر آری به هر کار دست\nکز آتش، خردمند، آرد شکر ز پست", english: "With patience, you'll master any deed —\nFor even from fire, the wise draw sweetness."),
        // Attar
        (farsi: "صبر کن، تا بر تو گردد روزگار\nکز شکیبایی، گل آید زین خار", english: "Be patient till fate turns your way —\nFrom patience, flowers bloom from thorns."),
        // Baba Taher
        (farsi: "دلا صبر کن، کار دنیا گذاره\nغم و شادی و تیمار دنیا گذاره", english: "O heart, be patient, this world will pass —\nIts sorrow, its joy, its burden will pass."),
        // Khayyam
        (farsi: "چون نیست رهی به جاودانی، صبر است\nدر ناملایمات جهانی، صبر است", english: "Since no road leads to eternity, be patient —\nIn all this world's hardships, patience is the way."),
        // Nizami
        (farsi: "هر که صبر آموخت، کام یافت\nهر که شتاب کرد، زیان یافت", english: "He who learned patience, found delight;\nHe who rushed, met loss outright."),
        // Sanai
        (farsi: "صبوری، کلید گنج مراد است\nکه در بی‌تابی، درِ دل گشاد است", english: "Patience is the key to the treasure of desire —\nFor restlessness only opens the heart to fire."),
        // Bedil Dehlavi
        (farsi: "صبری که تلخ نیست، صبر نیست\nشیرینیِ آن، در تلخی‌ست", english: "Patience that isn't bitter isn't patience —\nIts sweetness lies in its bitterness.")
    ]

    var body: some View {
        ZStack {
            // Dynamic background that adapts to light/dark mode
            (colorScheme == .dark ? Color.black : Color(red: 244/255, green: 244/255, blue: 244/255))
                .ignoresSafeArea(.all)
            
            VStack {
                Spacer()
                
                VStack(spacing: 30) {
                    Text("Coming soon")
                        .font(.custom("Palatino", size: 24))
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 20) {
                        Text(displayedText)
                            .font(.custom("Palatino", size: 18))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                            .frame(minHeight: 120)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            startTyping()
        }
    }
    
    private func startTyping() {
        isTyping = true
        displayedText = ""
        currentCharIndex = 0
        
        let currentPoem = patiencePoems[currentPoemIndex]
        let textToType = currentLanguage == .farsi ? currentPoem.farsi : currentPoem.english
        
        typeText(textToType)
    }
    
    private func typeText(_ text: String) {
        guard currentCharIndex < text.count else {
            // Finished typing, wait then move to next poem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                nextPoem()
            }
            return
        }
        
        let index = text.index(text.startIndex, offsetBy: currentCharIndex)
        displayedText = String(text[..<index])
        currentCharIndex += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            typeText(text)
        }
    }
    
    private func nextPoem() {
        currentPoemIndex = (currentPoemIndex + 1) % patiencePoems.count
        currentLanguage = currentLanguage == .farsi ? .english : .farsi
        startTyping()
    }
}
