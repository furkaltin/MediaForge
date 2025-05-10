import SwiftUI

/// View for editing a single custom element
struct CustomElementEditView: View {
    @ObservedObject var element: CustomElement
    @State private var tempName: String
    @State private var tempType: CustomElement.ElementType
    @State private var tempDefaultValue: String
    @State private var tempOptions: [SelectOption]
    
    var onSave: (CustomElement) -> Void
    var onCancel: () -> Void
    
    init(element: CustomElement, onSave: @escaping (CustomElement) -> Void, onCancel: @escaping () -> Void) {
        self.element = element
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize state with element values
        _tempName = State(initialValue: element.displayName) // Remove braces for editing
        _tempType = State(initialValue: element.type)
        _tempDefaultValue = State(initialValue: element.defaultValue)
        _tempOptions = State(initialValue: element.options)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Element")
                .font(.title)
                .fontWeight(.bold)
            
            Form {
                Section(header: Text("Element Details")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Element Name", text: $tempName)
                            .frame(width: 220)
                    }
                    
                    HStack {
                        Text("Type")
                        Spacer()
                        Picker("Type", selection: $tempType) {
                            ForEach(CustomElement.ElementType.allCases, id: \.self) { type in
                                Text(type.description).tag(type)
                            }
                        }
                        .frame(width: 220)
                    }
                    
                    if tempType == .select {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Options")
                                .font(.headline)
                                .padding(.top, 5)
                            
                            ForEach(0..<tempOptions.count, id: \.self) { index in
                                HStack {
                                    TextField("Option Name", text: $tempOptions[index].name)
                                    TextField("Value", text: $tempOptions[index].value)
                                    
                                    Button(action: {
                                        tempOptions.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 2)
                            }
                            
                            Button(action: {
                                tempOptions.append(SelectOption(name: "", value: ""))
                            }) {
                                Label("Add Option", systemImage: "plus.circle")
                            }
                            .padding(.top, 5)
                        }
                    } else {
                        HStack {
                            Text("Default Value")
                            Spacer()
                            if tempType == .date {
                                DatePicker("", selection: Binding(
                                    get: { 
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "yyyy-MM-dd"
                                        return formatter.date(from: tempDefaultValue) ?? Date()
                                    },
                                    set: { 
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "yyyy-MM-dd"
                                        tempDefaultValue = formatter.string(from: $0)
                                    }
                                ))
                                .labelsHidden()
                                .frame(width: 220)
                            } else {
                                TextField("Default Value", text: $tempDefaultValue)
                                    .frame(width: 220)
                            }
                        }
                    }
                }
                
                Section(header: Text("Preview")) {
                    HStack {
                        Text("Template")
                        Spacer()
                        Text("{\(tempName)}")
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if tempType == .counter {
                        Text("Counter will increment automatically when used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save Element") {
                    // Update the element with edited values
                    element.name = "{\(tempName)}" // Add back the braces
                    element.type = tempType
                    element.defaultValue = tempDefaultValue
                    element.currentValue = tempDefaultValue
                    element.options = tempOptions
                    
                    onSave(element)
                }
                .buttonStyle(.borderedProminent)
                .disabled(tempName.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 500, height: 450)
    }
}

/// View for displaying a list of custom elements within a preset
struct CustomElementsListView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var isAddingElement = false
    @State private var editingElement: CustomElement?
    @State private var showingTemplates = false
    @State private var showingMetadataExtractor = false
    @State private var showingBatchOperations = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Custom Elements")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingTemplates = true
                }) {
                    Label("Templates", systemImage: "doc.on.doc")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(GlassButtonStyle())
                
                Button(action: {
                    showingMetadataExtractor = true
                }) {
                    Label("Extract", systemImage: "wand.and.stars")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(GlassButtonStyle())
                
                Button(action: {
                    showingBatchOperations = true
                }) {
                    Label("Batch", systemImage: "list.bullet.clipboard")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(viewModel.activePreset?.customElements.isEmpty ?? true)
                
                Button(action: {
                    isAddingElement = true
                }) {
                    Label("Add Element", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(GlassButtonStyle())
            }
            
            if let preset = viewModel.activePreset, !preset.customElements.isEmpty {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(preset.customElements) { element in
                            elementRow(element)
                        }
                    }
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "curlybraces")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding()
                    
                    Text("No Custom Elements")
                        .font(.headline)
                    
                    Text("Add custom elements using the + button above.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .sheet(isPresented: $isAddingElement) {
            CustomElementEditView(
                element: CustomElement(name: ""),
                onSave: { newElement in
                    viewModel.addCustomElement(newElement)
                    isAddingElement = false
                },
                onCancel: {
                    isAddingElement = false
                }
            )
        }
        .sheet(item: $editingElement) { element in
            CustomElementEditView(
                element: element,
                onSave: { updatedElement in
                    viewModel.updateCustomElement(updatedElement)
                    editingElement = nil
                },
                onCancel: {
                    editingElement = nil
                }
            )
        }
        .sheet(isPresented: $showingTemplates) {
            ElementTemplatesView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingMetadataExtractor) {
            MetadataExtractorView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingBatchOperations) {
            BatchOperationsView(viewModel: viewModel)
        }
    }
    
    private func elementRow(_ element: CustomElement) -> some View {
        HStack(spacing: 12) {
            // Element type icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [elementTypeColor(element.type).opacity(0.7), elementTypeColor(element.type).opacity(0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: elementTypeIcon(element.type))
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(element.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                HStack {
                    Text(element.type.description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    if !element.defaultValue.isEmpty && element.type != .select {
                        Text("• Default: \(element.defaultValue)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Edit button
            Button(action: {
                editingElement = element
            }) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            
            // Delete button
            Button(action: {
                viewModel.removeCustomElement(element)
            }) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.15))
        )
        .padding(.horizontal, 2)
    }
    
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

/// View that shows how a custom element appears in patterns
struct CustomElementPatternView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @Binding var pattern: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Pattern Editor")
                .font(.headline)
            
            TextField("Custom Pattern", text: $pattern)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: pattern) { oldPattern, newPattern in
                    // Check for newly added elements
                    let placeholders = viewModel.extractPlaceholders(from: newPattern)
                    
                    for placeholder in placeholders {
                        // Create any missing elements
                        _ = viewModel.findOrCreateCustomElement(name: placeholder)
                    }
                }
            
            Text("Available Elements (click to insert)")
                .font(.subheadline)
                .padding(.top, 5)
            
            if let preset = viewModel.activePreset {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // Standard elements
                        Group {
                            elementChip("{Date}", icon: "calendar", color: .green)
                            elementChip("{Time}", icon: "clock", color: .blue)
                            elementChip("{Project}", icon: "folder", color: .orange)
                            elementChip("{Camera}", icon: "camera", color: .purple)
                        }
                        
                        // Custom elements
                        ForEach(preset.customElements) { element in
                            elementChip(
                                element.templateName,
                                icon: elementTypeIcon(element.type),
                                color: elementTypeColor(element.type)
                            )
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }
    
    private func elementChip(_ name: String, icon: String, color: Color) -> some View {
        Button(action: {
            // Insert the element at cursor position or append to end
            pattern += name
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(name)
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
        .buttonStyle(.plain)
    }
    
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

/// View for managing element templates
struct ElementTemplatesView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var showingSavePrompt = false
    @State private var templateName = ""
    @State private var selectedTemplate: [String: Any]?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Element Templates")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingSavePrompt = true
                }) {
                    Label("Save Current", systemImage: "square.and.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(viewModel.activePreset?.customElements.isEmpty ?? true)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
            
            if viewModel.loadElementTemplates().isEmpty {
                // Empty state
                VStack(spacing: 15) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No Templates Saved")
                        .font(.headline)
                    
                    Text("Save your current elements as a template for reuse.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .frame(maxWidth: 250)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Template list
                List {
                    ForEach(viewModel.loadElementTemplates().indices, id: \.self) { index in
                        let template = viewModel.loadElementTemplates()[index]
                        templateRow(template)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTemplate = template
                            }
                    }
                }
            }
            
            // Bottom buttons
            HStack {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Spacer()
                
                if let template = selectedTemplate {
                    Button("Apply Template") {
                        viewModel.applyElementTemplate(template)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
        }
        .frame(width: 500, height: 400)
        .alert("Save Template", isPresented: $showingSavePrompt) {
            TextField("Template Name", text: $templateName)
            
            Button("Cancel", role: .cancel) { }
            
            Button("Save") {
                viewModel.saveElementTemplate(name: templateName)
                templateName = ""
            }
            .disabled(templateName.isEmpty)
        } message: {
            Text("Enter a name for this template")
        }
    }
    
    private func templateRow(_ template: [String: Any]) -> some View {
        HStack(spacing: 15) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "doc.badge.gearshape")
                    .font(.system(size: 18))
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(template["name"] as? String ?? "Unnamed Template")
                    .font(.system(size: 15, weight: .semibold))
                
                if let elements = template["elements"] as? [[String: Any]] {
                    Text("\(elements.count) elements")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                if let date = template["date"] as? Date {
                    Text(date, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Selected indicator
            if template as NSDictionary == selectedTemplate as? NSDictionary {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(template as NSDictionary == selectedTemplate as? NSDictionary ? 
                      Color.blue.opacity(0.1) : Color.clear)
        )
    }
}

/// View for extracting metadata from files into custom elements
struct MetadataExtractorView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var selectedFilePath: String?
    @State private var metadataExtracted = false
    @State private var extractedFields: [String: String] = [:]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Extract Metadata")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
            
            // Content
            VStack(spacing: 20) {
                if selectedFilePath == nil {
                    // File selection prompt
                    VStack(spacing: 15) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 40))
                            .foregroundColor(.blue.opacity(0.6))
                        
                        Text("Select a media file")
                            .font(.headline)
                        
                        Text("Choose a media file to extract metadata from. The app will attempt to populate custom elements based on the file's metadata.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                        
                        Button("Select File") {
                            selectFile()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 10)
                    }
                    .padding()
                } else if metadataExtracted {
                    // Metadata results
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Metadata Extracted")
                            .font(.headline)
                        
                        if extractedFields.isEmpty {
                            Text("No metadata could be extracted from this file.")
                                .foregroundColor(.secondary)
                        } else {
                            List {
                                ForEach(extractedFields.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    HStack {
                                        Text(key)
                                            .font(.system(size: 14, weight: .medium))
                                        
                                        Spacer()
                                        
                                        Text(value)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        HStack {
                            Button("Select Another File") {
                                selectedFilePath = nil
                                metadataExtracted = false
                                extractedFields = [:]
                            }
                            
                            Spacer()
                            
                            Button("Apply to Elements") {
                                if let path = selectedFilePath {
                                    viewModel.extractMetadataAndPopulateElements(from: path)
                                }
                                presentationMode.wrappedValue.dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(extractedFields.isEmpty)
                        }
                    }
                    .padding()
                } else {
                    // Loading
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        
                        Text("Extracting metadata...")
                            .font(.headline)
                    }
                    .onAppear {
                        // Simulate metadata extraction
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            extractMetadata()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 500, height: 400)
    }
    
    private func selectFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.movie, .image, .audio]
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                selectedFilePath = url.path
            }
        }
    }
    
    private func extractMetadata() {
        guard let path = selectedFilePath else { return }
        
        // Simulate extracting metadata
        // In a real app, this would use AVFoundation, ImageIO, etc.
        let url = URL(fileURLWithPath: path)
        
        // Get file attributes
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let creationDate = attributes[.creationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                extractedFields["Creation Date"] = formatter.string(from: creationDate)
            }
            
            if let size = attributes[.size] as? Int64 {
                extractedFields["File Size"] = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
        } catch {
            print("Error getting file attributes: \(error)")
        }
        
        // Get filename
        extractedFields["Filename"] = url.lastPathComponent
        extractedFields["File Extension"] = url.pathExtension
        
        // Add more metadata based on actual file content
        // This would be expanded in a real implementation
        
        metadataExtracted = true
    }
}

/// View for performing batch operations on custom elements
struct BatchOperationsView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var prefixText = ""
    @State private var selectedType: CustomElement.ElementType = .text
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Batch Operations")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
            
            // Operations list
            ScrollView {
                VStack(spacing: 15) {
                    Group {
                        operationCard(
                            title: "Reset All to Defaults",
                            description: "Reset all elements to their default values",
                            icon: "arrow.counterclockwise",
                            color: .blue
                        ) {
                            viewModel.batchOperationOnElements(operation: .resetAllToDefaults)
                            presentationMode.wrappedValue.dismiss()
                        }
                        
                        operationCard(
                            title: "Clear All Values",
                            description: "Set all element values to empty",
                            icon: "xmark.circle",
                            color: .red
                        ) {
                            viewModel.batchOperationOnElements(operation: .clearAllValues)
                            presentationMode.wrappedValue.dismiss()
                        }
                        
                        operationCard(
                            title: "Increment All Counters",
                            description: "Increase all counter elements by one",
                            icon: "plus.circle",
                            color: .green
                        ) {
                            viewModel.batchOperationOnElements(operation: .incrementAllCounters)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    
                    // Add prefix operation
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "text.append")
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            
                            Text("Add Prefix to All Names")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        Text("Add a prefix to all element names")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("Prefix", text: $prefixText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Apply") {
                                viewModel.batchOperationOnElements(operation: .prefixAllNames(prefixText))
                                presentationMode.wrappedValue.dismiss()
                            }
                            .disabled(prefixText.isEmpty)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Convert type operation
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "arrow.triangle.swap")
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            
                            Text("Convert All to Type")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        Text("Convert all elements to a specific type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Picker("Type", selection: $selectedType) {
                                ForEach(CustomElement.ElementType.allCases, id: \.self) { type in
                                    Text(type.description).tag(type)
                                }
                            }
                            .frame(width: 200)
                            
                            Button("Apply") {
                                viewModel.batchOperationOnElements(operation: .convertAllToType(selectedType))
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private func operationCard(
        title: String,
        description: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .frame(width: 30)
                    
                    Text(title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
} 