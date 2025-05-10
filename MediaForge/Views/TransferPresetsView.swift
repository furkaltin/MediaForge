import SwiftUI

/// View to manage and configure transfer presets
struct TransferPresetsView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var selectedPreset: TransferPreset?
    @State private var isAddingNewPreset = false
    @State private var editingPreset: TransferPreset?
    
    @State private var showDeleteAlert = false
    @State private var presetToDelete: TransferPreset?
    
    // Styling
    private let cornerRadius: CGFloat = 15
    private let cardPadding: CGFloat = 16
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            HStack(spacing: 0) {
                // Left side - Preset List
                presetsListView
                    .frame(width: 280)
                
                // Divider
                Divider()
                
                // Right side - Preset Detail
                presetDetailView
                    .padding(cardPadding)
            }
        }
        .sheet(item: $editingPreset) { preset in
            PresetEditView(
                preset: preset,
                onSave: { updatedPreset in
                    viewModel.updatePreset(updatedPreset)
                    editingPreset = nil
                    selectedPreset = updatedPreset
                },
                onCancel: {
                    editingPreset = nil
                }
            )
        }
        .sheet(isPresented: $isAddingNewPreset) {
            PresetEditView(
                preset: TransferPreset(), 
                isNew: true,
                onSave: { newPreset in
                    viewModel.addPreset(newPreset)
                    isAddingNewPreset = false
                    selectedPreset = newPreset
                },
                onCancel: {
                    isAddingNewPreset = false
                }
            )
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Preset"),
                message: Text("Are you sure you want to delete '\(presetToDelete?.name ?? "")'? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let preset = presetToDelete {
                        viewModel.deletePreset(preset)
                        if selectedPreset?.id == preset.id {
                            selectedPreset = viewModel.transferPresets.first
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // Header with title and actions
    private var headerView: some View {
        HStack {
            Text("Transfer Presets")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Spacer()
            
            // Add button
            Button(action: {
                isAddingNewPreset = true
            }) {
                Label("Add Preset", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // Left side list of presets
    private var presetsListView: some View {
        List {
            ForEach(viewModel.transferPresets) { preset in
                presetListItem(preset)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPreset = preset
                    }
            }
            .onDelete { indexSet in
                let presetsToDelete = indexSet.map { viewModel.transferPresets[$0] }
                if let presetToRemove = presetsToDelete.first {
                    presetToDelete = presetToRemove
                    showDeleteAlert = true
                }
            }
        }
        .listStyle(SidebarListStyle())
    }
    
    // Individual preset list item
    private func presetListItem(_ preset: TransferPreset) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(preset.name)
                    .font(.headline)
                
                Text(preset.folderPattern == .custom ? preset.customPattern : preset.folderPattern.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if selectedPreset?.id == preset.id {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(selectedPreset?.id == preset.id ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
    
    // Right side preset details
    private var presetDetailView: some View {
        Group {
            if let preset = selectedPreset {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header with preset name and edit button
                        HStack {
                            Text(preset.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                editingPreset = preset
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // Preset details in cards
                        Group {
                            // Folder pattern
                            detailCard("Folder Pattern", content: {
                                VStack(alignment: .leading) {
                                    Text(preset.folderPattern.description)
                                        .bold()
                                    
                                    if preset.folderPattern == .custom {
                                        Text(preset.customPattern)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("Example: \(preset.createDestinationPath())")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
                                }
                            })
                            
                            // Verification
                            detailCard("Verification", content: {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Image(systemName: "checkmark.shield")
                                            .foregroundColor(.green)
                                        
                                        Text(preset.verificationBehavior.description)
                                            .bold()
                                    }
                                    
                                    Text("Using \(preset.checksumAlgorithm.description)")
                                        .foregroundColor(.secondary)
                                }
                            })
                            
                            // Project info
                            detailCard("Project Information", content: {
                                VStack(alignment: .leading, spacing: 6) {
                                    if !preset.projectName.isEmpty {
                                        detailRow("Project", preset.projectName)
                                    }
                                    
                                    if !preset.cameraMake.isEmpty {
                                        detailRow("Camera", preset.cameraMake)
                                    }
                                    
                                    detailRow("Generate Report", preset.generateReport ? "Yes" : "No")
                                    detailRow("Create MHL", preset.createMHL ? "Yes" : "No")
                                    detailRow("Cascading Copy", preset.isCascadingEnabled ? "Enabled" : "Disabled")
                                }
                            })
                            
                            // Apply preset button
                            Button(action: {
                                viewModel.applyPreset(preset)
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Apply Preset")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .padding(.top, 10)
                        }
                    }
                }
            } else {
                // No preset selected
                VStack {
                    Spacer()
                    Text("Select a preset or create a new one")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }
    
    // Display a detail card with title and custom content
    private func detailCard<Content: View>(_ title: String, content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(cornerRadius)
    }
    
    // Display a detail row with label and value
    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .frame(width: 120, alignment: .leading)
                .foregroundColor(.secondary)
            
            Text(value)
                .bold()
            
            Spacer()
        }
    }
}

/// View for editing or creating a transfer preset
struct PresetEditView: View {
    @ObservedObject var preset: TransferPreset
    var isNew: Bool = false
    var onSave: (TransferPreset) -> Void
    var onCancel: () -> Void
    
    @State private var presetName: String
    @State private var folderPattern: FolderPattern
    @State private var customPattern: String
    @State private var verificationBehavior: VerificationBehavior
    @State private var checksumAlgorithm: ChecksumAlgorithm
    @State private var createMHL: Bool
    @State private var projectName: String
    @State private var cameraMake: String
    @State private var generateReport: Bool
    @State private var isCascadingEnabled: Bool
    
    init(preset: TransferPreset, isNew: Bool = false, onSave: @escaping (TransferPreset) -> Void, onCancel: @escaping () -> Void) {
        self.preset = preset
        self.isNew = isNew
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize state with preset values
        _presetName = State(initialValue: preset.name)
        _folderPattern = State(initialValue: preset.folderPattern)
        _customPattern = State(initialValue: preset.customPattern)
        _verificationBehavior = State(initialValue: preset.verificationBehavior)
        _checksumAlgorithm = State(initialValue: preset.checksumAlgorithm)
        _createMHL = State(initialValue: preset.createMHL)
        _projectName = State(initialValue: preset.projectName)
        _cameraMake = State(initialValue: preset.cameraMake)
        _generateReport = State(initialValue: preset.generateReport)
        _isCascadingEnabled = State(initialValue: preset.isCascadingEnabled)
    }
    
    var body: some View {
        VStack {
            // Header
            Text(isNew ? "Create Preset" : "Edit Preset")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Form {
                // Basic Info
                Section(header: Text("Basic Information")) {
                    TextField("Preset Name", text: $presetName)
                    
                    HStack {
                        Text("Default Project")
                        Spacer()
                        TextField("Project Name", text: $projectName)
                            .frame(width: 200)
                    }
                    
                    HStack {
                        Text("Camera")
                        Spacer()
                        TextField("Camera Make/Model", text: $cameraMake)
                            .frame(width: 200)
                    }
                }
                
                // Folder Structure
                Section(header: Text("Folder Structure")) {
                    Picker("Pattern", selection: $folderPattern) {
                        ForEach(FolderPattern.allCases) { pattern in
                            Text(pattern.description).tag(pattern)
                        }
                    }
                    
                    if folderPattern == .custom {
                        VStack(alignment: .leading) {
                            TextField("Custom Pattern", text: $customPattern)
                                .textFieldStyle(.roundedBorder)
                            
                            Text("Available placeholders: {Date}, {Time}, {Project}, {Camera}")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Example output
                    if !presetName.isEmpty || !projectName.isEmpty || !cameraMake.isEmpty {
                        let examplePath = generateExamplePath()
                        Text("Example: \(examplePath)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Verification
                Section(header: Text("Verification")) {
                    Picker("Method", selection: $verificationBehavior) {
                        ForEach(VerificationBehavior.allCases) { behavior in
                            Text(behavior.description).tag(behavior)
                        }
                    }
                    
                    Picker("Checksum", selection: $checksumAlgorithm) {
                        ForEach(ChecksumAlgorithm.allCases) { algorithm in
                            Text(algorithm.description).tag(algorithm)
                        }
                    }
                    
                    Toggle("Create Media Hash List (MHL)", isOn: $createMHL)
                }
                
                // Advanced Options
                Section(header: Text("Advanced Options")) {
                    Toggle("Generate Transfer Report", isOn: $generateReport)
                    Toggle("Enable Cascading Copy", isOn: $isCascadingEnabled)
                }
            }
            .padding()
            
            // Buttons
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save Preset") {
                    updatePreset()
                    onSave(preset)
                }
                .buttonStyle(.borderedProminent)
                .disabled(presetName.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 550, height: 700)
    }
    
    private func updatePreset() {
        preset.name = presetName
        preset.folderPattern = folderPattern
        preset.customPattern = customPattern
        preset.verificationBehavior = verificationBehavior
        preset.checksumAlgorithm = checksumAlgorithm
        preset.createMHL = createMHL
        preset.projectName = projectName
        preset.cameraMake = cameraMake
        preset.generateReport = generateReport
        preset.isCascadingEnabled = isCascadingEnabled
    }
    
    private func generateExamplePath() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH-mm"
        let currentTime = timeFormatter.string(from: Date())
        
        let project = projectName.isEmpty ? "Untitled" : projectName
        let camera = cameraMake.isEmpty ? "Camera" : cameraMake
        
        switch folderPattern {
        case .dateTime:
            return "\(currentDate)/\(currentTime)"
        case .dateProject:
            return "\(currentDate)/\(project)"
        case .projectDate:
            return "\(project)/\(currentDate)"
        case .cameraDate:
            return "\(camera)/\(currentDate)"
        case .projectCameraCard:
            return "\(project)/\(camera)/Card-\(currentDate)"
        case .custom:
            var pattern = customPattern
            pattern = pattern.replacingOccurrences(of: "{Date}", with: currentDate)
            pattern = pattern.replacingOccurrences(of: "{Time}", with: currentTime)
            pattern = pattern.replacingOccurrences(of: "{Project}", with: project)
            pattern = pattern.replacingOccurrences(of: "{Camera}", with: camera)
            return pattern
        }
    }
} 