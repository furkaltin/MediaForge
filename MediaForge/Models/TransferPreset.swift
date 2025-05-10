import Foundation

/// Checksum algorithm types for verification
enum ChecksumAlgorithm: String, Codable, CaseIterable, Identifiable {
    case xxHash64 = "xxHash64"
    case md5 = "MD5"
    case sha1 = "SHA1"
    case fileSize = "File Size Only"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .xxHash64:
            return "xxHash64 (Fast, Recommended)"
        case .md5:
            return "MD5 (Industry Standard)"
        case .sha1:
            return "SHA1 (Slower but Most Secure)"
        case .fileSize:
            return "File Size Only (Fast, Less Secure)"
        }
    }
}

/// Folder naming pattern using placeholders for dynamic values
enum FolderPattern: String, Codable, CaseIterable, Identifiable {
    case dateTime = "{Date}/{Time}"
    case dateProject = "{Date}/{Project}"
    case projectDate = "{Project}/{Date}"
    case cameraDate = "{Camera}/{Date}"
    case projectCameraCard = "{Project}/{Camera}/{Card}"
    case custom = "Custom" // Custom pattern
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .dateTime:
            return "Date/Time (2023-09-05/14-30)"
        case .dateProject:
            return "Date/Project (2023-09-05/ProjectName)"
        case .projectDate:
            return "Project/Date (ProjectName/2023-09-05)"
        case .cameraDate:
            return "Camera/Date (SonyA7S/2023-09-05)"
        case .projectCameraCard:
            return "Project/Camera/Card (ProjectName/SonyA7S/Card1)"
        case .custom:
            return "Custom Pattern"
        }
    }
}

/// Verification behavior options
enum VerificationBehavior: String, Codable, CaseIterable, Identifiable {
    case standard = "Standard"
    case verifySource = "Verify Source"
    case doubleVerification = "Double Verification"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .standard:
            return "Standard (Verify Destination)"
        case .verifySource:
            return "Verify Source (Check Source Before Transfer)"
        case .doubleVerification:
            return "Double Verification (Most Secure)"
        }
    }
}

/// Represents a transfer preset for configuring transfers
class TransferPreset: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var name: String
    @Published var folderPattern: FolderPattern
    @Published var customPattern: String
    @Published var verificationBehavior: VerificationBehavior
    @Published var checksumAlgorithm: ChecksumAlgorithm
    @Published var createMHL: Bool
    @Published var projectName: String
    @Published var cameraMake: String
    @Published var generateReport: Bool
    @Published var isCascadingEnabled: Bool
    @Published var customElements: [CustomElement]
    
    enum CodingKeys: String, CodingKey {
        case id, name, folderPattern, customPattern, verificationBehavior
        case checksumAlgorithm, createMHL, projectName, cameraMake
        case generateReport, isCascadingEnabled, customElements
    }
    
    init(
        id: UUID = UUID(),
        name: String = "Default Preset",
        folderPattern: FolderPattern = .projectDate,
        customPattern: String = "",
        verificationBehavior: VerificationBehavior = .standard,
        checksumAlgorithm: ChecksumAlgorithm = .xxHash64,
        createMHL: Bool = false,
        projectName: String = "",
        cameraMake: String = "",
        generateReport: Bool = true,
        isCascadingEnabled: Bool = false,
        customElements: [CustomElement] = []
    ) {
        self.id = id
        self.name = name
        self.folderPattern = folderPattern
        self.customPattern = customPattern
        self.verificationBehavior = verificationBehavior
        self.checksumAlgorithm = checksumAlgorithm
        self.createMHL = createMHL
        self.projectName = projectName
        self.cameraMake = cameraMake
        self.generateReport = generateReport
        self.isCascadingEnabled = isCascadingEnabled
        self.customElements = customElements
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        folderPattern = try container.decode(FolderPattern.self, forKey: .folderPattern)
        customPattern = try container.decode(String.self, forKey: .customPattern)
        verificationBehavior = try container.decode(VerificationBehavior.self, forKey: .verificationBehavior)
        checksumAlgorithm = try container.decode(ChecksumAlgorithm.self, forKey: .checksumAlgorithm)
        createMHL = try container.decode(Bool.self, forKey: .createMHL)
        projectName = try container.decode(String.self, forKey: .projectName)
        cameraMake = try container.decode(String.self, forKey: .cameraMake)
        generateReport = try container.decode(Bool.self, forKey: .generateReport)
        isCascadingEnabled = try container.decode(Bool.self, forKey: .isCascadingEnabled)
        customElements = try container.decodeIfPresent([CustomElement].self, forKey: .customElements) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(folderPattern, forKey: .folderPattern)
        try container.encode(customPattern, forKey: .customPattern)
        try container.encode(verificationBehavior, forKey: .verificationBehavior)
        try container.encode(checksumAlgorithm, forKey: .checksumAlgorithm)
        try container.encode(createMHL, forKey: .createMHL)
        try container.encode(projectName, forKey: .projectName)
        try container.encode(cameraMake, forKey: .cameraMake)
        try container.encode(generateReport, forKey: .generateReport)
        try container.encode(isCascadingEnabled, forKey: .isCascadingEnabled)
        try container.encode(customElements, forKey: .customElements)
    }
    
    /// Create a destination folder path based on the pattern
    func createDestinationPath() -> String {
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
            
            // Replace custom elements
            for element in customElements {
                pattern = pattern.replacingOccurrences(of: element.templateName, with: element.currentValue)
            }
            
            return pattern
        }
    }
    
    /// Add a new custom element
    func addCustomElement(_ element: CustomElement) {
        customElements.append(element)
    }
    
    /// Remove a custom element
    func removeCustomElement(_ element: CustomElement) {
        if let index = customElements.firstIndex(where: { $0.id == element.id }) {
            customElements.remove(at: index)
        }
    }
    
    /// Update a custom element
    func updateCustomElement(_ element: CustomElement) {
        if let index = customElements.firstIndex(where: { $0.id == element.id }) {
            customElements[index] = element
        }
    }
    
    /// Get a custom element by name
    func getCustomElement(name: String) -> CustomElement? {
        // Check for exact name match or with/without braces
        let nameWithoutBraces = name.trimmingCharacters(in: CharacterSet(charactersIn: "{}"))
        let nameWithBraces = "{\(nameWithoutBraces)}"
        
        return customElements.first { 
            $0.name == name || 
            $0.name == nameWithBraces || 
            $0.name == nameWithoutBraces 
        }
    }
    
    /// Parse a string and extract potential custom element names
    func extractCustomElementNames(from text: String) -> [String] {
        let pattern = "\\{[^\\{\\}]+\\}"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = text as NSString
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        return matches.map { match in
            nsString.substring(with: match.range)
        }
    }
    
    /// Reset all custom element values to their defaults
    func resetCustomElements() {
        for element in customElements {
            element.resetToDefault()
        }
    }
    
    /// Increment any counter elements
    func incrementCounters() {
        for element in customElements where element.type == .counter {
            element.incrementCounter()
        }
    }
}

/// Manages transfer presets (saving and loading)
class TransferPresetManager {
    private static let presetsKey = "MediaForgeTransferPresets"
    
    /// Load saved presets from user defaults
    static func loadPresets() -> [TransferPreset] {
        if let data = UserDefaults.standard.data(forKey: presetsKey) {
            do {
                let presets = try JSONDecoder().decode([TransferPreset].self, from: data)
                return presets
            } catch {
                print("Error loading presets: \(error)")
                return [TransferPreset()]
            }
        }
        return [TransferPreset()]
    }
    
    /// Save presets to user defaults
    static func savePresets(_ presets: [TransferPreset]) {
        do {
            let data = try JSONEncoder().encode(presets)
            UserDefaults.standard.set(data, forKey: presetsKey)
        } catch {
            print("Error saving presets: \(error)")
        }
    }
} 