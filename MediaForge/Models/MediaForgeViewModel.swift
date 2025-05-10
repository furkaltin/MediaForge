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
    
    /// Status message to show notifications to the user
    @Published var statusMessage: String = ""
    
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
    
    // MARK: - Transfer Presets
    
    /// Available transfer presets
    @Published var transferPresets: [TransferPreset] = []
    
    /// Currently active preset
    @Published var activePreset: TransferPreset?
    
    // MARK: - Settings Properties
    
    // General settings
    @Published var showConfirmationDialogs: Bool = true
    @Published var autoStartTransfer: Bool = false
    @Published var playSoundOnComplete: Bool = true
    @Published var createSubfolder: Bool = true
    @Published var generateChecksums: Bool = true
    @Published var createMHL: Bool = false
    
    // Advanced settings
    @Published var maxConcurrentTransfers: Double = 3
    @Published var useNativeCopy: Bool = true
    @Published var skipSystemFiles: Bool = true
    @Published var showDebugInfo: Bool = false
    
    // Verification settings
    @Published var defaultChecksumMethod: String = "xxHash64"
    @Published var defaultVerificationMode: String = "Standard"
    @Published var alwaysVerify: Bool = true
    @Published var stopOnVerificationFailure: Bool = true
    @Published var autoRetryFailedTransfers: Bool = false
    @Published var maxRetryAttempts: Int = 3
    
    // Appearance settings
    @Published var useDarkMode: Bool = true
    @Published var accentColor: Color = .blue
    @Published var animateTransitions: Bool = true
    @Published var useCompactView: Bool = false
    @Published var defaultSortOrder: String = "name"
    @Published var diskViewLayout: String = "grid"
    
    // Selected methods for current transfer
    @Published var selectedChecksumMethod: String = "xxHash64"
    @Published var selectedVerificationMethod: String = "Standard"
    @Published var subfolderPath: String = ""
    
    // Selection states
    @Published var selectedSourceDisk: Disk?
    @Published var selectedDestinationDisk: Disk?
    
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
        
        // Load saved presets
        loadPresets()
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
            devicePath: "/dev/disk1s1", 
            icon: "folder", 
            totalSpace: 1_000_000_000_000, 
            freeSpace: 900_000_000_000
        )
        
        let userDesktop = Disk(
            name: "Desktop", 
            path: "\(homeDirectory)/Desktop", 
            devicePath: "/dev/disk1s1", 
            icon: "desktopcomputer", 
            totalSpace: 1_000_000_000_000, 
            freeSpace: 950_000_000_000
        )
        
        let userDownloads = Disk(
            name: "Downloads", 
            path: "\(homeDirectory)/Downloads", 
            devicePath: "/dev/disk1s1", 
            icon: "arrow.down.circle", 
            totalSpace: 1_000_000_000_000, 
            freeSpace: 800_000_000_000
        )
        
        let tempdisk = Disk(
            name: "External Drive", 
            path: "/tmp", 
            devicePath: "/dev/disk2s1", 
            icon: "externaldrive.fill", 
            totalSpace: 2_000_000_000_000, 
            freeSpace: 1_500_000_000_000
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
    
    /// Set a source folder for a disk
    func setSourceFolder(for disk: Disk, path: String?) {
        disk.setSourceFolder(path)
    }
    
    /// Set a destination folder for a disk
    func setDestinationFolder(for disk: Disk, path: String?) {
        disk.setDestinationFolder(path)
    }
    
    /// Set a label for a disk
    func setLabel(for disk: Disk, label: String?) {
        disk.setLabel(label ?? "")
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
                    
                    // Extract file count information if available
                    if let fileCountRange = currentFile.range(of: "\\d+/\\d+", options: .regularExpression) {
                        let countInfo = String(currentFile[fileCountRange])
                        let parts = countInfo.split(separator: "/")
                        if parts.count == 2, 
                           let completed = Int(parts[0]), 
                           let total = Int(parts[1]) {
                            transfer.completedFiles = completed
                            transfer.totalFiles = total
                        }
                    }
                    
                    // Set transfer status message
                    transfer.transferStatus = currentFile
                    
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
    
    /// Load saved transfer presets
    private func loadPresets() {
        transferPresets = TransferPresetManager.loadPresets()
        
        // Set first preset as active if available
        if let firstPreset = transferPresets.first {
            activePreset = firstPreset
        }
    }
    
    /// Save presets to storage
    private func savePresets() {
        TransferPresetManager.savePresets(transferPresets)
    }
    
    /// Add a new preset
    func addPreset(_ preset: TransferPreset) {
        transferPresets.append(preset)
        savePresets()
    }
    
    /// Update an existing preset
    func updatePreset(_ preset: TransferPreset) {
        if let index = transferPresets.firstIndex(where: { $0.id == preset.id }) {
            transferPresets[index] = preset
            
            // Update active preset if we're editing it
            if activePreset?.id == preset.id {
                activePreset = preset
            }
            
            savePresets()
        }
    }
    
    /// Delete a preset
    func deletePreset(_ preset: TransferPreset) {
        transferPresets.removeAll { $0.id == preset.id }
        
        // Update active preset if needed
        if activePreset?.id == preset.id {
            activePreset = transferPresets.first
        }
        
        savePresets()
    }
    
    /// Apply a preset to the current configuration
    func applyPreset(_ preset: TransferPreset) {
        activePreset = preset
        
        // Apply preset settings to transfer configuration
        if let sourceDisk = selectedSourceDisk, let destinationDisk = selectedDestinationDisk {
            // Create destination subfolder based on preset pattern
            let subfolderPath = preset.createDestinationPath()
            
            // Set up transfer with preset settings
            prepareTransfer(
                source: sourceDisk,
                destination: destinationDisk,
                createSubfolder: true,
                subfolder: subfolderPath,
                checksumMethod: preset.checksumAlgorithm.rawValue,
                verificationMethod: preset.verificationBehavior.rawValue,
                createMHL: preset.createMHL
            )
        }
    }
    
    /// Prepare a transfer with advanced options
    func prepareTransfer(
        source: Disk,
        destination: Disk,
        createSubfolder: Bool = false,
        subfolder: String = "",
        checksumMethod: String = "xxHash64",
        verificationMethod: String = "Standard",
        createMHL: Bool = false
    ) {
        // Mark disks as source and destination
        markSourceDisk(source)
        markDestinationDisk(destination)
        
        // Set transfer options
        self.createSubfolder = createSubfolder
        self.subfolderPath = subfolder
        self.selectedChecksumMethod = checksumMethod
        self.selectedVerificationMethod = verificationMethod
        self.createMHL = createMHL
        
        // Set up the transfer UI to show these options
        setupTransferUI()
    }
    
    /// Set up the transfer UI after configuring options
    private func setupTransferUI() {
        // Update UI to reflect transfer settings
        // This would typically navigate to the transfers view
        NotificationCenter.default.post(name: Notification.Name("ShowTransfersView"), object: nil)
        
        // Update status message
        if let source = selectedSourceDisk, let destination = selectedDestinationDisk {
            statusMessage = "Ready to transfer from \(source.name) to \(destination.name)"
            
            // Show folder path if creating subfolder
            if createSubfolder && !subfolderPath.isEmpty {
                statusMessage += " in subfolder '\(subfolderPath)'"
            }
        }
    }
    
    /// Mark a disk as a source for easy reference
    private func markSourceDisk(_ disk: Disk) {
        selectedSourceDisk = disk
        setDiskAsSource(disk)
    }
    
    /// Mark a disk as a destination for easy reference
    private func markDestinationDisk(_ disk: Disk) {
        selectedDestinationDisk = disk
        setDiskAsDestination(disk)
    }
    
    /// Generate a report for completed transfers
    func generateTransferReport(format: FileTransferManager.ReportFormat = .html) {
        guard !completedTransfers.isEmpty else {
            print("No completed transfers to include in report")
            return
        }
        
        // Create report directory if it doesn't exist
        let reportsDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents")
            .appendingPathComponent("MediaForge Reports")
        
        do {
            try FileManager.default.createDirectory(at: reportsDirectory, withIntermediateDirectories: true)
        } catch {
            print("Error creating reports directory: \(error)")
            return
        }
        
        // Generate report filename
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let reportPath = reportsDirectory
            .appendingPathComponent("Transfer_Report_\(timestamp).\(format.fileExtension)")
            .path
        
        // Generate the report
        FileTransferManager.generateReport(
            transfers: completedTransfers,
            format: format, 
            outputPath: reportPath
        ) { result in
            switch result {
            case .success(let path):
                DispatchQueue.main.async {
                    self.statusMessage = "Report saved to: \(path)"
                    
                    // Open the report with the default app
                    NSWorkspace.shared.open(URL(fileURLWithPath: path))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.statusMessage = "Failed to generate report: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Generate MHL file for a transfer
    func generateMHL(for transfer: FileTransfer, algorithm: MediaHashList.HashAlgorithm = .md5) {
        // Create MHL directory if it doesn't exist
        let mhlDirectory = URL(fileURLWithPath: transfer.destination.path)
            .appendingPathComponent("MHL")
        
        do {
            try FileManager.default.createDirectory(at: mhlDirectory, withIntermediateDirectories: true)
        } catch {
            print("Error creating MHL directory: \(error)")
            return
        }
        
        // Generate filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let sourceName = URL(fileURLWithPath: transfer.source.path).lastPathComponent
        let mhlPath = mhlDirectory
            .appendingPathComponent("\(sourceName)_\(timestamp).mhl")
            .path
        
        // Get list of files in transfer
        let transferDirectory = URL(fileURLWithPath: transfer.destination.path)
            .appendingPathComponent(URL(fileURLWithPath: transfer.source.path).lastPathComponent)
        
        guard let enumerator = FileManager.default.enumerator(
            at: transferDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else {
            print("Failed to enumerate files for MHL generation")
            return
        }
        
        // Collect all file paths
        var filePaths: [String] = []
        for case let fileURL as URL in enumerator {
            if !fileURL.hasDirectoryPath {
                filePaths.append(fileURL.path)
            }
        }
        
        // Generate MHL file
        let comment = "Transfer from \(transfer.source.name) to \(transfer.destination.name)"
        let success = MediaHashList.generateMHL(for: filePaths, mhlPath: mhlPath, algorithm: algorithm, comment: comment)
        
        if success {
            DispatchQueue.main.async {
                self.statusMessage = "MHL file created at: \(mhlPath)"
            }
        } else {
            DispatchQueue.main.async {
                self.statusMessage = "Failed to create MHL file"
            }
        }
    }
    
    /// Show a permission error for a specific disk
    func showPermissionErrorFor(disk: Disk) {
        permissionErrorMessage = "MediaForge needs full disk access to '\(disk.name)'"
        permissionErrorDisk = disk.name
        showPermissionAlert = true
    }
    
    /// Select a custom folder to use as a source
    func selectCustomSourceFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Source Folder"
        openPanel.message = "Choose a folder to use as source"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            let path = url.path
            let name = url.lastPathComponent
            
            // Create a custom disk object with default values
            let disk = Disk(
                name: name, 
                path: path, 
                devicePath: path,
                icon: "folder",
                totalSpace: 1000000000, // 1 GB default
                freeSpace: 500000000,   // 500 MB default
                isRemovable: false
            )
            disk.isSource = true
            
            // Add to disks if not already present
            if !availableDisks.contains(where: { $0.path == path }) {
                availableDisks.append(disk)
                sources.append(disk)
                
                // Show a notification
                statusMessage = "Added '\(name)' as source folder"
            }
        }
    }
    
    /// Select a custom folder to use as a destination
    func selectCustomDestinationFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Destination Folder"
        openPanel.message = "Choose a folder to use as destination"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            let path = url.path
            let name = url.lastPathComponent
            
            // Create a custom disk object with default values
            let disk = Disk(
                name: name, 
                path: path, 
                devicePath: path,
                icon: "folder",
                totalSpace: 1000000000, // 1 GB default
                freeSpace: 500000000,   // 500 MB default
                isRemovable: false
            )
            disk.isDestination = true
            
            // Add to disks if not already present
            if !availableDisks.contains(where: { $0.path == path }) {
                availableDisks.append(disk)
                destinations.append(disk)
                
                // Show a notification
                statusMessage = "Added '\(name)' as destination folder"
            }
        }
    }
} 