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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            
            Spacer()
            
            // Add button
            Button(action: {
                isAddingNewPreset = true
            }) {
                Label("Add Preset", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(GlassButtonStyle())
            .padding(.horizontal)
        }
        .frame(height: 60)
        .padding(.vertical, 0)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // Left side list of presets
    private var presetsListView: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                Text("Search Presets")
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            .cornerRadius(8)
            .padding(10)
            
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
            .background(Color.clear)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
    }
    
    // Individual preset list item
    private func presetListItem(_ preset: TransferPreset) -> some View {
        HStack(spacing: 12) {
            // Icon for preset type
            ZStack {
                Circle()
                    .fill(selectedPreset?.id == preset.id ? 
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : 
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: getPresetIcon(preset))
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedPreset?.id == preset.id ? .white : .white.opacity(0.9))
                
                Text(preset.folderPattern == .custom ? preset.customPattern : preset.folderPattern.description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if selectedPreset?.id == preset.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(selectedPreset?.id == preset.id ? 
                    Color.blue.opacity(0.15) : 
                    Color.clear)
                .shadow(color: selectedPreset?.id == preset.id ? Color.blue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    // Helper function to get appropriate icon for preset
    private func getPresetIcon(_ preset: TransferPreset) -> String {
        if preset.isCascadingEnabled {
            return "arrow.triangle.branch"
        } else if preset.createMHL {
            return "checkmark.shield.fill"
        } else if preset.generateReport {
            return "doc.text.fill"
        } else {
            return "folder.fill"
        }
    }
    
    // Right side preset details
    private var presetDetailView: some View {
        Group {
            if let preset = selectedPreset {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header with preset name and edit button
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(preset.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    
                                    Text("Active Preset")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                editingPreset = preset
                            }) {
                                Label("Edit", systemImage: "pencil.circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .buttonStyle(GlassButtonStyle())
                            
                            Button(action: {
                                viewModel.applyPreset(preset)
                            }) {
                                Label("Apply", systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .buttonStyle(GlassButtonStyle(isProminent: true))
                        }
                        .padding(.bottom, 10)
                        
                        // Feature badges
                        HStack(spacing: 10) {
                            presetBadge(icon: "folder.fill", text: preset.folderPattern.description, color: .blue)
                            
                            if preset.createMHL {
                                presetBadge(icon: "checkmark.shield.fill", text: "MHL", color: .green)
                            }
                            
                            if preset.generateReport {
                                presetBadge(icon: "doc.text.fill", text: "Report", color: .orange)
                            }
                            
                            if preset.isCascadingEnabled {
                                presetBadge(icon: "arrow.triangle.branch", text: "Cascade", color: .purple)
                            }
                            
                            if !preset.customElements.isEmpty {
                                presetBadge(icon: "curlybraces", text: "\(preset.customElements.count) Elements", color: .teal)
                            }
                        }
                        .padding(.bottom, 10)
                        
                        // Preset details in cards with improved styling
                        Group {
                            // Folder pattern
                            detailCard("Folder Structure", icon: "folder.fill", color: .blue, content: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(preset.folderPattern.description)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.blue.opacity(0.7))
                                    }
                                    
                                    if preset.folderPattern == .custom {
                                        Text(preset.customPattern)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Example Path:")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Text(preset.createDestinationPath())
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(Color.black.opacity(0.2))
                                            .cornerRadius(6)
                                    }
                                    .padding(.top, 4)
                                }
                            })
                            
                            // Custom Elements if present
                            if !preset.customElements.isEmpty {
                                detailCard("Custom Elements", icon: "curlybraces", color: .teal, content: {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(preset.customElements.prefix(4)) { element in
                                            HStack(spacing: 10) {
                                                Image(systemName: elementTypeIcon(element.type))
                                                    .font(.system(size: 14))
                                                    .foregroundColor(elementTypeColor(element.type))
                                                    .frame(width: 28, height: 28)
                                                    .background(elementTypeColor(element.type).opacity(0.1))
                                                    .clipShape(Circle())
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(element.displayName)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.white)
                                                    
                                                    Text(element.type.description)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Spacer()
                                                
                                                Text(element.templateName)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.teal)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.teal.opacity(0.1))
                                                    .cornerRadius(4)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                        
                                        if preset.customElements.count > 4 {
                                            Text("+ \(preset.customElements.count - 4) more elements")
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                                .padding(.top, 4)
                                        }
                                    }
                                })
                            }
                            
                            // Verification
                            detailCard("Verification & Security", icon: "lock.shield.fill", color: .green, content: {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        Image(systemName: "checkmark.shield.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 16))
                                        
                                        Text(preset.verificationBehavior.description)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    
                                    HStack(spacing: 20) {
                                        verificationDetail(title: "Checksum", value: preset.checksumAlgorithm.description)
                                        
                                        verificationDetail(title: "MHL", value: preset.createMHL ? "Enabled" : "Disabled")
                                    }
                                    
                                    if preset.createMHL {
                                        Text("Media Hash List will be created for each transfer operation.")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                            .padding(.top, 4)
                                    }
                                }
                            })
                            
                            // Project info
                            detailCard("Project Information", icon: "film.fill", color: .orange, content: {
                                VStack(alignment: .leading, spacing: 14) {
                                    // Project details
                                    if !preset.projectName.isEmpty {
                                        HStack(spacing: 12) {
                                            infoItem(title: "Project", value: preset.projectName, icon: "folder.badge.person.crop", color: .orange)
                                            
                                            if !preset.cameraMake.isEmpty {
                                                Divider()
                                                    .background(Color.gray.opacity(0.3))
                                                    .frame(height: 30)
                                                
                                                infoItem(title: "Camera", value: preset.cameraMake, icon: "camera.fill", color: .blue) 
                                            }
                                        }
                                    } else if !preset.cameraMake.isEmpty {
                                        infoItem(title: "Camera", value: preset.cameraMake, icon: "camera.fill", color: .blue)
                                    } else {
                                        Text("No project information configured")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    // Advanced features
                                    VStack(spacing: 10) {
                                        HStack(spacing: 20) {
                                            featureToggle(icon: "doc.text.fill", title: "Transfer Report", isEnabled: preset.generateReport, color: .orange)
                                            
                                            featureToggle(icon: "arrow.triangle.branch", title: "Cascading Copy", isEnabled: preset.isCascadingEnabled, color: .purple)
                                        }
                                    }
                                    .padding(.top, 10)
                                }
                            })
                        }
                    }
                    .padding(.horizontal, 10)
                }
            } else {
                // No preset selected - improved empty state
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]), 
                                startPoint: .topLeading, 
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolRenderingMode(.hierarchical)
                    
                    Text("Select a Transfer Preset")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Choose an existing preset from the list or create a new one")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        isAddingNewPreset = true
                    }) {
                        Label("Create New Preset", systemImage: "plus.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .buttonStyle(GlassButtonStyle(isProminent: true))
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            }
        }
    }
    
    // Display a detail card with title, icon and custom content
    private func detailCard<Content: View>(_ title: String, icon: String, color: Color, content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Card title with icon
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.2))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                // Pill divider
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.3))
                    .frame(width: 30, height: 4)
            }
            
            // Custom content
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(NSColor.controlBackgroundColor).opacity(0.15),
                            Color(NSColor.controlBackgroundColor).opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.3),
                                    color.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .padding(.bottom, 5)
    }
    
    // Feature badge for preset capabilities
    private func presetBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.2))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Verification detail item
    private func verificationDetail(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title + ":")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.15))
        .cornerRadius(4)
    }
    
    // Info item for project details
    private func infoItem(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
    
    // Feature toggle display
    private func featureToggle(icon: String, title: String, isEnabled: Bool, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isEnabled ? color : .gray)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(isEnabled ? .white.opacity(0.9) : .gray)
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(isEnabled ? color : .gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.15))
        .cornerRadius(8)
    }
    
    // Helper functions for element icons and colors
    private func elementTypeIcon(_ type: CustomElement.ElementType) -> String {
        switch type {
        case .text:
            return "text.cursor"
        case .date:
            return "calendar"
        case .select:
            return "list.bullet"
        case .counter:
            return "number.circle"
        case .number:
            return "number"
        case .hidden:
            return "eye.slash"
        }
    }
    
    private func elementTypeColor(_ type: CustomElement.ElementType) -> Color {
        switch type {
        case .text:
            return .blue
        case .date:
            return .green
        case .select:
            return .purple
        case .counter, .number:
            return .orange
        case .hidden:
            return .gray
        }
    }
}

/// Glass button style for better looking buttons
struct GlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isProminent ?
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isProminent ?
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .foregroundColor(.white)
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
    
    @State private var selectedTab = 0
    @State private var showElementsView = false
    
    @EnvironmentObject var viewModel: MediaForgeViewModel
    
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
            
            // Tab view for different sections
            TabView(selection: $selectedTab) {
                basicSettingsForm
                    .tabItem {
                        Label("Basic Settings", systemImage: "gear")
                    }
                    .tag(0)
                
                folderStructureForm
                    .tabItem {
                        Label("Folder Structure", systemImage: "folder")
                    }
                    .tag(1)
                
                customElementsTab
                    .tabItem {
                        Label("Custom Elements", systemImage: "curlybraces")
                    }
                    .tag(2)
                
                verificationForm
                    .tabItem {
                        Label("Verification", systemImage: "checkmark.shield")
                    }
                    .tag(3)
                
                advancedOptionsForm
                    .tabItem {
                        Label("Advanced", systemImage: "slider.horizontal.3")
                    }
                    .tag(4)
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
        .frame(width: 620, height: 550)
        .sheet(isPresented: $showElementsView) {
            // Set the active preset before showing the element editor
            if !isNew {
                // Wrap in Group for proper SwiftUI syntax
                Group {
                    let _ = viewModel.activePreset = preset
                    CustomElementsListView(viewModel: viewModel)
                        .frame(width: 550, height: 500)
                }
            } else {
                CustomElementsListView(viewModel: viewModel)
                    .frame(width: 550, height: 500)
            }
        }
    }
    
    // Basic Settings Form
    private var basicSettingsForm: some View {
        Form {
            Section(header: Text("Preset Information")) {
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
        }
    }
    
    // Folder Structure Form
    private var folderStructureForm: some View {
        Form {
            Section(header: Text("Folder Pattern")) {
                Picker("Pattern", selection: $folderPattern) {
                    ForEach(FolderPattern.allCases) { pattern in
                        Text(pattern.description).tag(pattern)
                    }
                }
                
                if folderPattern == .custom {
                    VStack(alignment: .leading) {
                        // Custom pattern editor with element support
                        CustomElementPatternView(viewModel: viewModel, pattern: $customPattern)
                            .padding(.bottom, 10)
                        
                        Button("Manage Custom Elements...") {
                            // Ensure the active preset is set before showing the element editor
                            let _ = viewModel.activePreset = preset
                            showElementsView = true
                        }
                        .padding(.vertical, 5)
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
        }
    }
    
    // Custom Elements Tab
    private var customElementsTab: some View {
        VStack {
            Text("Custom Elements")
                .font(.headline)
                .padding(.bottom, 10)
            
            Text("Custom elements allow you to create placeholders for metadata that can be used in folder paths, filenames, and more.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            Button("Manage Custom Elements") {
                // Ensure the active preset is set before showing the element editor
                let _ = viewModel.activePreset = preset
                showElementsView = true
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
            
            if preset.customElements.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "curlybraces")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No Custom Elements Created")
                        .font(.headline)
                    
                    Text("Create custom elements to use in folder patterns and other templates.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .frame(maxWidth: 300)
                }
                .padding()
            } else {
                List {
                    ForEach(preset.customElements) { element in
                        HStack(spacing: 15) {
                            Image(systemName: elementTypeIcon(element.type))
                                .foregroundColor(elementTypeColor(element.type))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text(element.displayName)
                                    .font(.headline)
                                
                                Text("\(element.type.description) • Default: \(element.defaultValue.isEmpty ? "None" : element.defaultValue)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // Verification Form
    private var verificationForm: some View {
        Form {
            Section(header: Text("Verification Method")) {
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
        }
    }
    
    // Advanced Options Form
    private var advancedOptionsForm: some View {
        Form {
            Section(header: Text("Advanced Options")) {
                Toggle("Generate Transfer Report", isOn: $generateReport)
                Toggle("Enable Cascading Copy", isOn: $isCascadingEnabled)
            }
        }
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
            
            // Replace custom elements with default values for example
            for element in preset.customElements {
                pattern = pattern.replacingOccurrences(of: element.templateName, with: element.defaultValue.isEmpty ? element.displayName : element.defaultValue)
            }
            
            return pattern
        }
    }
    
    // Helper functions for element icons and colors
    private func elementTypeIcon(_ type: CustomElement.ElementType) -> String {
        switch type {
        case .text:
            return "text.cursor"
        case .date:
            return "calendar"
        case .select:
            return "list.bullet"
        case .counter:
            return "number.circle"
        case .number:
            return "number"
        case .hidden:
            return "eye.slash"
        }
    }
    
    private func elementTypeColor(_ type: CustomElement.ElementType) -> Color {
        switch type {
        case .text:
            return .blue
        case .date:
            return .green
        case .select:
            return .purple
        case .counter, .number:
            return .orange
        case .hidden:
            return .gray
        }
    }
} 