import Foundation
import SwiftUI

/// Custom metadata field definition
class MetadataField: Identifiable, Codable, ObservableObject {
    var id = UUID()
    @Published var name: String
    @Published var type: MetadataFieldType
    @Published var isRequired: Bool
    @Published var defaultValue: String
    @Published var options: [String]  // For dropdown fields
    @Published var isSearchable: Bool
    @Published var showInFileList: Bool
    
    /// Available metadata field types
    enum MetadataFieldType: String, CaseIterable, Identifiable, Codable {
        case text = "Text"
        case number = "Number"
        case date = "Date"
        case time = "Time"
        case boolean = "Boolean"
        case dropdown = "Dropdown"
        
        var id: String { self.rawValue }
    }
    
    init(name: String, type: MetadataFieldType, isRequired: Bool = false, defaultValue: String = "", 
         options: [String] = [], isSearchable: Bool = true, showInFileList: Bool = true) {
        self.name = name
        self.type = type
        self.isRequired = isRequired
        self.defaultValue = defaultValue
        self.options = options
        self.isSearchable = isSearchable
        self.showInFileList = showInFileList
    }
    
    // MARK: - Codable Support
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, isRequired, defaultValue, options, isSearchable, showInFileList
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(MetadataFieldType.self, forKey: .type)
        isRequired = try container.decode(Bool.self, forKey: .isRequired)
        defaultValue = try container.decode(String.self, forKey: .defaultValue)
        options = try container.decode([String].self, forKey: .options)
        isSearchable = try container.decode(Bool.self, forKey: .isSearchable)
        showInFileList = try container.decode(Bool.self, forKey: .showInFileList)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(isRequired, forKey: .isRequired)
        try container.encode(defaultValue, forKey: .defaultValue)
        try container.encode(options, forKey: .options)
        try container.encode(isSearchable, forKey: .isSearchable)
        try container.encode(showInFileList, forKey: .showInFileList)
    }
} 