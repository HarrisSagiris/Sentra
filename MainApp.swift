import SwiftUI

@main
struct SentraApp: App {
    @StateObject private var privacyManager = PrivacyManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var searchManager = AISearchManager()
    @AppStorage("selectedTab") private var selectedTab = 0
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                // Browser Tab
                NavigationView {
                    BrowserView()
                        .environmentObject(privacyManager)
                        .environmentObject(themeManager)
                }
                .tabItem {
                    Image(systemName: "globe")
                    Text("Browser")
                }
                .tag(0)
                
                // AI Search Tab
                NavigationView {
                    AISearchView()
                        .environmentObject(searchManager)
                        .environmentObject(themeManager)
                }
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("AI Search")
                }
                .tag(1)
                
                // Settings Tab
                NavigationView {
                    SettingsView()
                        .environmentObject(privacyManager)
                        .environmentObject(themeManager)
                }
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
            }
            .background(themeManager.getBlurredBackground())
            .animation(.easeInOut, value: selectedTab)
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }
}
