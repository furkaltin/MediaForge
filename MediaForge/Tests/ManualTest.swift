import Foundation
import AppKit

/// A simple script to manually test the MediaForge functionality after our fixes
class ManualTest {
    
    static func main() {
        print("MediaForge Manual Test")
        print("======================")
        
        // Initialize the disk manager
        DiskManager.initialize()
        
        // Initialize the file transfer manager
        FileTransferManager.initialize()
        
        // Test 1: List all available disks
        testDiskDetection()
        
        // Test 2: Check permissions for each disk
        testDiskPermissions()
        
        // Exit message
        print("\nTests completed. Press Enter to exit...")
        _ = readLine()
    }
    
    static func testDiskDetection() {
        print("\n1. Detecting Available Disks...")
        let disks = DiskManager.getAvailableDisks()
        
        if disks.isEmpty {
            print("No disks found.")
            return
        }
        
        print("Found \(disks.count) disks:")
        for (i, disk) in disks.enumerated() {
            print("\n  Disk \(i+1): \(disk.name)")
            print("    Path: \(disk.path)")
            print("    Device Path: \(disk.devicePath)")
            print("    Total Space: \(disk.formattedTotalSpace)")
            print("    Free Space: \(disk.formattedFreeSpace)")
            print("    Type: \(disk.diskType.rawValue)")
            print("    Has Full Access: \(disk.hasFullAccess ? "Yes" : "No")")
        }
    }
    
    static func testDiskPermissions() {
        print("\n2. Checking Disk Permissions...")
        let disks = DiskManager.getAvailableDisks()
        
        for (i, disk) in disks.enumerated() {
            print("\n  Testing access to Disk \(i+1): \(disk.name)")
            
            // Check if we can access the disk
            let hasAccess = FileTransferManager.validatePath(disk.path)
            disk.hasFullAccess = hasAccess
            
            print("    Full Access: \(hasAccess ? "Yes" : "No")")
            
            if !hasAccess {
                print("    Would you like to request permission for this disk? (y/n)")
                if let input = readLine(), input.lowercased() == "y" {
                    print("    Requesting permission...")
                    
                    let semaphore = DispatchSemaphore(value: 0)
                    
                    FileTransferManager.requestPermissionFor(path: disk.path) { success in
                        print("    Permission request result: \(success ? "Granted" : "Denied")")
                        disk.hasFullAccess = success
                        semaphore.signal()
                    }
                    
                    semaphore.wait()
                }
            }
        }
    }
} 