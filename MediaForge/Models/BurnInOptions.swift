import Foundation
import SwiftUI
import AppKit

/// Model for managing burn-in options for overlays on media
class BurnInOptions: Identifiable, Codable, ObservableObject {
    var id = UUID()
    
    /// Available burn-in types
    enum BurnInType: String, CaseIterable, Identifiable, Codable {
        case none = "None"
        case clipName = "Clip Name"
        case clipNameAndTimecode = "Clip Name & Timecode"
        case timecode = "Timecode"
        case sourceFilename = "Source Filename"
        case dateAndTime = "Date & Time"
        case customText = "Custom Text"
        case customMetadata = "Custom Metadata Fields"
        
        var id: String { self.rawValue }
    }
    
    /// Text alignment options
    enum TextAlignment: String, CaseIterable, Identifiable, Codable {
        case topLeft = "Top Left"
        case top = "Top"
        case topRight = "Top Right"
        case left = "Left"
        case center = "Center"
        case right = "Right"
        case bottomLeft = "Bottom Left"
        case bottom = "Bottom"
        case bottomRight = "Bottom Right"
        
        var id: String { self.rawValue }
    }
    
    /// Background options for burn-in text
    enum BackgroundStyle: String, CaseIterable, Identifiable, Codable {
        case none = "None"
        case box = "Box"
        case outline = "Outline"
        case shadow = "Shadow"
        
        var id: String { self.rawValue }
    }
    
    /// Types of burn-in to apply
    @Published var burnInType: BurnInType = .clipNameAndTimecode
    
    /// Custom text for burn-in when burnInType is .customText
    @Published var customText: String = ""
    
    /// Selected metadata fields when burnInType is .customMetadata
    @Published var selectedMetadataFields: [String] = []
    
    /// Appearance options
    @Published var horizontalMargin: CGFloat = 10
    @Published var verticalMargin: CGFloat = 10
    @Published var fontName: String = "Helvetica"
    @Published var fontSize: CGFloat = 18
    @Published var transparency: CGFloat = 0.0  // 0.0 is fully opaque, 1.0 is transparent
    @Published var textColor: Color = .white
    @Published var backgroundColor: Color = .black
    @Published var backgroundStyle: BackgroundStyle = .box
    @Published var alignment: TextAlignment = .bottomLeft
    
    /// Image overlay options
    @Published var overlayImageEnabled: Bool = false
    @Published var overlayImageURL: URL?
    @Published var overlayImageSize: CGFloat = 0.2  // Percentage of screen size (0.0-1.0)
    @Published var overlayImagePositionX: CGFloat = 0.9  // Normalized position (0.0-1.0)
    @Published var overlayImagePositionY: CGFloat = 0.1  // Normalized position (0.0-1.0)
    @Published var overlayImageTransparency: CGFloat = 0.0  // 0.0 is fully opaque, 1.0 is transparent
    
    // Initialize with default values
    init() {}
    
    // MARK: - Codable Support
    
    enum CodingKeys: String, CodingKey {
        case id, burnInType, customText, selectedMetadataFields,
             horizontalMargin, verticalMargin, fontName, fontSize,
             transparency, textColor, backgroundColor, backgroundStyle,
             alignment, overlayImageEnabled, overlayImageURL,
             overlayImageSize, overlayImagePositionX, overlayImagePositionY,
             overlayImageTransparency
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        burnInType = try container.decode(BurnInType.self, forKey: .burnInType)
        customText = try container.decode(String.self, forKey: .customText)
        selectedMetadataFields = try container.decode([String].self, forKey: .selectedMetadataFields)
        
        horizontalMargin = try container.decode(CGFloat.self, forKey: .horizontalMargin)
        verticalMargin = try container.decode(CGFloat.self, forKey: .verticalMargin)
        fontName = try container.decode(String.self, forKey: .fontName)
        fontSize = try container.decode(CGFloat.self, forKey: .fontSize)
        transparency = try container.decode(CGFloat.self, forKey: .transparency)
        
        // Since Color is not directly Codable, we'll use a simpler strategy
        // Just decode a string representation
        if let textColorString = try? container.decode(String.self, forKey: .textColor),
           let nsColor = NSColor(hexString: textColorString) {
            textColor = Color(nsColor: nsColor)
        } else {
            textColor = .white
        }
        
        if let backgroundColorString = try? container.decode(String.self, forKey: .backgroundColor),
           let nsColor = NSColor(hexString: backgroundColorString) {
            backgroundColor = Color(nsColor: nsColor)
        } else {
            backgroundColor = .black
        }
        
        backgroundStyle = try container.decode(BackgroundStyle.self, forKey: .backgroundStyle)
        alignment = try container.decode(TextAlignment.self, forKey: .alignment)
        
        overlayImageEnabled = try container.decode(Bool.self, forKey: .overlayImageEnabled)
        if let urlString = try container.decodeIfPresent(String.self, forKey: .overlayImageURL) {
            overlayImageURL = URL(string: urlString)
        }
        overlayImageSize = try container.decode(CGFloat.self, forKey: .overlayImageSize)
        overlayImagePositionX = try container.decode(CGFloat.self, forKey: .overlayImagePositionX)
        overlayImagePositionY = try container.decode(CGFloat.self, forKey: .overlayImagePositionY)
        overlayImageTransparency = try container.decode(CGFloat.self, forKey: .overlayImageTransparency)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(burnInType, forKey: .burnInType)
        try container.encode(customText, forKey: .customText)
        try container.encode(selectedMetadataFields, forKey: .selectedMetadataFields)
        
        try container.encode(horizontalMargin, forKey: .horizontalMargin)
        try container.encode(verticalMargin, forKey: .verticalMargin)
        try container.encode(fontName, forKey: .fontName)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(transparency, forKey: .transparency)
        
        // Store colors as hex strings
        let nsTextColor = NSColor(textColor)
        try container.encode(nsTextColor.hexString, forKey: .textColor)
        
        let nsBackgroundColor = NSColor(backgroundColor)
        try container.encode(nsBackgroundColor.hexString, forKey: .backgroundColor)
        
        try container.encode(backgroundStyle, forKey: .backgroundStyle)
        try container.encode(alignment, forKey: .alignment)
        
        try container.encode(overlayImageEnabled, forKey: .overlayImageEnabled)
        try container.encode(overlayImageURL?.absoluteString, forKey: .overlayImageURL)
        try container.encode(overlayImageSize, forKey: .overlayImageSize)
        try container.encode(overlayImagePositionX, forKey: .overlayImagePositionX)
        try container.encode(overlayImagePositionY, forKey: .overlayImagePositionY)
        try container.encode(overlayImageTransparency, forKey: .overlayImageTransparency)
    }
    
    /// Get a mapping of available metadata wildcards
    static func availableMetadataWildcards() -> [String: String] {
        return [
            "$clipname$": "Clip Name",
            "$scene$": "Scene",
            "$shot$": "Shot", 
            "$take$": "Take",
            "$timecode$": "Timecode",
            "$camera$": "Camera",
            "$lens$": "Lens",
            "$date$": "Date",
            "$time$": "Time",
            "$filesize$": "File Size",
            "$format$": "Format",
            "$resolution$": "Resolution",
            "$framecount$": "Frame Count",
            "$framerate$": "Frame Rate",
            "$duration$": "Duration"
        ]
    }
    
    /// Process a custom text string to replace wildcards with actual values
    func processCustomText(customText: String, metadata: [String: String]) -> String {
        var result = customText
        
        for (key, value) in metadata {
            let wildcard = "$\(key)$"
            result = result.replacingOccurrences(of: wildcard, with: value)
        }
        
        return result
    }
}

// MARK: - NSColor Helpers for Color Coding

extension NSColor {
    var hexString: String {
        guard let rgbColor = self.usingColorSpace(.sRGB) else {
            return "#000000"
        }
        
        let red = Int(round(rgbColor.redComponent * 255.0))
        let green = Int(round(rgbColor.greenComponent * 255.0))
        let blue = Int(round(rgbColor.blueComponent * 255.0))
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    convenience init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        guard Scanner(string: hex).scanHexInt64(&int) else {
            return nil
        }
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension Color {
    init(nsColor: NSColor) {
        self.init(nsColor)
    }
} 