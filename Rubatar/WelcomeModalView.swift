import SwiftUI

struct WelcomeModalView: View {
    let isDarkMode: Bool
    let onButtonDismiss: () -> Void
    let onPlayTapped: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ZStack {
                    AsyncImage(url: URL(string: "https://plus.unsplash.com/premium_photo-1752782188828-6bff4fe86c4e?q=80&w=2664&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(.quaternary)
                    }
                    .frame(height: 200)
                    .clipped()
                    
                    Button(action: onPlayTapped) {
                        ZStack {
                            Circle()
                                .fill(.clear)
                                .frame(width: 80, height: 80)
                                .glassEffect(in: Circle())
                            
                            Image(systemName: "play.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                                .offset(x: 2)
                        }
                    }
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 16)
                        
                        VStack(spacing: 16) {
                            Text("Title")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("Aenean pharetra, erat id malesuada iaculis, mauris tortor dictum ligula, dapibus faucibus odio est id arcu. Proin metus justo, mattis eu lacus a, accumsan sodales tellus.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                            
                            HStack(spacing: 8) {
                                ForEach(0..<5) { index in
                                    Circle()
                                        .fill(index == 0 ? Color.blue : Color.gray.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                    }
                }
                
                VStack(spacing: 0) {
                    Divider()
                    
                    Button(action: onButtonDismiss) {
                        Text("CTA")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(.regularMaterial)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
