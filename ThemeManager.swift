import SwiftUI
import UIKit

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    enum Theme: String {
        case light
        case dark
        case amoled
    }
    
    @Published var currentTheme: Theme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
            applyTheme()
        }
    }
    
    @Published var customWallpaper: UIImage? {
        didSet {
            if let imageData = customWallpaper?.jpegData(compressionQuality: 0.8) {
                UserDefaults.standard.set(imageData, forKey: "customWallpaper")
            }
        }
    }
    
    @Published var blurIntensity: Double {
        didSet {
            UserDefaults.standard.set(blurIntensity, forKey: "blurIntensity")
        }
    }
    
    private init() {
        // Load saved theme
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? Theme.light.rawValue
        currentTheme = Theme(rawValue: savedTheme) ?? .light
        
        // Load saved wallpaper
        if let savedImageData = UserDefaults.standard.data(forKey: "customWallpaper") {
            customWallpaper = UIImage(data: savedImageData)
        } else {
            customWallpaper = nil
        }
        
        // Load saved blur intensity
        blurIntensity = UserDefaults.standard.double(forKey: "blurIntensity")
    }
    
    func applyTheme(animated: Bool = true) {
        let duration = animated ? 0.3 : 0
        
        UIView.animate(withDuration: duration) {
            switch self.currentTheme {
            case .light:
                self.applyLightTheme()
            case .dark:
                self.applyDarkTheme()
            case .amoled:
                self.applyAmoledTheme()
            }
        }
    }
    
    private func applyLightTheme() {
        let backgroundColor = UIColor.systemBackground
        let textColor = UIColor.label
        
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .light
            window.backgroundColor = backgroundColor
        }
    }
    
    private func applyDarkTheme() {
        let backgroundColor = UIColor.systemBackground
        let textColor = UIColor.label
        
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .dark
            window.backgroundColor = backgroundColor
        }
    }
    
    private func applyAmoledTheme() {
        let backgroundColor = UIColor.black
        let textColor = UIColor.white
        
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .dark
            window.backgroundColor = backgroundColor
        }
    }
    
    func setCustomWallpaper(_ image: UIImage) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.customWallpaper = image
        }
    }
    
    func getBlurredBackground() -> some View {
        Group {
            if let wallpaper = customWallpaper {
                Image(uiImage: wallpaper)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: blurIntensity)
                    .opacity(0.5)
            } else {
                Color(UIColor.systemBackground)
            }
        }
    }
    
    func setBlurIntensity(_ intensity: Double) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.blurIntensity = intensity
        }
    }
}
