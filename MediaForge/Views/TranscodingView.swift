import SwiftUI

/// View for managing and using transcoding profiles
struct TranscodingView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var showingProfileEditor = false
    @State private var editingProfile: TranscodingProfile?
    @State private var selectedProfile: UUID?
    @State private var showingFileImporter = false
    @State private var selectedSourceFiles: [URL] = []
    @State private var isTranscoding = false
    @State private var transcodingProgress: Double = 0
    @State private var showTranscodingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Transcoding")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    // Create new profile
                    editingProfile = TranscodingProfile()
                    showingProfileEditor = true
                }) {
                    Label("New Profile", systemImage: "plus")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Two-column layout
            HStack(spacing: 0) {
                // Profiles sidebar
                VStack(alignment: .leading, spacing: 0) {
                    Text("Profiles")
                        .font(.headline)
                        .padding()
                    
                    Divider()
                    
                    // Profile list
                    List(viewModel.transcodingProfiles) { profile in
                        HStack {
                            // Profile icon based on format
                            Image(systemName: iconForFormat(profile.outputFormat))
                                .foregroundColor(colorForFormat(profile.outputFormat))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                    .fontWeight(selectedProfile == profile.id ? .bold : .regular)
                                
                                Text(profile.outputFormat.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProfile = profile.id
                            viewModel.activeTranscodingProfile = profile
                        }
                        .contextMenu {
                            Button("Edit Profile") {
                                editingProfile = profile
                                showingProfileEditor = true
                            }
                            
                            Button("Duplicate Profile") {
                                duplicateProfile(profile)
                            }
                            
                            Divider()
                            
                            Button("Delete Profile") {
                                viewModel.removeTranscodingProfile(profile)
                                if selectedProfile == profile.id {
                                    selectedProfile = nil
                                    viewModel.activeTranscodingProfile = nil
                                }
                            }
                        }
                        .background(selectedProfile == profile.id ? Color.blue.opacity(0.1) : Color.clear)
                    }
                }
                .frame(width: 250)
                .background(Color(NSColor.windowBackgroundColor))
                .border(Color.gray.opacity(0.2), width: 1)
                
                // Main content area
                VStack {
                    if let selectedProfile = viewModel.activeTranscodingProfile {
                        // Profile details and transcode UI
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Profile overview card
                                profileOverview(selectedProfile)
                                
                                // Source file selector
                                sourceFileSelector
                                
                                // Transcoding settings card
                                if !selectedSourceFiles.isEmpty {
                                    transcodingSettingsCard(selectedProfile)
                                }
                                
                                // Start transcoding button
                                if !selectedSourceFiles.isEmpty {
                                    startTranscodingButton
                                }
                                
                                // Progress if transcoding
                                if isTranscoding {
                                    transcodingProgressView
                                }
                            }
                            .padding()
                        }
                    } else {
                        // No profile selected
                        VStack(spacing: 16) {
                            Image(systemName: "film")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("Select or create a transcoding profile")
                                .font(.headline)
                            
                            Button("Create New Profile") {
                                editingProfile = TranscodingProfile()
                                showingProfileEditor = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .sheet(isPresented: $showingProfileEditor) {
            if let profile = editingProfile {
                TranscodingProfileEditor(viewModel: viewModel, profile: profile, isNew: profile.name == "New Transcoding Profile")
            }
        }
    }
    
    /// Profile overview card
    private func profileOverview(_ profile: TranscodingProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(profile.name)
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button(action: {
                    editingProfile = profile
                    showingProfileEditor = true
                }) {
                    Image(systemName: "pencil")
                }
            }
            
            Divider()
            
            // Format & Resolution
            HStack(spacing: 30) {
                VStack(alignment: .leading) {
                    Text("Format")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: iconForFormat(profile.outputFormat))
                            .foregroundColor(colorForFormat(profile.outputFormat))
                        
                        Text(profile.outputFormat.rawValue)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Resolution")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(resolutionText(for: profile))
                }
            }
            
            // Settings Summary
            HStack(spacing: 30) {
                if profile.applyLUT {
                    HStack {
                        Image(systemName: "photo.artframe")
                            .foregroundColor(.orange)
                        
                        Text("LUT Applied")
                    }
                }
                
                if profile.burnInOptions.burnInType != .none {
                    HStack {
                        Image(systemName: "text.below.photo")
                            .foregroundColor(.blue)
                        
                        Text("Burn-in: \(profile.burnInOptions.burnInType.rawValue)")
                    }
                }
                
                if profile.applyFrameLines {
                    HStack {
                        Image(systemName: "rectangle.dashed")
                            .foregroundColor(.green)
                        
                        Text("Frame Lines: \(profile.frameLineAspectRatio)")
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    /// Source file selector
    private var sourceFileSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Source Files")
                .font(.headline)
            
            if selectedSourceFiles.isEmpty {
                Button(action: {
                    showingFileImporter = true // This would need real implementation
                    
                    // For testing, add some sample files
                    selectedSourceFiles = [
                        URL(fileURLWithPath: "/Users/user/Movies/test_clip.mov"),
                        URL(fileURLWithPath: "/Users/user/Movies/interview.mp4")
                    ]
                }) {
                    HStack {
                        Image(systemName: "plus")
                        
                        Text("Add Source Files")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(selectedSourceFiles, id: \.self) { url in
                        HStack {
                            Image(systemName: "film")
                                .foregroundColor(.blue)
                            
                            Text(url.lastPathComponent)
                            
                            Spacer()
                            
                            Button(action: {
                                selectedSourceFiles.removeAll(where: { $0 == url })
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    Button(action: {
                        selectedSourceFiles = []
                    }) {
                        Text("Clear All")
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    /// Transcoding settings card
    private func transcodingSettingsCard(_ profile: TranscodingProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transcoding Settings")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showTranscodingSettings.toggle()
                }) {
                    Image(systemName: showTranscodingSettings ? "chevron.up" : "chevron.down")
                }
            }
            
            if showTranscodingSettings {
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Output path
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Output Path")
                            .font(.subheadline)
                        
                        HStack {
                            Text(profile.destinationPath.isEmpty ? "Same as source" : profile.destinationPath)
                                .foregroundColor(profile.destinationPath.isEmpty ? .secondary : .primary)
                            
                            Spacer()
                            
                            Button(action: {
                                // Show folder picker
                            }) {
                                Text("Browse...")
                            }
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    // Filename pattern
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filename Pattern")
                            .font(.subheadline)
                        
                        TextField("Filename pattern", text: Binding(
                            get: { profile.filenamePattern },
                            set: { profile.filenamePattern = $0 }
                        ))
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    // File handling
                    HStack(spacing: 30) {
                        Toggle("Overwrite existing files", isOn: Binding(
                            get: { profile.overwriteExisting },
                            set: { profile.overwriteExisting = $0 }
                        ))
                        
                        Toggle("Create subfolders", isOn: Binding(
                            get: { profile.createSubfolders },
                            set: { profile.createSubfolders = $0 }
                        ))
                    }
                    
                    // Subfolder pattern if enabled
                    if profile.createSubfolders {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subfolder Pattern")
                                .font(.subheadline)
                            
                            TextField("Subfolder pattern", text: Binding(
                                get: { profile.subfolderPattern },
                                set: { profile.subfolderPattern = $0 }
                            ))
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    /// Start transcoding button
    private var startTranscodingButton: some View {
        Button(action: {
            isTranscoding = true
            transcodingProgress = 0
            
            // Simulate transcoding progress
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                transcodingProgress += 0.1
                if transcodingProgress >= 1.0 {
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isTranscoding = false
                        transcodingProgress = 0
                    }
                }
            }
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Transcoding")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(isTranscoding)
    }
    
    /// Transcoding progress view
    private var transcodingProgressView: some View {
        VStack(spacing: 12) {
            ProgressView(value: transcodingProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
            
            HStack {
                Text("Transcoding \(Int(transcodingProgress * 100))%")
                
                Spacer()
                
                Button(action: {
                    isTranscoding = false
                    transcodingProgress = 0
                }) {
                    Text("Cancel")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    /// Get icon for output format
    private func iconForFormat(_ format: TranscodingProfile.OutputFormat) -> String {
        switch format {
        case .prores422, .prores422HQ, .prores422LT, .prores4444, .proresProxy:
            return "apple"
        case .h264, .h265:
            return "film"
        case .dnxhd, .dnxhr:
            return "a.square"
        }
    }
    
    /// Get color for output format
    private func colorForFormat(_ format: TranscodingProfile.OutputFormat) -> Color {
        switch format {
        case .prores422, .prores422HQ, .prores422LT, .prores4444, .proresProxy:
            return .blue
        case .h264, .h265:
            return .green
        case .dnxhd, .dnxhr:
            return .purple
        }
    }
    
    /// Get resolution text for profile
    private func resolutionText(for profile: TranscodingProfile) -> String {
        switch profile.resolutionPreset {
        case .custom:
            return "\(profile.customWidth)×\(profile.customHeight)"
        case .original:
            return "Original Resolution"
        case .quarterRes:
            return "Quarter Resolution"
        case .halfRes:
            return "Half Resolution"
        default:
            if let dimensions = profile.resolutionPreset.dimensions {
                return "\(dimensions.width)×\(dimensions.height)"
            } else {
                return profile.resolutionPreset.rawValue
            }
        }
    }
    
    /// Duplicate a profile
    private func duplicateProfile(_ profile: TranscodingProfile) {
        let newProfile = TranscodingProfile(name: "\(profile.name) Copy")
        
        // Copy all properties
        newProfile.outputFormat = profile.outputFormat
        newProfile.resolutionPreset = profile.resolutionPreset
        newProfile.customWidth = profile.customWidth
        newProfile.customHeight = profile.customHeight
        newProfile.fittingStrategy = profile.fittingStrategy
        newProfile.frameRate = profile.frameRate
        newProfile.decodingQuality = profile.decodingQuality
        newProfile.preserveColorDepth = profile.preserveColorDepth
        newProfile.quality = profile.quality
        newProfile.audioBitrate = profile.audioBitrate
        newProfile.lookSource = profile.lookSource
        newProfile.applyLUT = profile.applyLUT
        newProfile.lutURL = profile.lutURL
        newProfile.burnInOptions = profile.burnInOptions
        newProfile.applyFrameLines = profile.applyFrameLines
        newProfile.frameLineAspectRatio = profile.frameLineAspectRatio
        newProfile.frameLinesAppearance = profile.frameLinesAppearance
        newProfile.destinationPath = profile.destinationPath
        newProfile.filenamePattern = profile.filenamePattern
        newProfile.overwriteExisting = profile.overwriteExisting
        newProfile.createSubfolders = profile.createSubfolders
        newProfile.subfolderPattern = profile.subfolderPattern
        newProfile.metadataExportFormat = profile.metadataExportFormat
        
        viewModel.addTranscodingProfile(newProfile)
    }
}

/// Editor for transcoding profiles
struct TranscodingProfileEditor: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @ObservedObject var profile: TranscodingProfile
    var isNew: Bool
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isNew ? "New Transcoding Profile" : "Edit Profile")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Button(isNew ? "Create" : "Save") {
                    if isNew {
                        viewModel.addTranscodingProfile(profile)
                    } else {
                        viewModel.updateTranscodingProfile(profile)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Profile name field
            TextField("Profile Name", text: $profile.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .padding(.bottom)
            
            // Tab view for different sections
            TabView(selection: $selectedTab) {
                // Format & Resolution tab
                formatAndResolutionTab
                    .tabItem {
                        Label("Format", systemImage: "film")
                    }
                    .tag(0)
                
                // Quality tab
                qualityTab
                    .tabItem {
                        Label("Quality", systemImage: "gauge")
                    }
                    .tag(1)
                
                // Color & LUTs tab
                colorAndLutsTab
                    .tabItem {
                        Label("Color", systemImage: "photo.artframe")
                    }
                    .tag(2)
                
                // Burn-In tab
                burnInTab
                    .tabItem {
                        Label("Burn-In", systemImage: "text.below.photo")
                    }
                    .tag(3)
                
                // Output tab
                outputTab
                    .tabItem {
                        Label("Output", systemImage: "folder")
                    }
                    .tag(4)
            }
            .tabViewStyle(DefaultTabViewStyle())
            .frame(width: 600, height: 500)
        }
        .frame(width: 600)
        .padding(.bottom)
    }
    
    // Format & Resolution tab
    var formatAndResolutionTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Output Format
                VStack(alignment: .leading, spacing: 8) {
                    Text("Output Format")
                        .font(.headline)
                    
                    Picker("", selection: $profile.outputFormat) {
                        ForEach(TranscodingProfile.OutputFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                }
                
                Divider()
                
                // Resolution
                VStack(alignment: .leading, spacing: 8) {
                    Text("Resolution")
                        .font(.headline)
                    
                    Picker("", selection: $profile.resolutionPreset) {
                        ForEach(TranscodingProfile.ResolutionPreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    
                    if profile.resolutionPreset == .custom {
                        HStack {
                            TextField("Width", value: $profile.customWidth, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("×")
                            
                            TextField("Height", value: $profile.customHeight, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.top, 8)
                    }
                }
                
                Divider()
                
                // Fitting Strategy
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fitting Strategy")
                        .font(.headline)
                    
                    Picker("", selection: $profile.fittingStrategy) {
                        ForEach(TranscodingProfile.FittingStrategy.allCases) { strategy in
                            Text(strategy.rawValue).tag(strategy)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                }
                
                Divider()
                
                // Frame Rate
                VStack(alignment: .leading, spacing: 8) {
                    Text("Frame Rate")
                        .font(.headline)
                    
                    HStack {
                        // "Same as source" toggle
                        Toggle("Same as source", isOn: Binding(
                            get: { profile.frameRate == nil },
                            set: { if $0 { profile.frameRate = nil } else { profile.frameRate = 24.0 } }
                        ))
                        
                        if profile.frameRate != nil {
                            Picker("", selection: Binding(
                                get: { profile.frameRate ?? 24.0 },
                                set: { profile.frameRate = $0 }
                            )) {
                                Text("23.976").tag(23.976)
                                Text("24").tag(24.0)
                                Text("25").tag(25.0)
                                Text("29.97").tag(29.97)
                                Text("30").tag(30.0)
                                Text("50").tag(50.0)
                                Text("59.94").tag(59.94)
                                Text("60").tag(60.0)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // Quality tab
    var qualityTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Decoding Quality
                VStack(alignment: .leading, spacing: 8) {
                    Text("Decoding Quality")
                        .font(.headline)
                    
                    Picker("", selection: $profile.decodingQuality) {
                        ForEach(TranscodingProfile.DecodingQuality.allCases) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                }
                
                Divider()
                
                // Color Depth
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color Depth")
                        .font(.headline)
                    
                    Toggle("Preserve original color depth", isOn: $profile.preserveColorDepth)
                }
                
                Divider()
                
                // Quality (for H.264/H.265)
                if profile.outputFormat == .h264 || profile.outputFormat == .h265 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quality")
                            .font(.headline)
                        
                        HStack {
                            Text("Low")
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { Double(profile.quality) },
                                set: { profile.quality = Int($0) }
                            ), in: 1...100, step: 1)
                            
                            Text("High")
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Quality: \(profile.quality)%")
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                }
                
                // Audio Bitrate
                VStack(alignment: .leading, spacing: 8) {
                    Text("Audio Bitrate")
                        .font(.headline)
                    
                    Picker("", selection: Binding(
                        get: { profile.audioBitrate },
                        set: { profile.audioBitrate = $0 }
                    )) {
                        Text("128 kbps").tag(128)
                        Text("192 kbps").tag(192)
                        Text("256 kbps").tag(256)
                        Text("320 kbps").tag(320)
                        Text("384 kbps").tag(384)
                        Text("448 kbps").tag(448)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .padding()
        }
    }
    
    // Color & LUTs tab
    var colorAndLutsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Look Source
                VStack(alignment: .leading, spacing: 8) {
                    Text("Look Source")
                        .font(.headline)
                    
                    Picker("", selection: $profile.lookSource) {
                        ForEach(TranscodingProfile.LookSource.allCases) { source in
                            Text(source.rawValue).tag(source)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                }
                
                Divider()
                
                // LUT Application
                VStack(alignment: .leading, spacing: 8) {
                    Text("LUT")
                        .font(.headline)
                    
                    Toggle("Apply LUT", isOn: $profile.applyLUT)
                    
                    if profile.applyLUT {
                        HStack {
                            Text(profile.lutURL?.lastPathComponent ?? "No LUT selected")
                                .foregroundColor(profile.lutURL == nil ? .secondary : .primary)
                            
                            Spacer()
                            
                            Button("Browse...") {
                                // Would show file picker
                            }
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            .padding()
        }
    }
    
    // Burn-In tab
    var burnInTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Burn-In Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Burn-In Type")
                        .font(.headline)
                    
                    Picker("", selection: Binding(
                        get: { profile.burnInOptions.burnInType },
                        set: { profile.burnInOptions.burnInType = $0 }
                    )) {
                        ForEach(BurnInOptions.BurnInType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    
                    if profile.burnInOptions.burnInType == .customText {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Custom Text")
                                .font(.subheadline)
                            
                            TextField("Custom text", text: Binding(
                                get: { profile.burnInOptions.customText },
                                set: { profile.burnInOptions.customText = $0 }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Available wildcards: $clipname$, $timecode$, $scene$, $take$, etc.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                
                if profile.burnInOptions.burnInType != .none {
                    Divider()
                    
                    // Burn-In Appearance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Appearance")
                            .font(.headline)
                        
                        // Position
                        HStack {
                            Text("Position:")
                            
                            Picker("", selection: Binding(
                                get: { profile.burnInOptions.alignment },
                                set: { profile.burnInOptions.alignment = $0 }
                            )) {
                                ForEach(BurnInOptions.TextAlignment.allCases) { alignment in
                                    Text(alignment.rawValue).tag(alignment)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        // Background Style
                        HStack {
                            Text("Background:")
                            
                            Picker("", selection: Binding(
                                get: { profile.burnInOptions.backgroundStyle },
                                set: { profile.burnInOptions.backgroundStyle = $0 }
                            )) {
                                ForEach(BurnInOptions.BackgroundStyle.allCases) { style in
                                    Text(style.rawValue).tag(style)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        // Font size
                        HStack {
                            Text("Size: \(Int(profile.burnInOptions.fontSize))")
                            
                            Slider(value: Binding(
                                get: { profile.burnInOptions.fontSize },
                                set: { profile.burnInOptions.fontSize = $0 }
                            ), in: 10...40, step: 1)
                        }
                    }
                }
                
                Divider()
                
                // Frame Lines
                VStack(alignment: .leading, spacing: 8) {
                    Text("Frame Lines")
                        .font(.headline)
                    
                    Toggle("Apply frame lines", isOn: $profile.applyFrameLines)
                    
                    if profile.applyFrameLines {
                        HStack {
                            Text("Aspect Ratio:")
                            
                            Picker("", selection: $profile.frameLineAspectRatio) {
                                ForEach(["1.85:1", "2.35:1", "2.39:1", "16:9", "4:3"], id: \.self) { ratio in
                                    Text(ratio).tag(ratio)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        HStack {
                            Text("Appearance:")
                            
                            Picker("", selection: $profile.frameLinesAppearance) {
                                ForEach(TranscodingProfile.FrameLinesAppearance.allCases) { appearance in
                                    Text(appearance.rawValue).tag(appearance)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // Output tab
    var outputTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Destination
                VStack(alignment: .leading, spacing: 8) {
                    Text("Destination Path")
                        .font(.headline)
                    
                    HStack {
                        Text(profile.destinationPath.isEmpty ? "Same folder as source" : profile.destinationPath)
                            .foregroundColor(profile.destinationPath.isEmpty ? .secondary : .primary)
                        
                        Spacer()
                        
                        Button("Browse...") {
                            // Would show folder picker
                        }
                        
                        if !profile.destinationPath.isEmpty {
                            Button("Clear") {
                                profile.destinationPath = ""
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Divider()
                
                // Filename Pattern
                VStack(alignment: .leading, spacing: 8) {
                    Text("Filename Pattern")
                        .font(.headline)
                    
                    TextField("Pattern", text: $profile.filenamePattern)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Available wildcards: {source_filename}, {date}, {preset}, {resolution}, etc.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // File Handling
                VStack(alignment: .leading, spacing: 8) {
                    Text("File Handling")
                        .font(.headline)
                    
                    Toggle("Overwrite existing files", isOn: $profile.overwriteExisting)
                    Toggle("Create subfolders", isOn: $profile.createSubfolders)
                    
                    if profile.createSubfolders {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Subfolder Pattern")
                                .font(.subheadline)
                            
                            TextField("Pattern", text: $profile.subfolderPattern)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Example: {date}/{scene}")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                
                Divider()
                
                // Metadata Export
                VStack(alignment: .leading, spacing: 8) {
                    Text("Metadata Export")
                        .font(.headline)
                    
                    Picker("", selection: $profile.metadataExportFormat) {
                        ForEach(TranscodingProfile.MetadataExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                }
            }
            .padding()
        }
    }
}

struct TranscodingView_Previews: PreviewProvider {
    static var previews: some View {
        TranscodingView(viewModel: MediaForgeViewModel())
    }
} 