import Foundation
import SwiftUI
import AppKit

/// Collection to organize catalog items
class MediaCollection: Identifiable, Codable, ObservableObject {
    var id = UUID()
    @Published var name: String
    @Published var items: [CatalogItem.ID]
    @Published var color: Color?
    @Published var notes: String
    @Published var dateCreated: Date
    
    init(name: String, items: [CatalogItem.ID] = [], notes: String = "") {
        self.name = name
        self.items = items
        self.notes = notes
        self.dateCreated = Date()
    }
    
    // MARK: - Codable Support
    
    enum CodingKeys: String, CodingKey {
        case id, name, items, colorData, notes, dateCreated
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        items = try container.decode([UUID].self, forKey: .items)
        
        if let colorData = try container.decodeIfPresent(Data.self, forKey: .colorData),
           let nsColor = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            color = Color(nsColor: nsColor)
        }
        
        notes = try container.decode(String.self, forKey: .notes)
        dateCreated = try container.decode(Date.self, forKey: .dateCreated)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(items, forKey: .items)
        
        if let color = color {
            // Convert Color to NSColor safely
            let nsColor = NSColor(color)
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false)
            try container.encode(colorData, forKey: .colorData)
        }
        
        try container.encode(notes, forKey: .notes)
        try container.encode(dateCreated, forKey: .dateCreated)
    }
} 