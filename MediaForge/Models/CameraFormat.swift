import Foundation
import AVFoundation

/// Model for camera format information
struct CameraFormat: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let extensions: [String]
    let manufacturer: String
    let description: String
    let isRaw: Bool
    
    static func == (lhs: CameraFormat, rhs: CameraFormat) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Standard camera formats with file extensions
    static let allFormats: [CameraFormat] = [
        // ARRI cameras
        CameraFormat(
            name: "ARRI ALEXA/AMIRA",
            extensions: ["ari", "arri", "mxf"],
            manufacturer: "ARRI",
            description: "ARRIRAW or ProRes in MXF container",
            isRaw: true
        ),
        
        // RED cameras
        CameraFormat(
            name: "RED R3D",
            extensions: ["r3d"],
            manufacturer: "RED Digital Cinema",
            description: "REDCODE RAW format",
            isRaw: true
        ),
        
        // Sony cameras
        CameraFormat(
            name: "Sony XAVC",
            extensions: ["mxf", "mp4"],
            manufacturer: "Sony",
            description: "XAVC codec in MXF or MP4 container",
            isRaw: false
        ),
        CameraFormat(
            name: "Sony X-OCN",
            extensions: ["mxf"],
            manufacturer: "Sony",
            description: "X-OCN compressed RAW format",
            isRaw: true
        ),
        
        // Canon cameras
        CameraFormat(
            name: "Canon RAW",
            extensions: ["crm", "cr3"],
            manufacturer: "Canon",
            description: "Canon RAW format",
            isRaw: true
        ),
        CameraFormat(
            name: "Canon Cinema RAW Light",
            extensions: ["crm"],
            manufacturer: "Canon",
            description: "Canon compressed RAW format",
            isRaw: true
        ),
        
        // Blackmagic cameras
        CameraFormat(
            name: "Blackmagic RAW",
            extensions: ["braw"],
            manufacturer: "Blackmagic Design",
            description: "Blackmagic RAW format",
            isRaw: true
        ),
        CameraFormat(
            name: "Blackmagic ProRes",
            extensions: ["mov"],
            manufacturer: "Blackmagic Design",
            description: "Apple ProRes in QuickTime container",
            isRaw: false
        ),
        
        // Common video formats
        CameraFormat(
            name: "ProRes",
            extensions: ["mov", "qt"],
            manufacturer: "Apple",
            description: "Apple ProRes codec in QuickTime container",
            isRaw: false
        ),
        CameraFormat(
            name: "H.264",
            extensions: ["mp4", "mov"],
            manufacturer: "Various",
            description: "H.264/AVC codec in MP4 or QuickTime container",
            isRaw: false
        ),
        CameraFormat(
            name: "H.265",
            extensions: ["mp4", "mov"],
            manufacturer: "Various",
            description: "H.265/HEVC codec in MP4 or QuickTime container",
            isRaw: false
        )
    ]
    
    /// Detect format from file extension
    static func detectFormat(from url: URL) -> CameraFormat? {
        let fileExtension = url.pathExtension.lowercased()
        
        // Find matching format
        return allFormats.first { format in
            format.extensions.contains(fileExtension)
        }
    }
    
    /// Get minimal video specs that won't cause compilation issues
    static func detectVideoSpecs(from url: URL) -> [String: String]? {
        var specs: [String: String] = [:]
        
        // Just return the file extension info for now
        // We'll handle the AVFoundation API in a future update when we can test with actual video files
        specs["Format"] = url.pathExtension.uppercased()
        specs["File Size"] = "Unknown"
        
        return specs
    }
} 