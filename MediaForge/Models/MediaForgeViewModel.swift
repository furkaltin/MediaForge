import Foundation
import SwiftUI

/// Main view model for the MediaForge application
class MediaForgeViewModel: ObservableObject {
    /// All available disks in the system
    @Published var availableDisks: [Disk] = []
    
    /// Disks marked as sources
    @Published var sources: [Disk] = []
    
    /// Disks marked as destinations
    @Published var destinations: [Disk] = []
    
    /// All transfers (active, completed, and queued)
    @Published var transfers: [FileTransfer] = []
    
    /// Show permission error alert
    @Published var showPermissionAlert = false
    
    /// Permission error details for the alert
    @Published var permissionErrorMessage = ""
    @Published var permissionErrorDisk = ""
    
    /// Timer for refreshing disk information
    private var diskRefreshTimer: Timer?
    
    /// Dictionary to track progress objects for cancellation
    private var transferProgressMap: [UUID: Progress] = [:]
    
    /// Currently running transfers
    var activeTransfers: [FileTransfer] {
        transfers.filter { transfer in
            switch transfer.status {
            case .copying, .preparing, .verifying:
                return true
            default:
                return false
            }
        }
    }
    
    /// Completed transfers
    var completedTransfers: [FileTransfer] {
        transfers.filter { $0.status == .completed }
    }
    
    /// Failed transfers
    var failedTransfers: [FileTransfer] {
        transfers.filter {
            if case .failed(_) = $0.status {
                return true
            }
            return false
        }
    }
    
    /// Initialize the view model and load initial disk data
    init() {
        // Initialize Disk Arbitration framework
        DiskManager.initialize()
        
        // Initialize FileTransferManager
        FileTransferManager.initialize()
        
        // Set disk change callback
        DiskManager.diskChangeCallback = { [weak self] in
            self?.refreshDisks()
        }
        
        // Load initial disk data
        loadDisks()
        
        // Set up disk refresh timer
        diskRefreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refreshDisks()
        }
        
        // Set up notification listener for refresh
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRefreshDisksNotification),
            name: NSNotification.Name("RefreshDisks"),
            object: nil
        )
    }
    
    deinit {
        diskRefreshTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleRefreshDisksNotification() {
        refreshDisks()
    }
    
    /// Refresh the list of available disks
    func loadDisks() {
        #if DEBUG
        // Use mock data for previews
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.availableDisks = createMockDisks()
            return
        }
        #endif
        
        // Get real disk data
        let realDisks = DiskManager.getAvailableDisks()
        
        // Make sure to update on main thread
        DispatchQueue.main.async {
            self.availableDisks = realDisks
            print("Loaded \(realDisks.count) disks")
            
            // Print disk details for debugging
            for disk in realDisks {
                print("Disk: \(disk.name), Path: \(disk.path), Size: \(disk.formattedTotalSpace), Free: \(disk.formattedFreeSpace)")
                
                // Try to verify access permissions
                if !FileTransferManager.validatePath(disk.path) {
                    print("⚠️ No permission to access: \(disk.path)")
                    disk.hasFullAccess = false
                } else {
                    disk.hasFullAccess = true
                }
            }
        }
    }
    
    /// Refresh disks but preserve selections
    func refreshDisks() {
        // Get current disk paths
        let currentSourcePaths = sources.map { $0.path }
        let currentDestinationPaths = destinations.map { $0.path }
        
        // Load fresh disk data
        let freshDisks = DiskManager.getAvailableDisks()
        
        // Update on main thread
        DispatchQueue.main.async {
            // Temporary storage for new sources and destinations
            var newSources: [Disk] = []
            var newDestinations: [Disk] = []
            
            // Update the disk list
            self.availableDisks = freshDisks
            
            // Verify disk permissions
            for disk in freshDisks {
                // Try to verify access permissions
                if !FileTransferManager.validatePath(disk.path) {
                    print("⚠️ No permission to access: \(disk.path)")
                    disk.hasFullAccess = false
                } else {
                    disk.hasFullAccess = true
                }
            }
            
            // Restore selections based on path matching
            for disk in freshDisks {
                if currentSourcePaths.contains(disk.path) {
                    disk.setAsSource()
                    newSources.append(disk)
                } else if currentDestinationPaths.contains(disk.path) {
                    disk.setAsDestination()
                    newDestinations.append(disk)
                }
            }
            
            // Replace sources and destinations with the fresh references
            self.sources = newSources
            self.destinations = newDestinations
            
            print("Refreshed disks: \(freshDisks.count) disks, \(newSources.count) sources, \(newDestinations.count) destinations")
        }
    }
    
    /// Mock disk creation for testing purposes
    private func createMockDisks() -> [Disk] {
        // Get the user's home directory for more realistic testing
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        
        let userDocuments = Disk(
            name: "Documents", 
            path: "\(homeDirectory)/Documents", 
            icon: "folder", 
            totalSpace: 1_000_000_000_000, 
            usedSpace: 100_000_000_000
        )
        
        let userDesktop = Disk(
            name: "Desktop", 
            path: "\(homeDirectory)/Desktop", 
            icon: "desktopcomputer", 
            totalSpace: 1_000_000_000_000, 
            usedSpace: 50_000_000_000
        )
        
        let userDownloads = Disk(
            name: "Downloads", 
            path: "\(homeDirectory)/Downloads", 
            icon: "arrow.down.circle", 
            totalSpace: 1_000_000_000_000, 
            usedSpace: 200_000_000_000
        )
        
        let tempdisk = Disk(
            name: "External Drive", 
            path: "/tmp", 
            icon: "externaldrive.fill", 
            totalSpace: 2_000_000_000_000, 
            usedSpace: 500_000_000_000
        )
        
        return [userDocuments, userDesktop, userDownloads, tempdisk]
    }
    
    /// Set a disk as a source
    func setDiskAsSource(_ disk: Disk) {
        // Check permission before setting as source
        if !disk.hasFullAccess {
            requestPermissionFor(disk) { [weak self] success in
                if success {
                    disk.hasFullAccess = true
                    self?.setDiskAsSource(disk)
                } else {
                    self?.showPermissionErrorAlert(for: disk, isSource: true)
                }
            }
            return
        }
        
        disk.setAsSource()
        if !sources.contains(where: { $0.id == disk.id }) {
            sources.append(disk)
        }
    }
    
    /// Set a disk as a destination
    func setDiskAsDestination(_ disk: Disk) {
        // Check permission before setting as destination
        if !disk.hasFullAccess {
            requestPermissionFor(disk) { [weak self] success in
                if success {
                    disk.hasFullAccess = true
                    self?.setDiskAsDestination(disk)
                } else {
                    self?.showPermissionErrorAlert(for: disk, isSource: false)
                }
            }
            return
        }
        
        disk.setAsDestination()
        if !destinations.contains(where: { $0.id == disk.id }) {
            destinations.append(disk)
        }
    }
    
    /// Request user permission for a disk
    func requestPermissionFor(_ disk: Disk, completion: @escaping (Bool) -> Void) {
        FileTransferManager.requestPermissionFor(path: disk.path) { success in
            DispatchQueue.main.async {
                if success {
                    // Verify the access by validating the path again
                    if FileTransferManager.validatePath(disk.path) {
                        disk.hasFullAccess = true
                        completion(true)
                    } else {
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }
    }
    
    /// Show permission error alert for a disk
    func showPermissionErrorAlert(for disk: Disk, isSource: Bool) {
        permissionErrorDisk = disk.name
        permissionErrorMessage = """
        MediaForge needs full access permission to \(disk.name) to \(isSource ? "read from" : "write to") it.
        
        Please go to System Settings > Privacy & Security > Full Disk Access and add MediaForge to the list of allowed applications.
        
        For external devices like camera cards, you may need to:
        1. Eject the device
        2. Give MediaForge full disk access
        3. Re-insert the device
        """
        showPermissionAlert = true
    }
    
    /// Remove a disk from sources and destinations
    func setDiskAsUnused(_ disk: Disk) {
        disk.setAsUnused()
        sources.removeAll(where: { $0.id == disk.id })
        destinations.removeAll(where: { $0.id == disk.id })
    }
    
    /// Create new transfers from current sources to destinations
    func createTransfers() {
        guard !sources.isEmpty && !destinations.isEmpty else {
            print("Cannot create transfers: Need at least one source and one destination")
            return // Need at least one source and one destination
        }
        
        // Check permissions before creating transfers
        for source in sources {
            if !source.hasFullAccess {
                showPermissionErrorAlert(for: source, isSource: true)
                return
            }
        }
        
        for destination in destinations {
            if !destination.hasFullAccess {
                showPermissionErrorAlert(for: destination, isSource: false)
                return
            }
        }
        
        print("Creating transfers from \(sources.count) sources to \(destinations.count) destinations")
        
        // Create a transfer for each source-destination pair
        for source in sources {
            for destination in destinations {
                let transfer = FileTransfer(from: source, to: destination)
                transfers.append(transfer)
                print("Created transfer: \(source.name) -> \(destination.name)")
            }
        }
    }
    
    /// Get the count of transfers that would be created
    var potentialTransferCount: Int {
        sources.count * destinations.count
    }
    
    /// Start all queued transfers
    func startTransfers() {
        for transfer in transfers where transfer.status == .notStarted {
            // Start the transfer
            transfer.start()
            
            // Perform the actual file transfer operation
            performFileTransfer(transfer)
        }
    }
    
    /// Perform the actual file transfer
    private func performFileTransfer(_ transfer: FileTransfer) {
        // Set transfer to preparing state
        transfer.status = .preparing
        
        // Start in background
        DispatchQueue.global(qos: .userInitiated).async {
            // Get source and destination paths
            let sourcePath = transfer.source.path
            let destinationPath = transfer.destination.path
            
            // Double-check permissions at transfer time
            if !FileTransferManager.validatePath(sourcePath) {
                DispatchQueue.main.async {
                    transfer.fail(with: FileTransferManager.TransferError.permissionDenied)
                    self.permissionErrorDisk = transfer.source.name
                    self.permissionErrorMessage = """
                    MediaForge needs full access permission to \(transfer.source.name) to read from it.
                    
                    Please go to System Settings > Privacy & Security > Full Disk Access and add MediaForge to the list of allowed applications.
                    """
                    self.showPermissionAlert = true
                }
                return
            }
            
            if !FileTransferManager.validatePath(destinationPath) {
                DispatchQueue.main.async {
                    transfer.fail(with: FileTransferManager.TransferError.permissionDenied)
                    self.permissionErrorDisk = transfer.destination.name
                    self.permissionErrorMessage = """
                    MediaForge needs full access permission to \(transfer.destination.name) to write to it.
                    
                    Please go to System Settings > Privacy & Security > Full Disk Access and add MediaForge to the list of allowed applications.
                    """
                    self.showPermissionAlert = true
                }
                return
            }
            
            // Create destination folder path
            let sourceLastComponent = URL(fileURLWithPath: sourcePath).lastPathComponent
            let destinationFolderPath = URL(fileURLWithPath: destinationPath)
                .appendingPathComponent(sourceLastComponent)
                .path
            
            print("Starting transfer from \(sourcePath) to \(destinationFolderPath)")
            
            // Define progress handler
            let progressHandler: (Int64, Int64, String) -> Void = { bytesTransferred, totalBytes, currentFile in
                DispatchQueue.main.async {
                    transfer.updateProgress(bytesTransferred: bytesTransferred, 
                                           totalBytes: totalBytes, 
                                           currentFile: currentFile)
                    
                    // Update status
                    if transfer.status == .preparing {
                        transfer.status = .copying
                    }
                }
            }
            
            // Define completion handler
            let completionHandler: (Result<Bool, FileTransferManager.TransferError>) -> Void = { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        transfer.status = .verifying
                        
                        // Normally we'd do validation here
                        // For now, just mark as completed after a brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            transfer.complete()
                            print("Image transfer completed: \(sourcePath) -> \(destinationFolderPath)")
                        }
                        
                    case .failure(let error):
                        transfer.fail(with: error)
                        print("Transfer failed: \(error.localizedDescription)")
                        
                        // Show permission error dialog if needed
                        if case .permissionDenied = error {
                            self.permissionErrorDisk = transfer.source.name
                            self.permissionErrorMessage = """
                            MediaForge needs full access permission to your files.
                            
                            Please go to System Settings > Privacy & Security > Full Disk Access and add MediaForge to the list of allowed applications.
                            """
                            self.showPermissionAlert = true
                        }
                    }
                }
            }
            
            // Start the transfer
            let progress = FileTransferManager.copyDirectory(
                from: sourcePath,
                to: destinationFolderPath,
                progressHandler: progressHandler,
                completionHandler: completionHandler
            )
            
            // Store the progress object for cancellation
            DispatchQueue.main.async {
                self.transferProgressMap[transfer.id] = progress
            }
        }
    }
    
    /// Cancel a transfer
    func cancelTransfer(_ transfer: FileTransfer) {
        if let progress = transferProgressMap[transfer.id] {
            progress.cancel()
            transferProgressMap.removeValue(forKey: transfer.id)
            print("Cancelled transfer: \(transfer.source.name) -> \(transfer.destination.name)")
        } else {
            FileTransferManager.cancelTransfer(transfer)
        }
    }
    
    /// Clear all completed transfers from the list
    func clearCompletedTransfers() {
        DispatchQueue.main.async {
            self.transfers.removeAll(where: { $0.status == .completed })
        }
    }
    
    /// Clear all failed transfers from the list
    func clearFailedTransfers() {
        DispatchQueue.main.async {
            self.transfers.removeAll(where: { 
                if case .failed(_) = $0.status {
                    return true
                }
                return false
            })
        }
    }
    
    /// Open System Settings to Full Disk Access
    func openSystemSettingsForPermissions() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
} 