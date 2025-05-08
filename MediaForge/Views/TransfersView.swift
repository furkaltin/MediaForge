import SwiftUI
import AppKit

/// View that shows all transfers
struct TransfersView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var selectedTransfer: FileTransfer? = nil
    @State private var showDetails = false
    @State private var filterMode: FilterMode = .all
    
    // Filter options for transfers
    enum FilterMode: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        case failed = "Failed"
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .active: return .green
            case .completed: return .purple
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "tray.full"
            case .active: return "arrow.triangle.2.circlepath"
            case .completed: return "checkmark.circle"
            case .failed: return "exclamationmark.triangle"
            }
        }
    }
    
    // Computed transfers based on filter
    var filteredTransfers: [FileTransfer] {
        switch filterMode {
        case .all:
            return viewModel.transfers
        case .active:
            return viewModel.activeTransfers
        case .completed:
            return viewModel.completedTransfers
        case .failed:
            return viewModel.transfers.filter {
                if case .failed(_) = $0.status {
                    return true
                }
                return false
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            Color(red: 0.07, green: 0.07, blue: 0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with stats
                HStack(spacing: 25) {
                    // Title
                    Text("Media Transfers")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Stats badges
                    Group {
                        statBadge(
                            count: viewModel.activeTransfers.count,
                            title: "Active",
                            icon: "arrow.triangle.2.circlepath",
                            color: .green
                        )
                        
                        statBadge(
                            count: viewModel.completedTransfers.count,
                            title: "Completed",
                            icon: "checkmark.circle.fill",
                            color: .blue
                        )
                        
                        statBadge(
                            count: viewModel.failedTransfers.count,
                            title: "Failed",
                            icon: "exclamationmark.triangle.fill",
                            color: .red
                        )
                    }
                    
                    // Action buttons
                    HStack(spacing: 15) {
                        // Clear buttons, only enabled when there are transfers
                        Button {
                            withAnimation {
                                viewModel.clearCompletedTransfers()
                            }
                        } label: {
                            Label("Clear Completed", systemImage: "trash")
                                .font(.system(size: 13))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.completedTransfers.isEmpty ? Color.gray.opacity(0.2) : Color.blue.opacity(0.15))
                                .cornerRadius(20)
                                .foregroundColor(viewModel.completedTransfers.isEmpty ? .gray : .white)
                        }
                        .disabled(viewModel.completedTransfers.isEmpty)
                        .buttonStyle(.plain)
                        
                        Button {
                            withAnimation {
                                viewModel.clearFailedTransfers()
                            }
                        } label: {
                            Label("Clear Failed", systemImage: "xmark.circle")
                                .font(.system(size: 13))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.failedTransfers.isEmpty ? Color.gray.opacity(0.2) : Color.red.opacity(0.15))
                                .cornerRadius(20)
                                .foregroundColor(viewModel.failedTransfers.isEmpty ? .gray : .white)
                        }
                        .disabled(viewModel.failedTransfers.isEmpty)
                        .buttonStyle(.plain)
                        
                        // Back to disks button
                        Button {
                            NotificationCenter.default.post(name: Notification.Name("ShowDisksView"), object: nil)
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Back to Disks")
                                    .font(.system(size: 13))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 15)
                .padding(.bottom, 12)
                
                // Filter tabs
                HStack(spacing: 0) {
                    ForEach(FilterMode.allCases, id: \.self) { mode in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                filterMode = mode
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 14))
                                
                                Text(mode.rawValue)
                                    .font(.system(size: 14, weight: filterMode == mode ? .semibold : .medium))
                                
                                // Show count for each category
                                Group {
                                    switch mode {
                                    case .all:
                                        Text("(\(viewModel.transfers.count))")
                                    case .active:
                                        Text("(\(viewModel.activeTransfers.count))")
                                    case .completed:
                                        Text("(\(viewModel.completedTransfers.count))")
                                    case .failed:
                                        Text("(\(viewModel.failedTransfers.count))")
                                    }
                                }
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .foregroundColor(filterMode == mode ? .white : .white.opacity(0.7))
                            .background(
                                filterMode == mode ?
                                mode.color.opacity(0.15) : Color.clear
                            )
                            .cornerRadius(8)
                            .overlay(
                                filterMode == mode ?
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(mode.color)
                                    .offset(y: 19)
                                : nil
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .background(Color.black.opacity(0.2))
                
                // No transfers view
                if filteredTransfers.isEmpty {
                    emptyTransfersView
                } else {
                    // Transfers list
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(filteredTransfers) { transfer in
                                TransferItemView(transfer: transfer, viewModel: viewModel)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedTransfer = transfer
                                        showDetails = true
                                    }
                                    .transition(.opacity)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showDetails) {
            if let transfer = selectedTransfer {
                transferDetailsView(transfer: transfer)
            }
        }
    }
    
    // Empty state view when no transfers match the filter
    var emptyTransfersView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))
            
            Text(emptyStateMessage)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            // Action button based on filter type
            if filterMode == .all || filterMode == .active {
                Button {
                    NotificationCenter.default.post(name: Notification.Name("ShowDisksView"), object: nil)
                } label: {
                    Text("Configure Sources & Destinations")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
    
    // Dynamic empty state message based on filter
    var emptyStateMessage: String {
        switch filterMode {
        case .all:
            return "No transfers have been created yet.\nSelect source and destination disks to begin."
        case .active:
            return "No active transfers.\nStart a new transfer from the Disks view."
        case .completed:
            return "No completed transfers yet."
        case .failed:
            return "No failed transfers."
        }
    }
    
    // Custom stat badge component
    func statBadge(count: Int, title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            Text("\(count) \(title)")
                .font(.system(size: 13, weight: .medium))
            
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .cornerRadius(20)
        .foregroundColor(.white)
    }
    
    // Transfer details sheet
    func transferDetailsView(transfer: FileTransfer) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Transfer Details")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    showDetails = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Source and destination section
                    Group {
                        sectionTitle("Source & Destination")
                        
                        HStack(spacing: 20) {
                            // Source disk
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Source", systemImage: "arrow.up.doc")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                                
                                Text(transfer.source.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(transfer.source.path)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                
                                HStack {
                                    Text("Capacity:")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    
                                    Text(transfer.source.formattedTotalSpace)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            .padding(15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                            
                            // Destination disk
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Destination", systemImage: "arrow.down.doc")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.green)
                                
                                Text(transfer.destination.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(transfer.destination.path)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                
                                HStack {
                                    Text("Free Space:")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    
                                    Text(transfer.destination.formattedFreeSpace)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            .padding(15)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Status section
                    Group {
                        sectionTitle("Transfer Status")
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // Status indicator
                            HStack(spacing: 10) {
                                // Status icon
                                ZStack {
                                    Circle()
                                        .fill(statusColor(for: transfer))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: statusIcon(for: transfer))
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(statusText(for: transfer))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    if case let .failed(error) = transfer.status {
                                        Text(error.localizedDescription)
                                            .font(.system(size: 13))
                                            .foregroundColor(.red.opacity(0.8))
                                            .lineLimit(2)
                                    } else {
                                        Text(transfer.transferStatus)
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                // Show cancel button for active transfers
                                if transfer.status == .copying || transfer.status == .preparing || transfer.status == .verifying {
                                    Button {
                                        viewModel.cancelTransfer(transfer)
                                        showDetails = false
                                    } label: {
                                        Text("Cancel")
                                            .font(.system(size: 14, weight: .medium))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.red.opacity(0.2))
                                            .cornerRadius(8)
                                            .foregroundColor(.white)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Progress indicator
                            if transfer.status == .copying || transfer.status == .preparing || transfer.status == .verifying {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Progress:")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        
                                        Text("\(Int(transfer.progress * 100))%")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        if transfer.totalFiles > 0 {
                                            Text("\(transfer.completedFiles)/\(transfer.totalFiles) files")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    // Progress bar
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 8)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.green, .blue]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: CGFloat(transfer.progress) * 200, height: 6)
                                    }
                                }
                            }
                        }
                        .padding(15)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                        .cornerRadius(12)
                    }
                    
                    // Transfer details section
                    Group {
                        sectionTitle("Transfer Details")
                        
                        VStack(spacing: 15) {
                            detailRow(title: "ID:", value: transfer.id.uuidString.prefix(8).lowercased())
                            
                            if let started = transfer.startTime {
                                detailRow(title: "Started:", value: formatDate(started))
                            }
                            
                            if let completed = transfer.endTime {
                                detailRow(title: "Completed:", value: formatDate(completed))
                            }
                            
                            if transfer.bytesTransferred > 0 {
                                detailRow(title: "Transferred:", value: formatBytes(transfer.bytesTransferred))
                            }
                            
                            if transfer.totalBytesToTransfer > 0 {
                                detailRow(title: "Total Size:", value: formatBytes(transfer.totalBytesToTransfer))
                            }
                            
                            if transfer.transferRate > 0 {
                                detailRow(title: "Speed:", value: "\(formatBytes(Int64(transfer.transferRate)))/s")
                            }
                        }
                        .padding(15)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .frame(width: 700, height: 600)
        .background(
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.1).opacity(0.95)
                
                // Add some subtle visual elements
                Circle()
                    .fill(Color.blue.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .blur(radius: 80)
                    .offset(x: -150, y: -100)
                
                Circle()
                    .fill(Color.purple.opacity(0.05))
                    .frame(width: 250, height: 250)
                    .blur(radius: 80)
                    .offset(x: 150, y: 150)
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // Helper views for details screen
    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white.opacity(0.9))
    }
    
    func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
    
    // Helper functions for status display
    func statusColor(for transfer: FileTransfer) -> Color {
        switch transfer.status {
        case .notStarted:
            return .gray
        case .preparing, .copying, .verifying:
            return .green
        case .completed:
            return .blue
        case .failed:
            return .red
        case .paused:
            return .orange
        }
    }
    
    func statusIcon(for transfer: FileTransfer) -> String {
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
    
    func statusText(for transfer: FileTransfer) -> String {
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
    
    // Format helpers
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    TransfersView(viewModel: MediaForgeViewModel())
} 