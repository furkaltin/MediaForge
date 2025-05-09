import SwiftUI

/// View for a single transfer item
struct TransferItemView: View {
    @ObservedObject var transfer: FileTransfer
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var isHovered = false
    
    // Color for the transfer status
    var statusColor: Color {
        switch transfer.status {
        case .notStarted:
            return Color.gray
        case .preparing, .copying, .verifying:
            return Color.green
        case .completed:
            return Color.blue
        case .failed:
            return Color.red
        case .paused:
            return Color.orange
        }
    }
    
    // Icon for the transfer status
    var statusIcon: String {
        switch transfer.status {
        case .notStarted:
            return "hourglass"
        case .preparing:
            return "gear"
        case .copying:
            return "arrow.triangle.2.circlepath"
        case .verifying:
            return "checkmark.shield"
        case .completed:
            return "checkmark.circle"
        case .failed:
            return "exclamationmark.triangle"
        case .paused:
            return "xmark.circle"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            mainInfoView
            
            // Progress bar (only for active transfers)
            if transfer.status == .copying || transfer.status == .preparing || transfer.status == .verifying {
                progressView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.12).opacity(0.7))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActiveTransfer ? 
                    statusColor.opacity(0.3) : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    // Helper properties
    var isActiveTransfer: Bool {
        if case .copying = transfer.status { return true }
        if case .preparing = transfer.status { return true }
        if case .verifying = transfer.status { return true }
        return false
    }
    
    // Main information view
    var mainInfoView: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status icon with background
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 16))
                    .foregroundColor(statusColor)
            }
            
            // Transfer details
            VStack(alignment: .leading, spacing: 2) {
                // Source → Destination
                HStack(spacing: 4) {
                    Text(transfer.source.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Text(transfer.destination.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    
                    // Label if present
                    if let sourceLabel = transfer.source.label, !sourceLabel.isEmpty {
                        Text(sourceLabel)
                            .font(.system(size: 11))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                            .foregroundColor(.orange)
                    }
                }
                
                // Status and info
                HStack(spacing: 8) {
                    // Status text
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(statusColor)
                    
                    // Only show divider if we have a status message
                    if !transfer.transferStatus.isEmpty {
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Text(transfer.transferStatus)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right side info (time, progress, actions)
            rightSideView
            
            // Actions button (only shown on hover)
            if isHovered && isActiveTransfer {
                Button {
                    viewModel.cancelTransfer(transfer)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 26, height: 26)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Cancel transfer")
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
    }
    
    // Right side information
    var rightSideView: some View {
        VStack(alignment: .trailing, spacing: 5) {
            // Start/completion time
            if let date = transfer.endTime ?? transfer.startTime {
                Text(timeString(for: date))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            // For incomplete transfers, show percentage
            if case .completed = transfer.status {
                // Don't show percentage for completed transfers
            } else if case .failed = transfer.status {
                // Don't show percentage for failed transfers
            } else if case .paused = transfer.status {
                // Don't show percentage for paused transfers
            } else {
                Text("\(Int(transfer.progress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Show error message for failed transfers
            if case let .failed(error) = transfer.status {
                errorMessageView(for: error)
            }
        }
    }
    
    // Error message view component
    @ViewBuilder
    func errorMessageView(for error: Error) -> some View {
        if let transferError = error as? FileTransferManager.TransferError {
            // Custom error types from our app
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.red.opacity(0.8))
                
                Text(transferError.errorDescription ?? "Unknown error")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
                    .frame(maxWidth: 200, alignment: .trailing)
                    .lineLimit(1)
                    .help(transferError.failureReason ?? transferError.errorDescription ?? "Unknown error")
            }
        } else {
            // Handle NSError with more detail
            let nsError = error as NSError
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red.opacity(0.8))
                    
                    Text(nsError.localizedDescription)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(maxWidth: 200, alignment: .trailing)
                        .lineLimit(1)
                }
                
                // Add detailed reason if available
                if let reason = nsError.localizedFailureReason {
                    Text(reason)
                        .font(.system(size: 9))
                        .foregroundColor(.red.opacity(0.6))
                        .frame(maxWidth: 200, alignment: .trailing)
                        .lineLimit(1)
                }
            }
            .help(getFullErrorDetails(for: nsError))
        }
    }
    
    // Get full error details for tooltip
    func getFullErrorDetails(for error: NSError) -> String {
        var details = [String]()
        
        details.append("Error: \(error.localizedDescription)")
        
        if let reason = error.localizedFailureReason {
            details.append("Reason: \(reason)")
        }
        
        if let suggestion = error.localizedRecoverySuggestion {
            details.append("Suggestion: \(suggestion)")
        }
        
        details.append("Code: \(error.code)")
        details.append("Domain: \(error.domain)")
        
        // Check for additional details in user info
        if let skipItems = error.userInfo["skippedItems"] as? String {
            details.append("Skipped: \(skipItems)")
        }
        
        if let errorDetails = error.userInfo["errorMessages"] as? [String], !errorDetails.isEmpty {
            details.append("Details: \(errorDetails.joined(separator: "; "))")
        }
        
        return details.joined(separator: "\n")
    }
    
    // Progress view for active transfers
    var progressView: some View {
        VStack(spacing: 4) {
            // Progress bar
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)
                
                // Progress indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [statusColor, statusColor.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, CGFloat(transfer.progress) * 300), height: 4)
            }
            
            // File counts, size, and speed
            HStack(spacing: 12) {
                // File count
                if transfer.totalFiles > 0 {
                    Text("\(transfer.completedFiles)/\(transfer.totalFiles) files")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                // Bytes transferred
                if transfer.bytesTransferred > 0 {
                    Text(bytesTransferredText)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Transfer speed
                if transfer.transferRate > 0 {
                    Text(speedText(for: transfer.transferRate))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 12)
    }
    
    // Status text based on transfer state
    var statusText: String {
        switch transfer.status {
        case .notStarted:
            return "Queued"
        case .preparing:
            return "Preparing"
        case .copying:
            return "Copying"
        case .verifying:
            return "Verifying"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .paused:
            return "Paused"
        }
    }
    
    // Helper for formatting the time
    func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        
        // If it's today, just show the time
        if Calendar.current.isDateInToday(date) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    // Format transferred bytes text
    var bytesTransferredText: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        
        if transfer.totalBytesToTransfer > 0 {
            return "\(formatter.string(fromByteCount: transfer.bytesTransferred)) of \(formatter.string(fromByteCount: transfer.totalBytesToTransfer))"
        } else {
            return formatter.string(fromByteCount: transfer.bytesTransferred)
        }
    }
    
    // Format transfer speed
    func speedText(for bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: Int64(bytesPerSecond)))/s"
    }
}

#Preview {
    // Prepare mock transfer
    let previewTransfer: FileTransfer = {
        let disk1 = Disk(id: "1", name: "SSD Drive", path: "/Volumes/SSD", devicePath: "/dev/disk1", icon: "externaldrive", totalSpace: 1000000000, freeSpace: 500000000)
        let disk2 = Disk(id: "2", name: "Media Card", path: "/Volumes/CANON", devicePath: "/dev/disk2", icon: "camera", totalSpace: 64000000000, freeSpace: 32000000000)
        let transfer = FileTransfer(from: disk1, to: disk2)
        
        // Set properties for preview
        transfer.status = .copying
        transfer.progress = 0.35
        transfer.bytesTransferred = 350000000
        transfer.totalBytesToTransfer = 1000000000
        transfer.startTime = Date()
        transfer.transferStatus = "Copying file.mov"
        transfer.completedFiles = 2
        transfer.totalFiles = 5
        
        return transfer
    }()
    
    VStack {
        TransferItemView(transfer: previewTransfer, viewModel: MediaForgeViewModel())
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(red: 0.08, green: 0.08, blue: 0.1))
    .preferredColorScheme(.dark)
} 