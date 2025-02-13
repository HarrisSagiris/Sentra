import SwiftUI
import WebKit

class GestureManager: ObservableObject {
    @Published var scale: CGFloat = 1.0
    @Published var showAISearch: Bool = false
    
    // Minimum and maximum zoom scale limits
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 3.0
    
    func configureGestures(for webView: WKWebView) {
        // Pinch gesture for zooming
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        webView.addGestureRecognizer(pinchGesture)
        
        // Swipe gestures for navigation
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeRight.direction = .right
        webView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeLeft.direction = .left
        webView.addGestureRecognizer(swipeLeft)
        
        // Swipe down for AI search
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDown.direction = .down
        webView.addGestureRecognizer(swipeDown)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .changed:
            let newScale = scale * gesture.scale
            scale = min(max(newScale, minScale), maxScale)
            
            // Apply smooth animation
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                gesture.view?.transform = CGAffineTransform(scaleX: self.scale, y: self.scale)
            }
            gesture.scale = 1.0
            
        case .ended:
            // Spring animation when gesture ends
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3) {
                gesture.view?.transform = CGAffineTransform(scaleX: self.scale, y: self.scale)
            }
            
        default:
            break
        }
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard let webView = gesture.view as? WKWebView else { return }
        
        // Apply smooth transition animation
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            if gesture.direction == .right && webView.canGoBack {
                webView.goBack()
            } else if gesture.direction == .left && webView.canGoForward {
                webView.goForward()
            }
        }
    }
    
    @objc private func handleSwipeDown(_ gesture: UISwipeGestureRecognizer) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showAISearch = true
        }
    }
    
    func resetZoom() {
        scale = 1.0
    }
}
