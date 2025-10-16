import SwiftUI

struct SearchTabContent: View {
    var searchText: String
    @AppStorage("selectedBackgroundColor") private var selectedBackgroundColor = 0

    @Environment(\.isSearching) private var isSearching

    var body: some View {
        ZStack {
            getBackgroundColors()[selectedBackgroundColor].gradient
                .ignoresSafeArea()
            
            List {
                if !isSearching {
                    HStack {
                        Text("Search")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        AvatarButtonView()
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                if searchText.isEmpty {
                    Section("Quick Actions") {
                        Label("Explore destinations", systemImage: "globe")
                        Label("Find nearby", systemImage: "location")
                    }
                    Section("Recent searches") {
                        Text("No recent searches")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Section("Results") {
                        Text("Results for \"\(searchText)\"")
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}
