import Foundation
import SwiftUI

/// Model for configuring media transcoding options
class TranscodingProfile: Identifiable, Codable, ObservableObject {
    var id = UUID()
    @Published var name: String
    
    // MARK: - Output Format Options
    
    enum OutputFormat: String, CaseIterable, Identifiable, Codable {
        case prores422 = "Apple ProRes 422"
        case prores422HQ = "Apple ProRes 422 HQ"
        case prores422LT = "Apple ProRes 422 LT"
        case prores4444 = "Apple ProRes 4444"
        case proresProxy = "Apple ProRes Proxy"
        case h264 = "H.264"
        case h265 = "H.265 / HEVC"
        case dnxhd = "Avid DNxHD"
        case dnxhr = "Avid DNxHR"
        
        var id: String { self.rawValue }
    }
    
    enum ResolutionPreset: String, CaseIterable, Identifiable, Codable {
        case original = "Original Resolution"
        case custom = "Custom Resolution"
        case uhd4k = "UHD 4K (3840×2160)"
        case dci4k = "DCI 4K (4096×2160)"
        case hd1080p = "HD 1080p (1920×1080)"
        case hd720p = "HD 720p (1280×720)"
        case sd = "SD (720×576)"
        case quarterRes = "Quarter Resolution"
        case halfRes = "Half Resolution"
        
        var id: String { self.rawValue }
        
        var dimensions: (width: Int, height: Int)? {
            switch self {
            case .original, .custom, .quarterRes, .halfRes:
                return nil
            case .uhd4k:
                return (3840, 2160)
            case .dci4k:
                return (4096, 2160)
            case .hd1080p:
                return (1920, 1080)
            case .hd720p:
                return (1280, 720)
            case .sd:
                return (720, 576)
            }
        }
    }
    
    enum FittingStrategy: String, CaseIterable, Identifiable, Codable {
        case zoomToFit = "Zoom to Fit (Adding Black Bars)"
        case zoomToFitNoBars = "Zoom to Fit (Without Black Bars)"
        case zoomToFill = "Zoom to Fill"
        case oneToOne = "1:1 (Center Crop)"
        
        var id: String { self.rawValue }
    }
    
    @Published var outputFormat: OutputFormat = .prores422
    @Published var resolutionPreset: ResolutionPreset = .original
    @Published var customWidth: Int = 1920
    @Published var customHeight: Int = 1080
    @Published var fittingStrategy: FittingStrategy = .zoomToFit
    @Published var frameRate: Double? = nil  // nil means "same as source"
    
    // MARK: - Quality & Processing Options
    
    enum DecodingQuality: String, CaseIterable, Identifiable, Codable {
        case autoSelect = "Auto Select"
        case fullResolution = "Full Resolution"
        case halfResolution = "Half Resolution"
        case quarterResolution = "Quarter Resolution"
        
        var id: String { self.rawValue }
    }
    
    @Published var decodingQuality: DecodingQuality = .autoSelect
    @Published var preserveColorDepth: Bool = true
    @Published var quality: Int = 85  // 0-100 for h264/h265, ignored for ProRes
    @Published var audioBitrate: Int = 320  // in kbps
    
    // MARK: - Color Management
    
    enum LookSource: String, CaseIterable, Identifiable, Codable {
        case asInLibrary = "As Set in Library"
        case none = "None"
        case fromFile = "From File"
        
        var id: String { self.rawValue }
    }
    
    @Published var lookSource: LookSource = .asInLibrary
    @Published var applyLUT: Bool = false
    @Published var lutURL: URL?
    
    // MARK: - Overlays & Burn-ins
    
    @Published var burnInOptions: BurnInOptions = BurnInOptions()
    @Published var applyFrameLines: Bool = false
    @Published var frameLineAspectRatio: String = "2.39:1"
    @Published var frameLinesAppearance: FrameLinesAppearance = .solid
    
    enum FrameLinesAppearance: String, CaseIterable, Identifiable, Codable {
        case solid = "Solid"
        case dashed = "Dashed"
        case corners = "Corners"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Output Options
    
    @Published var destinationPath: String = ""
    @Published var filenamePattern: String = "{source_filename}_{preset}"
    @Published var overwriteExisting: Bool = false
    @Published var createSubfolders: Bool = true
    @Published var subfolderPattern: String = "{date}"
    
    // MARK: - Metadata Export
    
    enum MetadataExportFormat: String, CaseIterable, Identifiable, Codable {
        case none = "None"
        case premiereXML = "Adobe Premiere Pro (.XML)"
        case avidALE = "AVID Media Composer (.ALE)"
        case fcp7XML = "Final Cut Pro 7 (.XML)"
        case fcpxXML = "Final Cut Pro X (.FCPXML)"
        case xmlMetadata = "XML Metadata (.XML)"
        
        var id: String { self.rawValue }
    }
    
    @Published var metadataExportFormat: MetadataExportFormat = .none
    
    // MARK: - Initializers
    
    init(name: String = "New Transcoding Profile") {
        self.name = name
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, name, outputFormat, resolutionPreset, customWidth, customHeight,
             fittingStrategy, frameRate, decodingQuality, preserveColorDepth,
             quality, audioBitrate, lookSource, applyLUT, lutURL,
             burnInOptions, applyFrameLines, frameLineAspectRatio, frameLinesAppearance,
             destinationPath, filenamePattern, overwriteExisting, createSubfolders,
             subfolderPattern, metadataExportFormat
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        outputFormat = try container.decode(OutputFormat.self, forKey: .outputFormat)
        resolutionPreset = try container.decode(ResolutionPreset.self, forKey: .resolutionPreset)
        customWidth = try container.decode(Int.self, forKey: .customWidth)
        customHeight = try container.decode(Int.self, forKey: .customHeight)
        fittingStrategy = try container.decode(FittingStrategy.self, forKey: .fittingStrategy)
        frameRate = try container.decodeIfPresent(Double.self, forKey: .frameRate)
        
        decodingQuality = try container.decode(DecodingQuality.self, forKey: .decodingQuality)
        preserveColorDepth = try container.decode(Bool.self, forKey: .preserveColorDepth)
        quality = try container.decode(Int.self, forKey: .quality)
        audioBitrate = try container.decode(Int.self, forKey: .audioBitrate)
        
        lookSource = try container.decode(LookSource.self, forKey: .lookSource)
        applyLUT = try container.decode(Bool.self, forKey: .applyLUT)
        if let urlString = try container.decodeIfPresent(String.self, forKey: .lutURL) {
            lutURL = URL(string: urlString)
        }
        
        burnInOptions = try container.decode(BurnInOptions.self, forKey: .burnInOptions)
        applyFrameLines = try container.decode(Bool.self, forKey: .applyFrameLines)
        frameLineAspectRatio = try container.decode(String.self, forKey: .frameLineAspectRatio)
        frameLinesAppearance = try container.decode(FrameLinesAppearance.self, forKey: .frameLinesAppearance)
        
        destinationPath = try container.decode(String.self, forKey: .destinationPath)
        filenamePattern = try container.decode(String.self, forKey: .filenamePattern)
        overwriteExisting = try container.decode(Bool.self, forKey: .overwriteExisting)
        createSubfolders = try container.decode(Bool.self, forKey: .createSubfolders)
        subfolderPattern = try container.decode(String.self, forKey: .subfolderPattern)
        
        metadataExportFormat = try container.decode(MetadataExportFormat.self, forKey: .metadataExportFormat)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        try container.encode(outputFormat, forKey: .outputFormat)
        try container.encode(resolutionPreset, forKey: .resolutionPreset)
        try container.encode(customWidth, forKey: .customWidth)
        try container.encode(customHeight, forKey: .customHeight)
        try container.encode(fittingStrategy, forKey: .fittingStrategy)
        try container.encode(frameRate, forKey: .frameRate)
        
        try container.encode(decodingQuality, forKey: .decodingQuality)
        try container.encode(preserveColorDepth, forKey: .preserveColorDepth)
        try container.encode(quality, forKey: .quality)
        try container.encode(audioBitrate, forKey: .audioBitrate)
        
        try container.encode(lookSource, forKey: .lookSource)
        try container.encode(applyLUT, forKey: .applyLUT)
        try container.encode(lutURL?.absoluteString, forKey: .lutURL)
        
        try container.encode(burnInOptions, forKey: .burnInOptions)
        try container.encode(applyFrameLines, forKey: .applyFrameLines)
        try container.encode(frameLineAspectRatio, forKey: .frameLineAspectRatio)
        try container.encode(frameLinesAppearance, forKey: .frameLinesAppearance)
        
        try container.encode(destinationPath, forKey: .destinationPath)
        try container.encode(filenamePattern, forKey: .filenamePattern)
        try container.encode(overwriteExisting, forKey: .overwriteExisting)
        try container.encode(createSubfolders, forKey: .createSubfolders)
        try container.encode(subfolderPattern, forKey: .subfolderPattern)
        
        try container.encode(metadataExportFormat, forKey: .metadataExportFormat)
    }
    
    // MARK: - Factory Methods
    
    /// Create a proxy transcoding profile for editorial
    static func createProxyProfile() -> TranscodingProfile {
        let profile = TranscodingProfile(name: "Editorial Proxy")
        profile.outputFormat = .proresProxy
        profile.resolutionPreset = .hd1080p
        profile.fittingStrategy = .zoomToFit
        profile.decodingQuality = .autoSelect
        profile.lookSource = .asInLibrary
        
        // Add burn-ins for editorial
        profile.burnInOptions.burnInType = .clipNameAndTimecode
        profile.burnInOptions.alignment = .bottomLeft
        
        return profile
    }
    
    /// Create a dailies transcoding profile
    static func createDailiesProfile() -> TranscodingProfile {
        let profile = TranscodingProfile(name: "Dailies H.264")
        profile.outputFormat = .h264
        profile.resolutionPreset = .hd1080p
        profile.fittingStrategy = .zoomToFit
        profile.quality = 85
        profile.lookSource = .asInLibrary
        
        // Add burn-ins for dailies
        profile.burnInOptions.burnInType = .customText
        profile.burnInOptions.customText = "Scene: $scene$ - Take: $take$ - $timecode$"
        profile.burnInOptions.alignment = .bottomLeft
        profile.burnInOptions.backgroundStyle = .box
        
        return profile
    }
    
    /// Create a full quality ProRes archival profile
    static func createArchivalProfile() -> TranscodingProfile {
        let profile = TranscodingProfile(name: "Archival ProRes 422 HQ")
        profile.outputFormat = .prores422HQ
        profile.resolutionPreset = .original
        profile.fittingStrategy = .zoomToFit
        profile.decodingQuality = .fullResolution
        profile.lookSource = .none  // No color grading for archival
        
        // No burn-ins for archival
        profile.burnInOptions.burnInType = .none
        
        return profile
    }
} 