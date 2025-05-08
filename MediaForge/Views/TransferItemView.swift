import SwiftUI

/// View for a single transfer item showing progress and status
struct TransferItemView: View {
    @ObservedObject var transfer: FileTransfer
    
    // Color for the progress bar based on transfer status
    var progressBarColor: Color {
        switch transfer.status {
        case .preparing:
            return Color.gray
        case .copying:
            return Color.blue
        case .verifying:
            return Color(red: 0.4, green: 0.7, blue: 1.0)
        case .completed:
            return Color.green
        case .failed:
            return Color.red
        case .paused:
            return Color.orange
        default:
            return Color.gray
        }
    }
    
    // Status text
    var statusText: String {
        switch transfer.status {
        case .notStarted:
            return "Not Started"
        case .preparing:
            return "Preparing..."
        case .copying:
            return "Copying: \(transfer.currentFile ?? "")"
        case .verifying:
            return "Verifying: \(transfer.currentFile ?? "")"
        case .completed:
            return "Completed"
        case .failed(let error):
            if let transferError = error as? FileTransferManager.TransferError {
                return "Failed: \(transferError.localizedDescription)"
            } else {
                return "Failed: \(error.localizedDescription)"
            }
        case .paused:
            return "Paused"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with source and destination
            HStack {
                Text("\(transfer.source.name) → \(transfer.destination.name)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Controls based on transfer status
                HStack(spacing: 12) {
                    if transfer.status == .copying || transfer.status == .verifying {
                        Button {
                            transfer.pause()
                        } label: {
                            Image(systemName: "pause.circle")
                                .foregroundColor(.white)
                        }
                    } else if transfer.status == .paused {
                        Button {
                            transfer.resume()
                        } label: {
                            Image(systemName: "play.circle")
                                .foregroundColor(.white)
                        }
                    }
                    
                    if transfer.status != .completed {
                        Button {
                            transfer.cancel()
                        } label: {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .foregroundColor(Color(white: 0.2))
                        .cornerRadius(4)
                    
                    // Progress
                    Rectangle()
                        .foregroundColor(progressBarColor)
                        .cornerRadius(4)
                        .frame(width: max(geometry.size.width * CGFloat(transfer.progress), 0))
                }
                .frame(height: 8)
            }
            .frame(height: 8)
            
            // Status and progress info
            HStack {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if transfer.status == .copying || transfer.status == .verifying {
                    Text("\(transfer.formattedTransferRate) • \(transfer.formattedTimeRemaining)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Only show detailed error for failed transfers
            if case .failed(let error) = transfer.status, let transferError = error as? FileTransferManager.TransferError {
                Text(transferError.errorDescription)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(8)
    }
} 