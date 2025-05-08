import Foundation

/// Disk types to identify specific media sources
enum DiskType: String, Codable {
    case internalDrive = "Internal Drive"
    case externalDrive = "External Drive"
    case cameraCard = "Camera Card"
    case networkStorage = "Network Storage"
    case removableMedia = "Removable Media"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .internalDrive:
            return "internaldrive"
        case .externalDrive:
            return "externaldrive.fill"
        case .cameraCard:
            return "sdcard"
        case .networkStorage:
            return "network"
        case .removableMedia:
            return "opticaldiscdrive"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

/// Represents a physical disk or volume in the system
class Disk: Identifiable, ObservableObject {
    let id: String
    let name: String
    let path: String
    let devicePath: String
    var icon: String
    
    @Published var isSource: Bool = false
    @Published var isDestination: Bool = false
    @Published var label: String?
    @Published var hasFullAccess: Bool = false
    @Published var diskType: DiskType = .unknown
    
    // Source and destination path configuration
    @Published var sourceFolder: String?
    @Published var destinationFolder: String?
    
    // Disk capacity and usage
    let totalSpace: Int64
    let usedSpace: Int64
    
    var freeSpace: Int64 {
        return totalSpace - usedSpace
    }
    
    var formattedTotalSpace: String {
        return ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
    }
    
    var formattedFreeSpace: String {
        return ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
    }
    
    var formattedUsedSpace: String {
        return ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
    }
    
    var displayName: String {
        if let label = label, !label.isEmpty {
            return "\(name) (\(label))"
        }
        return name
    }
    
    var freeSpacePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(freeSpace) / Double(totalSpace)
    }
    
    var usedSpacePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }
    
    /// Initialize a disk with its properties
    init(id: String = UUID().uuidString, name: String, path: String, devicePath: String, icon: String = "externaldrive", totalSpace: Int64, freeSpace: Int64, isRemovable: Bool = false) {
        self.id = id
        self.name = name
        self.path = path
        self.devicePath = devicePath
        self.icon = icon
        self.totalSpace = totalSpace
        self.usedSpace = totalSpace - freeSpace
        
        // Try to determine disk type based on path and other characteristics
        determineDiskType()
    }
    
    /// Determine the type of disk based on various characteristics
    private func determineDiskType() {
        let path = self.path.lowercased()
        
        if path.contains("/volumes/") {
            // Check if it's likely a camera card
            if path.contains("dcim") || path.contains("canon") || path.contains("sony") || 
               path.contains("nikon") || path.contains("panasonic") || path.contains("fuji") {
                diskType = .cameraCard
                icon = DiskType.cameraCard.icon
                return
            }
            
            // Check for network storage characteristics
            if path.contains("smb") || path.contains("afp") || path.contains("nfs") {
                diskType = .networkStorage
                icon = DiskType.networkStorage.icon
                return
            }
            
            // Default to external drive
            diskType = .externalDrive
            icon = DiskType.externalDrive.icon
        } else if path.hasPrefix("/") {
            // Internal drive paths typically start with /
            diskType = .internalDrive
            icon = DiskType.internalDrive.icon
        } else {
            diskType = .unknown
            icon = DiskType.unknown.icon
        }
    }
    
    /// Add a label to this disk
    func setLabel(_ newLabel: String) {
        self.label = newLabel
    }
    
    /// Set source folder path (if not using entire disk)
    func setSourceFolder(_ folder: String?) {
        self.sourceFolder = folder
    }
    
    /// Set destination folder path
    func setDestinationFolder(_ folder: String?) {
        self.destinationFolder = folder
    }
    
    /// Set this disk as a source
    func setAsSource() {
        self.isSource = true
        self.isDestination = false
    }
    
    /// Set this disk as a destination
    func setAsDestination() {
        self.isDestination = true
        self.isSource = false
    }
    
    /// Remove this disk from sources and destinations
    func setAsUnused() {
        self.isSource = false
        self.isDestination = false
    }
    
    /// Get the effective source path (full disk or specific folder)
    func getEffectiveSourcePath() -> String {
        if let sourceFolder = sourceFolder, !sourceFolder.isEmpty {
            return sourceFolder
        }
        return path
    }
    
    /// Get the effective destination path (root or specific folder)
    func getEffectiveDestinationPath() -> String {
        if let destinationFolder = destinationFolder, !destinationFolder.isEmpty {
            // Make sure destination folder exists
            let folderPath = "\(path)/\(destinationFolder)"
            let fileManager = FileManager.default
            
            if !fileManager.fileExists(atPath: folderPath) {
                try? fileManager.createDirectory(atPath: folderPath, withIntermediateDirectories: true)
            }
            
            return folderPath
        }
        return path
    }
} 