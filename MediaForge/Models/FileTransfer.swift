import Foundation

/// Transfer status to track the progress
enum TransferStatus: Equatable {
    case notStarted      // Not started yet
    case preparing       // Preparing for transfer (indexing, validation)
    case copying         // Actively copying files
    case verifying       // Verifying checksums
    case completed       // Successfully completed
    case failed(Error)   // Failed with error
    case paused          // Paused by user
    
    // İlişkili değerleri olan enum için Equatable uygulaması
    static func == (lhs: TransferStatus, rhs: TransferStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted):
            return true
        case (.preparing, .preparing):
            return true
        case (.copying, .copying):
            return true
        case (.verifying, .verifying):
            return true
        case (.completed, .completed):
            return true
        case (.paused, .paused):
            return true
        case (.failed, .failed):
            // Error içeriğine bakmadan sadece durumları karşılaştırıyoruz
            return true
        default:
            return false
        }
    }
    
    // Durum mesajını insan tarafından okunabilir hale getir
    var description: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .preparing:
            return "Preparing..."
        case .copying:
            return "Copying Images"
        case .verifying:
            return "Verifying"
        case .completed:
            return "Completed"
        case .paused:
            return "Paused"
        case .failed(let error):
            if let transferError = error as? FileTransferManager.TransferError {
                return "Failed: \(transferError.errorDescription ?? transferError.localizedDescription)"
            } else {
                return "Failed: \(error.localizedDescription)"
            }
        }
    }
}

/// Represents a file transfer operation between two disks
class FileTransfer: Identifiable, ObservableObject {
    let id = UUID()
    let source: Disk
    let destination: Disk
    
    @Published var status: TransferStatus = .notStarted
    @Published var progress: Double = 0.0
    @Published var bytesTransferred: Int64 = 0
    @Published var totalBytesToTransfer: Int64 = 0
    @Published var transferStatus: String = ""
    @Published var completedFiles: Int = 0
    @Published var totalFiles: Int = 0
    
    // Transfer timing
    @Published var startTime: Date?
    @Published var endTime: Date?
    @Published var transferRate: Double = 0.0 // bytes per second
    @Published var estimatedTimeRemaining: TimeInterval?
    
    // Timer for calculating transfer rate
    private var rateCalculationTimer: Timer?
    private var lastBytesTransferred: Int64 = 0
    private var lastUpdateTime: Date = Date()
    
    init(from source: Disk, to destination: Disk) {
        self.source = source
        self.destination = destination
    }
    
    /// Start the transfer
    func start() {
        status = .preparing
        progress = 0.0
        bytesTransferred = 0
        startTime = Date()
        lastUpdateTime = startTime!
        
        // Start timer for transfer rate calculation
        rateCalculationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.calculateTransferRate()
        }
    }
    
    /// Update progress during transfer
    func updateProgress(bytesTransferred: Int64, totalBytes: Int64, currentFile: String) {
        self.bytesTransferred = bytesTransferred
        self.totalBytesToTransfer = totalBytes
        
        if totalBytes > 0 {
            self.progress = Double(bytesTransferred) / Double(totalBytes)
        } else {
            self.progress = 0.0
        }
        
        self.transferStatus = currentFile
    }
    
    /// Calculate transfer rate
    private func calculateTransferRate() {
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastUpdateTime)
        
        if timeInterval > 0 {
            let bytesDifference = bytesTransferred - lastBytesTransferred
            transferRate = Double(bytesDifference) / timeInterval
            
            lastBytesTransferred = bytesTransferred
            lastUpdateTime = now
            
            // Calculate estimated time remaining
            if transferRate > 0 && totalBytesToTransfer > bytesTransferred {
                let bytesRemaining = totalBytesToTransfer - bytesTransferred
                estimatedTimeRemaining = Double(bytesRemaining) / transferRate
            } else {
                estimatedTimeRemaining = nil
            }
        }
    }
    
    /// Mark transfer as completed
    func complete() {
        status = .completed
        progress = 1.0
        bytesTransferred = totalBytesToTransfer
        endTime = Date()
        
        // Stop transfer rate timer
        rateCalculationTimer?.invalidate()
        rateCalculationTimer = nil
    }
    
    /// Mark transfer as failed
    func fail(with error: Error) {
        status = .failed(error)
        endTime = Date()
        
        // Stop transfer rate timer
        rateCalculationTimer?.invalidate()
        rateCalculationTimer = nil
    }
    
    /// Cancel the transfer
    func cancel() {
        let error = NSError(domain: "MediaForge.FileTransfer", 
                           code: 999, 
                           userInfo: [NSLocalizedDescriptionKey: "Transfer was cancelled by user"])
        status = .failed(error)
        endTime = Date()
        
        // Stop transfer rate timer
        rateCalculationTimer?.invalidate()
        rateCalculationTimer = nil
    }
    
    /// Pause the transfer
    func pause() {
        if status == .copying || status == .preparing || status == .verifying {
            // Save current state for later resuming
            status = .paused
            
            // Stop transfer rate timer while paused
            rateCalculationTimer?.invalidate()
            rateCalculationTimer = nil
        }
    }
    
    /// Resume a paused transfer
    func resume() {
        if status == .paused {
            // Restore previous state
            status = .copying
            
            // Reset transfer rate calculation
            lastUpdateTime = Date()
            lastBytesTransferred = bytesTransferred
            
            // Restart the timer
            rateCalculationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.calculateTransferRate()
            }
        }
    }
    
    /// Format the estimated time remaining to a human-readable string
    var formattedTimeRemaining: String {
        guard let timeRemaining = estimatedTimeRemaining else {
            return "Calculating..."
        }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        
        return formatter.string(from: timeRemaining) ?? "Calculating..."
    }
    
    /// Format the transfer rate to a human-readable string
    var formattedTransferRate: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: Int64(transferRate)))/s"
    }
    
    /// Generate an MHL file for this transfer
    func generateMHL(using algorithm: MediaHashList.HashAlgorithm = .md5) -> Bool {
        // Only generate for completed transfers
        guard status == .completed else {
            print("Cannot generate MHL for incomplete transfer")
            return false
        }
        
        // Create MHL directory
        let mhlDirectory = URL(fileURLWithPath: destination.path)
            .appendingPathComponent("MHL")
        
        do {
            try FileManager.default.createDirectory(at: mhlDirectory, withIntermediateDirectories: true)
        } catch {
            print("Error creating MHL directory: \(error)")
            return false
        }
        
        // Generate filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let sourceName = URL(fileURLWithPath: source.path).lastPathComponent
        let mhlPath = mhlDirectory
            .appendingPathComponent("\(sourceName)_\(timestamp).mhl")
            .path
        
        // Get list of files in transfer
        let transferDirectory = URL(fileURLWithPath: destination.path)
            .appendingPathComponent(URL(fileURLWithPath: source.path).lastPathComponent)
        
        guard let enumerator = FileManager.default.enumerator(
            at: transferDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else {
            print("Failed to enumerate files for MHL generation")
            return false
        }
        
        // Collect all file paths
        var filePaths: [String] = []
        for case let fileURL as URL in enumerator {
            if !fileURL.hasDirectoryPath {
                filePaths.append(fileURL.path)
            }
        }
        
        // Generate MHL file
        let comment = "Transfer from \(source.name) to \(destination.name) on \(timestamp)"
        return MediaHashList.generateMHL(for: filePaths, mhlPath: mhlPath, algorithm: algorithm, comment: comment)
    }
} 