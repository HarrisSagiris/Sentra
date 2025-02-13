import SwiftUI
import OpenAI
import AVFoundation

class AISearchManager: ObservableObject {
    private let openAI = OpenAI(apiToken: "YOUR_API_KEY")
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    
    @Published var isProcessing = false
    @Published var searchResults: [SearchResult] = []
    @Published var aiSummary: String = ""
    @Published var isListening = false
    
    struct SearchResult: Identifiable {
        let id = UUID()
        let title: String
        let snippet: String
        let url: String
    }
    
    func performAISearch(query: String) async {
        isProcessing = true
        
        // Generate AI summary of query
        do {
            let prompt = "Summarize this search query and provide key insights: \(query)"
            let response = try await openAI.completions.create(
                model: .gpt4,
                prompt: prompt,
                maxTokens: 150
            )
            
            DispatchQueue.main.async {
                self.aiSummary = response.choices.first?.text ?? ""
            }
        } catch {
            print("OpenAI API error: \(error)")
        }
        
        // Fetch and analyze search results
        // Note: Implementation would need Google Custom Search API integration
        
        isProcessing = false
    }
    
    func startVoiceRecognition() {
        guard let recognizer = speechRecognizer,
              recognizer.isAvailable else {
            return
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            // Process audio buffer
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        isListening = true
    }
    
    func stopVoiceRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isListening = false
    }
}

struct AISearchView: View {
    @StateObject private var searchManager = AISearchManager()
    @State private var searchQuery = ""
    
    var body: some View {
        VStack {
            // Search input
            HStack {
                TextField("Ask anything...", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if searchManager.isListening {
                        searchManager.stopVoiceRecognition()
                    } else {
                        searchManager.startVoiceRecognition()
                    }
                }) {
                    Image(systemName: searchManager.isListening ? "waveform.circle.fill" : "mic.circle")
                        .font(.title)
                        .foregroundColor(searchManager.isListening ? .red : .blue)
                }
            }
            .padding()
            
            // Results view
            ScrollView {
                if searchManager.isProcessing {
                    ProgressView()
                        .padding()
                }
                
                // AI Summary
                if !searchManager.aiSummary.isEmpty {
                    VStack(alignment: .leading) {
                        Text("AI Summary")
                            .font(.headline)
                        Text(searchManager.aiSummary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding()
                }
                
                // Search Results
                ForEach(searchManager.searchResults) { result in
                    SearchResultView(result: result)
                }
            }
        }
    }
}

struct SearchResultView: View {
    let result: AISearchManager.SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.title)
                .font(.headline)
            Text(result.snippet)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Link(result.url, destination: URL(string: result.url)!)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

#Preview {
    AISearchView()
}
