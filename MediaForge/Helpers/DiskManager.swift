import Foundation
import IOKit
import IOKit.storage
import DiskArbitration

/// Manages disk information and operations
class DiskManager {
    
    /// Callback for disk mount notifications
    static var diskChangeCallback: (() -> Void)?
    
    /// Singleton disk arbitration session
    private static var daSession: DASession?
    
    /// Initialize disk arbitration
    static func initialize() {
        // Create a disk arbitration session if not already created
        if daSession == nil {
            daSession = DASessionCreate(kCFAllocatorDefault)
            
            // Schedule the session on the main run loop
            if let session = daSession {
                DASessionScheduleWithRunLoop(session, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
                
                // Register for disk appearance notifications
                registerForDiskNotifications()
            }
        }
    }
    
    /// Register for disk mount/unmount notifications
    private static func registerForDiskNotifications() {
        // Get notification center
        let nc = NotificationCenter.default
        
        // Register for volume mount notifications
        nc.addObserver(
            forName: .init("com.apple.DiskArbitration.DADiskDidAppear"),
            object: nil,
            queue: nil
        ) { _ in
            // Call refresh callback
            diskChangeCallback?()
        }
        
        // Register for volume unmount notifications
        nc.addObserver(
            forName: .init("com.apple.DiskArbitration.DADiskDidDisappear"),
            object: nil,
            queue: nil
        ) { _ in
            // Call refresh callback
            diskChangeCallback?()
        }
    }
    
    /// Get all available disks on the system
    static func getAvailableDisks() -> [Disk] {
        // Initialize disk arbitration system if needed
        initialize()
        
        var disks: [Disk] = []
        
        // Get volume URLs using both approaches
        if let volumeURLs = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey], options: [.skipHiddenVolumes]) {
            // Process each volume using FileManager
            for url in volumeURLs {
                if let disk = diskFromURL(url) {
                    disks.append(disk)
                }
            }
        }
        
        // Also use IOKit approach to get more disks
        if let additionalDisks = getDisksViaIOKit() {
            // Filter out duplicates and non-mountable partition schemes
            for disk in additionalDisks {
                // Skip partition schemes that aren't actual mountable volumes
                if disk.name == "GUID_partition_scheme" || 
                   disk.name == "FDisk_partition_scheme" || 
                   disk.name.hasSuffix("-0000-11AA-AA11-00306543ECAC") {
                    continue
                }
                
                if !disks.contains(where: { $0.path == disk.path }) {
                    disks.append(disk)
                }
            }
        }
        
        return disks
    }
    
    /// Create a Disk object from a volume URL
    private static func diskFromURL(_ url: URL) -> Disk? {
        do {
            // Get volume properties
            let resourceValues = try url.resourceValues(forKeys: [
                .volumeNameKey,
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey,
                .volumeIsRemovableKey,
                .volumeIsEjectableKey
            ])
            
            // Skip if no name
            guard let name = resourceValues.volumeName else { return nil }
            
            // Determine the icon based on volume type
            var icon = "externaldrive"
            if resourceValues.volumeIsRemovable == true {
                icon = "externaldrive.badge.xmark"
            } else if resourceValues.volumeIsEjectable == true {
                icon = "externaldrive.fill"
            } else if url.path == "/" {
                // System drive
                icon = "macmini"
            } else if url.path.contains("network") || url.path.contains("net") {
                icon = "network"
            }
            
            // Calculate space
            let totalSpace = resourceValues.volumeTotalCapacity ?? 0
            let freeSpace = resourceValues.volumeAvailableCapacity ?? 0
            let usedSpace = totalSpace - freeSpace
            
            // Create the disk object
            let disk = Disk(
                name: name,
                path: url.path,
                icon: icon,
                totalSpace: Int64(totalSpace),
                usedSpace: Int64(usedSpace)
            )
            
            return disk
        } catch {
            print("Error getting disk properties: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get disks using low-level IOKit approach (more reliable for external media)
    private static func getDisksViaIOKit() -> [Disk]? {
        var disks: [Disk] = []
        
        // Get the IO Master Port - Use kIOMainPortDefault in macOS 12+
        var masterPort: mach_port_t = 0
        #if swift(>=5.5)
        // macOS 12+ way
        masterPort = kIOMainPortDefault
        #else
        // Older macOS way
        let result = IOMasterPort(mach_port_t(MACH_PORT_NULL), &masterPort)
        if result != KERN_SUCCESS {
            return nil
        }
        #endif
        
        // Create a matching dictionary for IOMedia
        if let matchingDict = IOServiceMatching("IOMedia") as CFMutableDictionary? {
            // Only get mounted volumes
            // Define key for mounted volumes
            let key = "Whole" as CFString
            CFDictionarySetValue(matchingDict, Unmanaged.passUnretained(key).toOpaque(), Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
            
            // Create iterator
            var iterator: io_iterator_t = 0
            if IOServiceGetMatchingServices(masterPort, matchingDict, &iterator) == KERN_SUCCESS {
                // Get each device and create disk objects
                var device: io_object_t = 0
                repeat {
                    device = IOIteratorNext(iterator)
                    if device != 0 {
                        if let disk = createDiskFromIODevice(device) {
                            disks.append(disk)
                        }
                        IOObjectRelease(device)
                    }
                } while device != 0
                
                IOObjectRelease(iterator)
            }
        }
        
        return disks
    }
    
    /// Create a Disk object from an IOKit device
    private static func createDiskFromIODevice(_ device: io_object_t) -> Disk? {
        // Get the volume (BSD) name
        let bsdNameKey = kIOBSDNameKey as CFString
        guard let bsdNameAsCFString = IORegistryEntryCreateCFProperty(device, bsdNameKey, kCFAllocatorDefault, 0) else {
            return nil
        }
        
        guard let bsdName = bsdNameAsCFString.takeRetainedValue() as? String else {
            return nil
        }
        
        // Get the volume name
        let volumeNameKey = kIOMediaContentKey as CFString
        guard let volumeNameAsCFString = IORegistryEntryCreateCFProperty(device, volumeNameKey, kCFAllocatorDefault, 0) else {
            return nil
        }
        
        guard let volumeName = volumeNameAsCFString.takeRetainedValue() as? String else {
            return nil
        }
        
        // Instead of assuming /Volumes/volumeName, let's find the actual mount path
        let devicePath = "/dev/\(bsdName)"
        var mountPath: String? = nil
        
        // Try to find the actual mount path by checking mounted volumes
        if let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeNameKey], options: [.skipHiddenVolumes]) {
            for volumeURL in volumes {
                do {
                    if let name = try volumeURL.resourceValues(forKeys: [.volumeNameKey]).volumeName,
                       name == volumeName {
                        mountPath = volumeURL.path
                        break
                    }
                } catch {
                    print("Error getting volume name: \(error)")
                }
            }
        }
        
        // Fall back to /Volumes/volumeName if we couldn't find the actual path
        if mountPath == nil {
            mountPath = "/Volumes/\(volumeName)"
        }
        
        guard let path = mountPath, FileManager.default.fileExists(atPath: path) else {
            print("Mount path not found for \(volumeName)")
            return nil
        }
        
        let fileManager = FileManager.default
        
        // Try to get disk statistics
        var totalSpace: Int64 = 0
        var usedSpace: Int64 = 0
        
        do {
            let attrs = try fileManager.attributesOfFileSystem(forPath: path)
            if let size = attrs[.systemSize] as? NSNumber {
                totalSpace = size.int64Value
            }
            if let free = attrs[.systemFreeSize] as? NSNumber {
                let freeSpace = free.int64Value
                usedSpace = totalSpace - freeSpace
            }
        } catch {
            // Use default values if we can't get actual size
            print("Error getting disk attributes: \(error)")
            totalSpace = 1_000_000_000_000 // 1 TB
            usedSpace = 0
        }
        
        // Create disk object
        let disk = Disk(
            name: volumeName,
            path: path,
            icon: "externaldrive.fill.badge",
            totalSpace: totalSpace,
            usedSpace: usedSpace
        )
        
        return disk
    }
    
    /// Check if a path exists
    static func pathExists(_ path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    /// Get the size of a file or directory
    static func getSize(of path: String) -> Int64 {
        let fileManager = FileManager.default
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            if let size = attributes[.size] as? Int64 {
                return size
            } else if fileManager.fileExists(atPath: path, isDirectory: nil) {
                // It's a directory, calculate recursively
                return getDirectorySize(path)
            }
        } catch {
            print("Error getting size: \(error.localizedDescription)")
        }
        
        return 0
    }
    
    /// Calculate directory size recursively
    private static func getDirectorySize(_ path: String) -> Int64 {
        let fileManager = FileManager.default
        var size: Int64 = 0
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            for item in contents {
                let itemPath = path + "/" + item
                size += getSize(of: itemPath)
            }
        } catch {
            print("Error calculating directory size: \(error.localizedDescription)")
        }
        
        return size
    }
    
    /// Eject a disk
    static func ejectDisk(_ disk: Disk, completion: @escaping (Bool, String?) -> Void) {
        // Skip the DiskArbitration framework approach since it's causing issues
        // Just use the more reliable diskutil command directly
        ejectUsingDiskUtil(disk, completion: completion)
    }
    
    /// Eject a disk using diskutil command
    private static func ejectUsingDiskUtil(_ disk: Disk, completion: @escaping (Bool, String?) -> Void) {
        let task = Process()
        task.launchPath = "/usr/sbin/diskutil"
        task.arguments = ["eject", disk.path]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let success = task.terminationStatus == 0
            completion(success, success ? nil : output)
        } catch {
            completion(false, error.localizedDescription)
        }
    }
} 