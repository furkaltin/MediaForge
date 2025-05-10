import SwiftUI

/// View for reviewing and filling in custom element values before starting a transfer
struct ElementReviewPanelView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var elementValues: [UUID: String] = [:]
    
    var onComplete: (Bool) -> Void
    
    init(viewModel: MediaForgeViewModel, onComplete: @escaping (Bool) -> Void) {
        self.viewModel = viewModel
        self.onComplete = onComplete
        
        // Initialize the state with current values from the preset
        var initialValues: [UUID: String] = [:]
        if let preset = viewModel.activePreset {
            for element in preset.customElements {
                initialValues[element.id] = element.currentValue
            }
        }
        _elementValues = State(initialValue: initialValues)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Review Elements")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    onComplete(false)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
            
            // Custom elements form
            if let preset = viewModel.activePreset, !preset.customElements.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Please fill in the following information:")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        ForEach(preset.customElements) { element in
                            if element.type != .hidden {
                                elementEditor(element)
                            }
                        }
                    }
                    .padding()
                }
                .frame(minHeight: 200)
            } else {
                VStack {
                    Text("No custom elements to review")
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            }
            
            // Preview section
            if let preset = viewModel.activePreset {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Destination Path Preview:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(generatePreviewPath(preset))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(4)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.05))
            }
            
            // Buttons
            HStack {
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                
                Spacer()
                
                Button("Continue") {
                    saveValues()
                    onComplete(true)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
        }
        .frame(width: 550, height: 450)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // Dynamic editor for different element types
    private func elementEditor(_ element: CustomElement) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(element.displayName)
                    .font(.headline)
                
                if element.type == .counter {
                    Image(systemName: "arrow.clockwise.circle")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    
                    Text("Auto-incrementing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Group {
                switch element.type {
                case .text, .number:
                    TextField(
                        "Enter \(element.displayName)",
                        text: Binding(
                            get: { elementValues[element.id] ?? element.currentValue },
                            set: { elementValues[element.id] = $0 }
                        )
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                case .date:
                    DatePicker(
                        "",
                        selection: Binding(
                            get: {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                return formatter.date(from: elementValues[element.id] ?? element.currentValue) ?? Date()
                            },
                            set: {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                elementValues[element.id] = formatter.string(from: $0)
                            }
                        ),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    
                case .select:
                    Picker(
                        "",
                        selection: Binding(
                            get: { elementValues[element.id] ?? element.currentValue },
                            set: { elementValues[element.id] = $0 }
                        )
                    ) {
                        ForEach(element.options, id: \.id) { option in
                            Text(option.name).tag(option.value)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .labelsHidden()
                    
                case .counter:
                    HStack {
                        TextField(
                            "Counter Value",
                            text: Binding(
                                get: { elementValues[element.id] ?? element.currentValue },
                                set: { elementValues[element.id] = $0 }
                            )
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            if let value = Int(elementValues[element.id] ?? element.currentValue) {
                                let newValue = value + 1
                                let valueStr = String(format: "%0\(elementValues[element.id]?.count ?? 4)d", newValue)
                                elementValues[element.id] = valueStr
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    
                case .hidden:
                    EmptyView() // Hidden elements are not displayed
                }
            }
            .padding(.top, 2)
        }
    }
    
    private func generatePreviewPath(_ preset: TransferPreset) -> String {
        // Create a temporary copy of the preset with our current values
        let tempPreset = TransferPreset(
            id: preset.id,
            name: preset.name,
            folderPattern: preset.folderPattern,
            customPattern: preset.customPattern,
            verificationBehavior: preset.verificationBehavior,
            checksumAlgorithm: preset.checksumAlgorithm,
            createMHL: preset.createMHL,
            projectName: preset.projectName,
            cameraMake: preset.cameraMake,
            generateReport: preset.generateReport,
            isCascadingEnabled: preset.isCascadingEnabled,
            customElements: []
        )
        
        // Add elements with current values from the form
        for element in preset.customElements {
            let copy = CustomElement(
                name: element.name,
                type: element.type,
                defaultValue: element.defaultValue,
                currentValue: elementValues[element.id] ?? element.currentValue,
                options: element.options
            )
            tempPreset.addCustomElement(copy)
        }
        
        return tempPreset.createDestinationPath()
    }
    
    private func resetToDefaults() {
        if let preset = viewModel.activePreset {
            var updatedValues: [UUID: String] = [:]
            for element in preset.customElements {
                updatedValues[element.id] = element.defaultValue
            }
            elementValues = updatedValues
        }
    }
    
    private func saveValues() {
        guard let preset = viewModel.activePreset else { return }
        
        // Update all elements with values from the form
        for element in preset.customElements {
            if let value = elementValues[element.id] {
                element.currentValue = value
            }
        }
        
        // Auto-increment counters if needed
        preset.incrementCounters()
        
        // Update the preset in the view model
        viewModel.updatePreset(preset)
    }
} 