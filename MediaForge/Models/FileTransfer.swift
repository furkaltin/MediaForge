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
                return "Failed: \(transferError.localizedDescription)"
            } else {
                return "Failed: \(error.localizedDescription)"
            }
        }
    }
}

/// Represents a file transfer operation from source to destination
class FileTransfer: Identifiable, ObservableObject {
    let id = UUID()
    
    @Published var source: Disk
    @Published var destination: Disk
    @Published var status: TransferStatus = .notStarted
    @Published var progress: Double = 0.0
    @Published var currentFile: String?
    @Published var transferRate: Double = 0.0 // Bytes per second
    @Published var estimatedTimeRemaining: TimeInterval?
    @Published var totalBytesToTransfer: Int64 = 0
    @Published var bytesTransferred: Int64 = 0
    
    var startTime: Date?
    var endTime: Date?
    
    /// Initialize a transfer with a source and destination
    init(from source: Disk, to destination: Disk) {
        self.source = source
        self.destination = destination
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
    
    /// Start the transfer
    func start() {
        // This will be implemented later with actual file copying logic
        self.status = .preparing
        self.startTime = Date()
    }
    
    /// Pause the transfer
    func pause() {
        if self.status == .copying || self.status == .verifying {
            self.status = .paused
        }
    }
    
    /// Resume a paused transfer
    func resume() {
        if self.status == .paused {
            self.status = .copying // Simplification for now
        }
    }
    
    /// Cancel the transfer
    func cancel() {
        // Logic to cancel will be implemented later
    }
    
    /// Update progress and related metrics
    func updateProgress(bytesTransferred: Int64, totalBytes: Int64, currentFile: String) {
        self.bytesTransferred = bytesTransferred
        self.totalBytesToTransfer = totalBytes
        self.currentFile = currentFile
        
        // Calculate progress
        if totalBytes > 0 {
            self.progress = Double(bytesTransferred) / Double(totalBytes)
        }
        
        // Calculate transfer rate and estimated time
        if let startTime = startTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            if elapsedTime > 0 {
                self.transferRate = Double(bytesTransferred) / elapsedTime
                
                if self.transferRate > 0 {
                    let bytesRemaining = totalBytes - bytesTransferred
                    self.estimatedTimeRemaining = Double(bytesRemaining) / self.transferRate
                }
            }
        }
    }
    
    /// Complete the transfer
    func complete() {
        self.status = .completed
        self.progress = 1.0
        self.endTime = Date()
    }
    
    /// Fail the transfer with an error
    func fail(with error: Error) {
        self.status = .failed(error)
        self.endTime = Date()
        
        // Detaylı hata mesajını konsola bas
        print("Transfer failed: \(error.localizedDescription)")
        if let transferError = error as? FileTransferManager.TransferError {
            print("Details: \(transferError.errorDescription)")
        }
    }
} 