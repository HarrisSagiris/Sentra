import SwiftUI
import WebKit
import Combine

struct BrowserView: View {
    @StateObject private var webViewModel = WebViewModel()
    @State private var searchText = ""
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom search bar
            HStack(spacing: 12) {
                Image(systemName: webViewModel.isLoading ? "stop.fill" : "magnifyingglass")
                    .foregroundColor(.gray)
                    .onTapGesture {
                        if webViewModel.isLoading {
                            webViewModel.stopLoading()
                        }
                    }
                
                TextField("Search or enter URL", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        webViewModel.loadUrl(from: searchText)
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            .shadow(color: Color.black.opacity(0.1), radius: 5)
            
            // Web content
            RefreshableWebView(webViewModel: webViewModel, isRefreshing: $isRefreshing)
                .edgesIgnoringSafeArea(.bottom)
        }
        .onChange(of: webViewModel.currentURL) { newValue in
            searchText = newValue?.absoluteString ?? ""
        }
    }
}

class WebViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var currentURL: URL?
    var webView: WKWebView
    
    init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        
        if let url = URL(string: "https://www.google.com") {
            webView.load(URLRequest(url: url))
            currentURL = url
        }
        
        webView.navigationDelegate = self
    }
    
    func loadUrl(from input: String) {
        var urlString = input
        
        if !input.contains("://") {
            // If input doesn't contain protocol, assume it's a search query
            urlString = "https://www.google.com/search?q=\(input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        } else if !input.hasPrefix("https://") && !input.hasPrefix("http://") {
            urlString = "https://" + input
        }
        
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
    }
    
    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    func refresh() {
        webView.reload()
    }
    
    func stopLoading() {
        webView.stopLoading()
        isLoading = false
    }
}

extension WebViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        currentURL = webView.url
    }
}

struct RefreshableWebView: UIViewRepresentable {
    @ObservedObject var webViewModel: WebViewModel
    @Binding var isRefreshing: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = webViewModel.webView
        
        // Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefreshControl), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        
        // Add swipe gesture handlers
        let swipeRight = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe))
        swipeRight.direction = .right
        webView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe))
        swipeLeft.direction = .left
        webView.addGestureRecognizer(swipeLeft)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: RefreshableWebView
        
        init(_ parent: RefreshableWebView) {
            self.parent = parent
        }
        
        @objc func handleRefreshControl(sender: UIRefreshControl) {
            parent.webViewModel.refresh()
            sender.endRefreshing()
        }
        
        @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            if gesture.direction == .right {
                parent.webViewModel.goBack()
            } else if gesture.direction == .left {
                parent.webViewModel.goForward()
            }
        }
    }
}

struct BrowserView_Previews: PreviewProvider {
    static var previews: some View {
        BrowserView()
    }
}
