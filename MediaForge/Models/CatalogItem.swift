import Foundation
import SwiftUI

/// Catalog item for media management
class CatalogItem: Identifiable, Codable, ObservableObject {
    var id = UUID()
    @Published var name: String
    @Published var type: String  // video, audio, image, etc.
    @Published var filePath: String
    @Published var dateAdded: Date
    @Published var isVerified: Bool
    @Published var duration: TimeInterval?
    @Published var resolution: String?
    @Published var bitrate: Int64?
    @Published var codecInfo: String?
    @Published var metadata: [String: String]
    @Published var customMetadata: [String: String]
    @Published var thumbnailPath: String?
    @Published var tags: [String]
    @Published var rating: Int?  // 1-5 stars
    @Published var notes: String
    @Published var verificationState: VerificationState
    
    enum VerificationState: String, Codable {
        case notVerified = "Not Verified"
        case verifying = "Verifying"
        case verified = "Verified"
        case failed = "Failed"
        case mismatch = "Checksum Mismatch"
    }
    
    init(name: String, type: String, filePath: String) {
        self.name = name
        self.type = type
        self.filePath = filePath
        self.dateAdded = Date()
        self.isVerified = false
        self.metadata = [:]
        self.customMetadata = [:]
        self.tags = []
        self.notes = ""
        self.verificationState = .notVerified
    }
    
    // MARK: - Codable Support
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, filePath, dateAdded, isVerified, duration, resolution,
             bitrate, codecInfo, metadata, customMetadata, thumbnailPath, tags,
             rating, notes, verificationState
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        filePath = try container.decode(String.self, forKey: .filePath)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        resolution = try container.decodeIfPresent(String.self, forKey: .resolution)
        bitrate = try container.decodeIfPresent(Int64.self, forKey: .bitrate)
        codecInfo = try container.decodeIfPresent(String.self, forKey: .codecInfo)
        metadata = try container.decode([String: String].self, forKey: .metadata)
        customMetadata = try container.decode([String: String].self, forKey: .customMetadata)
        thumbnailPath = try container.decodeIfPresent(String.self, forKey: .thumbnailPath)
        tags = try container.decode([String].self, forKey: .tags)
        rating = try container.decodeIfPresent(Int.self, forKey: .rating)
        notes = try container.decode(String.self, forKey: .notes)
        verificationState = try container.decode(VerificationState.self, forKey: .verificationState)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(filePath, forKey: .filePath)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encode(isVerified, forKey: .isVerified)
        try container.encode(duration, forKey: .duration)
        try container.encode(resolution, forKey: .resolution)
        try container.encode(bitrate, forKey: .bitrate)
        try container.encode(codecInfo, forKey: .codecInfo)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(customMetadata, forKey: .customMetadata)
        try container.encode(thumbnailPath, forKey: .thumbnailPath)
        try container.encode(tags, forKey: .tags)
        try container.encode(rating, forKey: .rating)
        try container.encode(notes, forKey: .notes)
        try container.encode(verificationState, forKey: .verificationState)
    }
} 