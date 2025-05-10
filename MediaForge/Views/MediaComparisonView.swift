import SwiftUI
import AVKit

/// A professional media comparison tool for side-by-side analysis
struct MediaComparisonView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var primaryItem: CatalogItem
    @State private var secondaryItem: CatalogItem?
    
    // UI States
    @State private var comparisonMode: ComparisonMode = .sideBySide
    @State private var syncPlayback: Bool = true
    @State private var showDifference: Bool = false
    @State private var showWaveform: Bool = false
    @State private var showVectorscope: Bool = false
    @State private var showHistogram: Bool = false
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0
    @State private var zoomLevel: Double = 1.0
    @State private var splitPosition: Double = 0.5
    
    // Comparison modes
    enum ComparisonMode: String, CaseIterable, Identifiable {
        case sideBySide = "Side by Side"
        case splitScreen = "Split Screen"
        case overlay = "Overlay"
        case difference = "Difference"
        
        var id: String { self.rawValue }
    }
    
    init(viewModel: MediaForgeViewModel, primaryItem: CatalogItem, secondaryItem: CatalogItem? = nil) {
        self.viewModel = viewModel
        self._primaryItem = State(initialValue: primaryItem)
        self._secondaryItem = State(initialValue: secondaryItem)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Media Comparison")
                    .font(.headline)
                
                Spacer()
                
                // Mode selector
                Picker("Mode", selection: $comparisonMode) {
                    ForEach(ComparisonMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 350)
                
                // Visualization toggles
                Toggle("Waveform", isOn: $showWaveform)
                    .toggleStyle(ButtonToggleStyle())
                    .padding(.horizontal, 8)
                
                Toggle("Vectorscope", isOn: $showVectorscope)
                    .toggleStyle(ButtonToggleStyle())
                    .padding(.horizontal, 8)
                
                Toggle("Histogram", isOn: $showHistogram)
                    .toggleStyle(ButtonToggleStyle())
                    .padding(.horizontal, 8)
                
                if comparisonMode == .overlay {
                    Toggle("Show Diff", isOn: $showDifference)
                        .toggleStyle(ButtonToggleStyle())
                        .padding(.horizontal, 8)
                }
                
                if secondaryItem != nil {
                    Toggle("Sync Playback", isOn: $syncPlayback)
                        .toggleStyle(ButtonToggleStyle())
                        .padding(.horizontal, 8)
                }
                
                Button(action: {
                    // Export comparison
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.horizontal, 8)
            }
            .padding()
            .background(Color.black.opacity(0.2))
            
            // Main content area
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Media display area
                    ZStack {
                        // Background
                        Color.black
                        
                        // Media display based on mode
                        switch comparisonMode {
                        case .sideBySide:
                            sideBySideView(width: geometry.size.width, height: geometry.size.height)
                        case .splitScreen:
                            splitScreenView(width: geometry.size.width, height: geometry.size.height)
                        case .overlay:
                            overlayView(width: geometry.size.width, height: geometry.size.height)
                        case .difference:
                            differenceView(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
            }
            
            // Bottom controls
            VStack(spacing: 0) {
                // Waveform/visualization display
                if showWaveform || showVectorscope || showHistogram {
                    visualizationPanel
                        .frame(height: 120)
                        .background(Color.black.opacity(0.15))
                }
                
                // Playback controls
                HStack {
                    // Current time
                    Text(formatTimecode(seconds: currentTime))
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 100)
                    
                    // Transport controls
                    HStack(spacing: 16) {
                        Button(action: {
                            // Previous frame
                            currentTime -= 1/30 // Assuming 30fps
                        }) {
                            Image(systemName: "backward.frame")
                                .font(.system(size: 18))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button(action: {
                            isPlaying.toggle()
                        }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 30))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button(action: {
                            // Next frame
                            currentTime += 1/30 // Assuming 30fps
                        }) {
                            Image(systemName: "forward.frame")
                                .font(.system(size: 18))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    // Zoom control
                    Slider(value: $zoomLevel, in: 0.5...5.0)
                        .frame(width: 150)
                        .padding(.horizontal)
                    
                    Text("Zoom: \(Int(zoomLevel * 100))%")
                        .font(.caption)
                        .frame(width: 80)
                    
                    Spacer()
                    
                    // Duration
                    if let duration = primaryItem.duration {
                        Text(formatTimecode(seconds: duration))
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 100)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - View Layouts
    
    // Side-by-side comparison
    func sideBySideView(width: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: 1) {
            // Primary media
            mediaPreviewView(for: primaryItem, width: width/2, height: height)
            
            // Secondary media (if available)
            if let secondaryItem = secondaryItem {
                mediaPreviewView(for: secondaryItem, width: width/2, height: height)
            } else {
                placeholderView(width: width/2, height: height)
            }
        }
    }
    
    // Split screen comparison
    func splitScreenView(width: CGFloat, height: CGFloat) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Primary media (full width)
                mediaPreviewView(for: primaryItem, width: width, height: height)
                
                // Secondary media (partial width based on split position)
                if let secondaryItem = secondaryItem {
                    mediaPreviewView(for: secondaryItem, width: width, height: height)
                        .frame(width: geometry.size.width * splitPosition)
                        .clipped()
                }
                
                // Split line with drag handle
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .position(x: geometry.size.width * splitPosition, y: geometry.size.height/2)
                
                // Drag handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .position(x: geometry.size.width * splitPosition, y: geometry.size.height/2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPosition = value.location.x / geometry.size.width
                                splitPosition = min(max(0.1, newPosition), 0.9)
                            }
                    )
            }
        }
    }
    
    // Overlay comparison
    func overlayView(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Primary media
            mediaPreviewView(for: primaryItem, width: width, height: height)
            
            // Secondary media (if available)
            if let secondaryItem = secondaryItem {
                mediaPreviewView(for: secondaryItem, width: width, height: height)
                    .opacity(showDifference ? 0.5 : 0.3) // Lower opacity for overlay
            }
        }
    }
    
    // Visual difference comparison
    func differenceView(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Primary media
            mediaPreviewView(for: primaryItem, width: width, height: height)
            
            // This would use a Core Image difference filter in a real implementation
            // Here we're just showing a placeholder for the concept
            if let _ = secondaryItem {
                Text("Difference visualization would appear here")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
            }
        }
    }
    
    // Media preview with frame markers
    func mediaPreviewView(for item: CatalogItem, width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Media would be displayed here using AVKit in a real implementation
            // This is just a placeholder visualization
            VStack {
                Rectangle()
                    .fill(item.type.contains("video") ? Color.blue.opacity(0.2) : 
                          item.type.contains("audio") ? Color.purple.opacity(0.2) : 
                          Color.green.opacity(0.2))
                    .overlay(
                        VStack {
                            Text(item.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if let resolution = item.resolution {
                                Text(resolution)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            if item.type.contains("video") {
                                // Video placeholder
                                Image(systemName: "film")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.3))
                            } else if item.type.contains("audio") {
                                // Audio placeholder
                                Image(systemName: "waveform")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.3))
                            } else {
                                // Image placeholder
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                    )
                
                // Timecode overlay
                Text(formatTimecode(seconds: currentTime))
                    .font(.system(size: 14, design: .monospaced))
                    .padding(6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
                    .foregroundColor(.white)
                    .padding([.bottom, .trailing], 8)
                    .frame(maxWidth: .infinity, maxHeight: 30, alignment: .trailing)
            }
        }
        .frame(width: width, height: height)
    }
    
    // Placeholder for when no secondary item is selected
    func placeholderView(width: CGFloat, height: CGFloat) -> some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "plus.rectangle.on.rectangle")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("Select a clip to compare")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                
                Button("Select Media") {
                    // Open media picker
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .frame(width: width, height: height)
        .background(Color.black.opacity(0.4))
    }
    
    // Media visualization panel (waveform, vectorscope, histogram)
    var visualizationPanel: some View {
        HStack(spacing: 0) {
            if showWaveform {
                waveformView
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }
            
            if showVectorscope {
                vectorscopeView
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }
            
            if showHistogram {
                histogramView
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // Audio waveform visualization
    var waveformView: some View {
        VStack {
            Text("Waveform")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Simulated waveform display
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let midHeight = height / 2
                    
                    // Drawing start point
                    path.move(to: CGPoint(x: 0, y: midHeight))
                    
                    // Generate random waveform points for visualization
                    // In a real app, this would use actual audio data
                    for i in 0..<Int(width) {
                        let x = CGFloat(i)
                        let angle = Double(i) / 10.0
                        let amplitude = CGFloat(sin(angle) * 0.3 + cos(angle * 2) * 0.2) // Simulated wave
                        let y = midHeight + amplitude * midHeight * 0.8
                        
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.green, lineWidth: 1.5)
            }
        }
    }
    
    // Video vectorscope visualization
    var vectorscopeView: some View {
        VStack {
            Text("Vectorscope")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Simulated vectorscope display
            ZStack {
                // Background circles
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: 75, height: 75)
                
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: 25, height: 25)
                
                // Color markers (a real vectorscope would show color distribution)
                ForEach(0..<24) { i in
                    let angle = Double(i) * .pi / 12
                    let radius: CGFloat = 45
                    let x = cos(angle) * radius
                    let y = sin(angle) * radius
                    
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 2, height: 2)
                        .position(x: x + 50, y: y + 50)
                }
                
                // Color blobs (simulated)
                ForEach(0..<5) { i in
                    let angle = Double(i) * .pi / 2.5 + 0.3
                    let radius: CGFloat = Double.random(in: 10...40)
                    let x = cos(angle) * radius
                    let y = sin(angle) * radius
                    
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: CGFloat.random(in: 5...15), 
                               height: CGFloat.random(in: 5...15))
                        .blur(radius: 3)
                        .position(x: x + 50, y: y + 50)
                }
                
                // Center crosshair
                Path { path in
                    path.move(to: CGPoint(x: 45, y: 50))
                    path.addLine(to: CGPoint(x: 55, y: 50))
                    path.move(to: CGPoint(x: 50, y: 45))
                    path.addLine(to: CGPoint(x: 50, y: 55))
                }
                .stroke(Color.white, lineWidth: 1)
            }
            .frame(width: 100, height: 100)
            .padding()
        }
    }
    
    // Video histogram visualization
    var histogramView: some View {
        VStack {
            Text("Histogram")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Simulated histogram display
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 0) {
                    // Generate random histogram bars for visualization
                    // In a real app, this would use actual video frame data
                    ForEach(0..<100) { i in
                        let heightMultiplier = Double.random(in: 0...1.0) * (sin(Double(i) / 15) * 0.5 + 0.5)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: geometry.size.width / 100, 
                                   height: geometry.size.height * CGFloat(heightMultiplier))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Format seconds as timecode (HH:MM:SS:FF)
    func formatTimecode(seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        let frames = Int((seconds - Double(Int(seconds))) * 30) // Assuming 30fps
        
        return String(format: "%02d:%02d:%02d:%02d", hours, minutes, secs, frames)
    }
} 