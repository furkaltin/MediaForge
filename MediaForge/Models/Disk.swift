import Foundation

/// Represents a physical disk or volume in the system
class Disk: Identifiable, ObservableObject {
    let id = UUID()
    let name: String
    let path: String
    let icon: String
    
    @Published var isSource: Bool = false
    @Published var isDestination: Bool = false
    @Published var label: String?
    @Published var hasFullAccess: Bool = false
    
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
    
    /// Initialize a disk with its properties
    init(name: String, path: String, icon: String = "externaldrive", totalSpace: Int64, usedSpace: Int64) {
        self.name = name
        self.path = path
        self.icon = icon
        self.totalSpace = totalSpace
        self.usedSpace = usedSpace
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
} 