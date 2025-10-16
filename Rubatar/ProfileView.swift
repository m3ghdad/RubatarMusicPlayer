import SwiftUI

struct ProfileView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    Text("Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    AvatarButtonView()
                }
                .padding(.horizontal, 20)
                
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundStyle(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Appearance")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Choose your preferred theme")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isDarkMode)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
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
                
                VStack(spacing: 12) {
                    SettingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Manage your alerts")
                    SettingsRow(icon: "lock.fill", title: "Privacy", subtitle: "Control your data")
                    SettingsRow(icon: "gear", title: "General", subtitle: "App preferences")
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationBarHidden(true)
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
