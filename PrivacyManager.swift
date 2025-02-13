import WebKit
import Combine

class PrivacyManager: ObservableObject {
    @Published var isAdBlockingEnabled = true
    @Published var blockedTrackerCount = 0
    
    private var contentRuleList: WKContentRuleList?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadContentRuleList()
    }
    
    private func loadContentRuleList() {
        // Basic ruleset to block common ad/tracker domains
        let rules = """
        [
            {
                "trigger": {
                    "url-filter": ".*",
                    "if-domain": ["*doubleclick.net", "*google-analytics.com", "*facebook.com", "*adnxs.com"]
                },
                "action": { "type": "block" }
            },
            {
                "trigger": {
                    "url-filter": ".*",
                    "resource-type": ["script", "image"],
                    "if-domain": ["*analytics.*", "*tracker.*", "*pixel.*", "*ads.*"]
                },
                "action": { "type": "block" }
            },
            {
                "trigger": {
                    "url-filter": ".*",
                    "resource-type": ["script"],
                    "if-domain": ["*track.*", "*stats.*", "*metric.*"]
                },
                "action": { "type": "block" }
            }
        ]
        """
        
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "ad-blocking-rules",
            encodedContentRuleList: rules) { [weak self] ruleList, error in
                guard let ruleList = ruleList, error == nil else {
                    print("Error compiling rule list: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                DispatchQueue.main.async {
                    self?.contentRuleList = ruleList
                }
            }
    }
    
    func configureWebView(_ webView: WKWebView) {
        guard isAdBlockingEnabled, let ruleList = contentRuleList else { return }
        
        webView.configuration.userContentController.add(ruleList)
        
        // Monitor network requests to count blocked trackers
        let script = WKUserScript(source: """
            window.addEventListener('error', function(e) {
                if (e.target instanceof HTMLImageElement || e.target instanceof HTMLScriptElement) {
                    window.webkit.messageHandlers.trackerBlocked.postMessage({url: e.target.src});
                }
            }, true);
        """, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        
        webView.configuration.userContentController.addUserScript(script)
    }
    
    func removeContentRules(from webView: WKWebView) {
        webView.configuration.userContentController.removeAllContentRuleLists()
    }
    
    func handleTrackerBlocked() {
        DispatchQueue.main.async {
            self.blockedTrackerCount += 1
        }
    }
    
    func resetBlockedCount() {
        blockedTrackerCount = 0
    }
}
