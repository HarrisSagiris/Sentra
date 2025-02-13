import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var privacyManager: PrivacyManager
    @EnvironmentObject private var themeManager: ThemeManager
    @AppStorage("homepage") private var homepage = "https://www.google.com"
    @AppStorage("aiSearchEnabled") private var aiSearchEnabled = true
    
    var body: some View {
        Form {
            Section(header: Text("Privacy")) {
                Toggle("Ad & Tracker Blocking", isOn: $privacyManager.isAdBlockingEnabled)
                if privacyManager.isAdBlockingEnabled {
                    Text("Trackers blocked: \(privacyManager.blockedTrackerCount)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Browser")) {
                TextField("Homepage", text: $homepage)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                Toggle("AI-Powered Search", isOn: $aiSearchEnabled)
            }
            
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $themeManager.currentTheme) {
                    ForEach(ThemeManager.Theme.allCases, id: \.self) { theme in
                        Text(theme.rawValue.capitalized)
                    }
                }
                
                if themeManager.customWallpaper != nil {
                    Button("Remove Custom Wallpaper") {
                        withAnimation {
                            themeManager.customWallpaper = nil
                        }
                    }
                    
                    Slider(value: $themeManager.blurIntensity, in: 0...20) {
                        Text("Blur Intensity")
                    }
                }
            }
            
            Section {
                Button("Select Custom Wallpaper") {
                    // Image picker would be implemented here
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(PrivacyManager())
            .environmentObject(ThemeManager())
    }
}
