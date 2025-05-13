import SwiftUI

/// View for configuring application settings
struct SettingsView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    
    @State private var selectedSection: SettingsSection = .general
    @State private var showResetAlert = false
    @State private var isHoveringResetButton = false
    
    // Styling
    private let cornerRadius: CGFloat = 15
    private let sectionSpacing: CGFloat = 24
    
    enum SettingsSection: String, CaseIterable, Identifiable {
        case general = "General"
        case advanced = "Advanced"
        case verification = "Verification"
        case appearance = "Appearance"
        case language = "Language"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .general: return "gear"
            case .advanced: return "gearshape.2"
            case .verification: return "checkmark.shield"
            case .appearance: return "paintbrush"
            case .language: return "globe"
            }
        }
        
        var color: Color {
            switch self {
            case .general: return .blue
            case .advanced: return .purple
            case .verification: return .green
            case .appearance: return .orange
            case .language: return .teal
            }
        }
        
        var localizedName: String {
            switch self {
            case .general: return "general".localized
            case .advanced: return "advanced".localized
            case .verification: return "verification".localized
            case .appearance: return "appearance".localized
            case .language: return "language".localized
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                HStack {
                    Text("settings".localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: {
                        showResetAlert = true
                    }) {
                        Label("reset_all".localized, systemImage: "arrow.counterclockwise.circle")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(isHoveringResetButton ? 0.2 : 0.1))
                            )
                            .foregroundColor(Color.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHoveringResetButton = hovering
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.15, green: 0.15, blue: 0.25)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Content
            HStack(spacing: 0) {
                // Sidebar
                VStack(spacing: 0) {
                    ForEach(SettingsSection.allCases) { section in
                        sidebarItem(section)
                    }
                    
                    Spacer()
                }
                .frame(width: 220)
                .background(Color(red: 0.12, green: 0.12, blue: 0.18))
                
                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: sectionSpacing) {
                        // Show settings based on selected section
                        switch selectedSection {
                        case .general:
                            generalSettings
                        case .advanced:
                            advancedSettings
                        case .verification:
                            verificationSettings
                        case .appearance:
                            appearanceSettings
                        case .language:
                            languageSettings
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            }
        }
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("reset_settings".localized),
                message: Text("reset_confirm_message".localized),
                primaryButton: .destructive(Text("reset".localized)) {
                    resetSettings()
                },
                secondaryButton: .cancel(Text("cancel".localized))
            )
        }
    }
    
    // Sidebar item for settings category
    private func sidebarItem(_ section: SettingsSection) -> some View {
        Button(action: {
            selectedSection = section
        }) {
            HStack {
                Image(systemName: section.icon)
                    .frame(width: 24)
                
                Text(section.localizedName)
                    .fontWeight(selectedSection == section ? .semibold : .regular)
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedSection == section ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }
    
    // MARK: - Settings Sections
    
    // General settings
    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("General Settings")
            
            settingsCard {
                Toggle("Show confirmation dialogs", isOn: $viewModel.showConfirmationDialogs)
                    .padding(.bottom, 6)
                
                Toggle("Auto-start transfer when ready", isOn: $viewModel.autoStartTransfer)
                    .padding(.bottom, 6)
                
                Toggle("Play sound when transfer completes", isOn: $viewModel.playSoundOnComplete)
            }
            
            Divider().padding(.vertical, 8)
            
            sectionHeader("Default Behavior")
            
            settingsCard {
                Toggle("Create subfolder for transfers", isOn: $viewModel.createSubfolder)
                    .padding(.bottom, 6)
                
                Toggle("Generate checksums", isOn: $viewModel.generateChecksums)
                    .padding(.bottom, 6)
                
                Toggle("Create Media Hash List (MHL)", isOn: $viewModel.createMHL)
            }
        }
    }
    
    // Advanced settings
    private var advancedSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Advanced Settings")
            
            settingsCard {
                Slider(value: $viewModel.maxConcurrentTransfers, in: 1...8, step: 1) {
                    Text("Maximum concurrent transfers: \(Int(viewModel.maxConcurrentTransfers))")
                } minimumValueLabel: {
                    Text("1")
                } maximumValueLabel: {
                    Text("8")
                }
                .padding(.bottom, 6)
                
                Toggle("Use native file copy for large files", isOn: $viewModel.useNativeCopy)
                    .padding(.bottom, 6)
                
                Toggle("Skip system files", isOn: $viewModel.skipSystemFiles)
                    .padding(.bottom, 6)
                
                Toggle("Show debug information", isOn: $viewModel.showDebugInfo)
            }
            
            Divider().padding(.vertical, 8)
            
            sectionHeader("Reset")
            
            settingsCard {
                Button("Reset All Settings") {
                    showResetAlert = true
                }
                .foregroundColor(.red)
            }
        }
    }
    
    // Verification settings
    private var verificationSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Verification Settings")
            
            settingsCard {
                Picker("Default checksum method", selection: $viewModel.defaultChecksumMethod) {
                    Text("xxHash64 (Fast)").tag("xxHash64")
                    Text("MD5 (Compatible)").tag("MD5")
                    Text("SHA-1 (Secure)").tag("SHA1")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 12)
                
                Picker("Verification behavior", selection: $viewModel.defaultVerificationMode) {
                    Text("Standard").tag("Standard")
                    Text("Verify Source").tag("Verify Source")
                    Text("Double Verification").tag("Double Verification")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 12)
                
                Toggle("Always verify after transfer", isOn: $viewModel.alwaysVerify)
                    .padding(.bottom, 6)
                
                Toggle("Stop on verification failure", isOn: $viewModel.stopOnVerificationFailure)
            }
            
            Divider().padding(.vertical, 8)
            
            sectionHeader("Error Handling")
            
            settingsCard {
                Toggle("Retry failed transfers automatically", isOn: $viewModel.autoRetryFailedTransfers)
                    .padding(.bottom, 6)
                
                if viewModel.autoRetryFailedTransfers {
                    HStack {
                        Text("Max retry attempts:")
                        Spacer()
                        Picker("", selection: $viewModel.maxRetryAttempts) {
                            ForEach([1, 2, 3, 5, 10], id: \.self) { num in
                                Text("\(num)").tag(num)
                            }
                        }
                        .frame(width: 100)
                    }
                }
            }
        }
    }
    
    // Appearance settings
    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Appearance")
            
            settingsCard {
                Toggle("Use dark mode", isOn: $viewModel.useDarkMode)
                    .padding(.bottom, 12)
                
                ColorPicker("Accent color", selection: $viewModel.accentColor)
                    .padding(.bottom, 12)
                
                Toggle("Animate transitions", isOn: $viewModel.animateTransitions)
                    .padding(.bottom, 6)
                
                Toggle("Use compact view", isOn: $viewModel.useCompactView)
            }
            
            Divider().padding(.vertical, 8)
            
            sectionHeader("List Settings")
            
            settingsCard {
                Picker("Default sort order", selection: $viewModel.defaultSortOrder) {
                    Text("Name").tag("name")
                    Text("Size").tag("size")
                    Text("Date").tag("date")
                    Text("Type").tag("type")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 12)
                
                Picker("Disk view layout", selection: $viewModel.diskViewLayout) {
                    Text("Grid").tag("grid")
                    Text("List").tag("list")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
    
    // Language settings
    private var languageSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("language_settings".localized)
            
            settingsCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("app_language".localized)
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        ForEach(AppLanguage.allCases) { language in
                            Button(action: {
                                viewModel.appLanguage = language.rawValue
                            }) {
                                HStack {
                                    Text(language.flagEmoji)
                                        .font(.title2)
                                        .frame(width: 36)
                                    
                                    Text(language.localizedDisplayName)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if viewModel.appLanguage == language.rawValue {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .contentShape(Rectangle())
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(viewModel.appLanguage == language.rawValue ? 
                                              Color.accentColor.opacity(0.1) : Color.clear)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Divider()
                    
                    Text("language_restart_required".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    // Section header
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
    }
    
    // Card style view for settings
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(cornerRadius)
    }
    
    // MARK: - Actions
    
    // Reset all settings to defaults
    private func resetSettings() {
        // Reset general settings
        viewModel.showConfirmationDialogs = true
        viewModel.autoStartTransfer = false
        viewModel.playSoundOnComplete = true
        viewModel.createSubfolder = true
        viewModel.generateChecksums = true
        viewModel.createMHL = false
        
        // Reset advanced settings
        viewModel.maxConcurrentTransfers = 3
        viewModel.useNativeCopy = true
        viewModel.skipSystemFiles = true
        viewModel.showDebugInfo = false
        
        // Reset verification settings
        viewModel.defaultChecksumMethod = "xxHash64"
        viewModel.defaultVerificationMode = "Standard"
        viewModel.alwaysVerify = true
        viewModel.stopOnVerificationFailure = true
        viewModel.autoRetryFailedTransfers = false
        viewModel.maxRetryAttempts = 3
        
        // Reset appearance settings
        viewModel.useDarkMode = false
        viewModel.accentColor = Color.blue
        viewModel.animateTransitions = true
        viewModel.useCompactView = false
        viewModel.defaultSortOrder = "name"
        viewModel.diskViewLayout = "grid"
    }
} 