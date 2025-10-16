import SwiftUI

struct PlanView: View {
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0
    
    var body: some View {
        ZStack {
            getBackgroundColors()[selectedBackgroundColor].gradient
                .ignoresSafeArea()
            
            NavigationView {
                VStack(spacing: 20) {
                    HStack {
                        Text("Plan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        AvatarButtonView()
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 50))
                            .foregroundStyle(.purple)
                        Text("Plan")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Plan your next adventure")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.top, 20)
                .navigationBarHidden(true)
            }
        }
    }
}
