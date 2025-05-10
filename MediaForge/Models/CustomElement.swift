import Foundation

/// Represents a custom element that can be used in transfer presets
class CustomElement: Identifiable, ObservableObject, Codable {
    enum ElementType: String, Codable, CaseIterable {
        case text
        case date
        case select
        case counter
        case number
        case hidden
        
        var description: String {
            switch self {
            case .text: return "Text"
            case .date: return "Date"
            case .select: return "Dropdown"
            case .counter: return "Counter"
            case .number: return "Number"
            case .hidden: return "Hidden"
            }
        }
    }
    
    var id: UUID
    @Published var name: String
    @Published var type: ElementType
    @Published var defaultValue: String
    @Published var currentValue: String
    @Published var options: [SelectOption]
    
    var displayName: String {
        // Remove curly braces if present
        let strippedName = name.trimmingCharacters(in: CharacterSet(charactersIn: "{}"))
        return strippedName
    }
    
    var templateName: String {
        // Ensure name has curly braces
        if name.hasPrefix("{") && name.hasSuffix("}") {
            return name
        }
        return "{\(name)}"
    }
    
    init(name: String, type: ElementType = .text, defaultValue: String = "", currentValue: String = "", options: [SelectOption] = []) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.currentValue = currentValue.isEmpty ? defaultValue : currentValue
        self.options = options
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case defaultValue
        case currentValue
        case options
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // First decode primitive values
        let decodedId = try container.decode(UUID.self, forKey: .id)
        let decodedName = try container.decode(String.self, forKey: .name)
        let decodedType = try container.decode(ElementType.self, forKey: .type)
        let decodedDefaultValue = try container.decode(String.self, forKey: .defaultValue)
        let decodedOptions = try container.decodeIfPresent([SelectOption].self, forKey: .options) ?? []
        let decodedCurrentValue = try container.decodeIfPresent(String.self, forKey: .currentValue) ?? decodedDefaultValue
        
        // Then initialize properties
        self.id = decodedId
        self.name = decodedName
        self.type = decodedType
        self.defaultValue = decodedDefaultValue
        self.options = decodedOptions
        self.currentValue = decodedCurrentValue
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(defaultValue, forKey: .defaultValue)
        try container.encode(currentValue, forKey: .currentValue)
        try container.encode(options, forKey: .options)
    }
    
    // Helper method to increment counter
    func incrementCounter() {
        if type == .counter, let value = Int(currentValue) {
            currentValue = String(format: "%0\(currentValue.count)d", value + 1)
        }
    }
    
    // Helper method to reset to default
    func resetToDefault() {
        currentValue = defaultValue
    }
}

/// Represents an option in a dropdown (select) element
struct SelectOption: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var value: String
    
    init(name: String, value: String? = nil) {
        self.name = name
        self.value = value ?? name
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable
    static func == (lhs: SelectOption, rhs: SelectOption) -> Bool {
        return lhs.id == rhs.id
    }
} 