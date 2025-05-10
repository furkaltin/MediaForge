import SwiftUI

/// View that displays a single disk with its properties
struct DiskView: View {
    @ObservedObject var disk: Disk
    var viewModel: MediaForgeViewModel
    var onSourceClick: () -> Void
    var onDestinationClick: () -> Void
    var onUnuseClick: () -> Void
    @State private var showLabelSheet = false
    @State private var diskLabel = ""
    @State private var isHovered = false
    @State private var isPressed = false
    
    // Animation values
    @State private var animateCapacity = false
    
    // Icon based on disk type
    var diskIcon: String {
        if !disk.hasFullAccess {
            return "exclamationmark.triangle.fill"
        }
        
        if disk.diskType == .internalDrive {
            return "internaldrive.fill"
        } else if disk.diskType == .externalDrive {
            return "externaldrive.fill"
        } else if disk.diskType == .removableMedia {
            return "opticaldiscdrive.fill"
        } else if disk.diskType == .cameraCard {
            return "sdcard.fill"
        } else if disk.diskType == .networkStorage {
            return "network.fill"
        } else if disk.path.contains("Camera") || disk.path.contains("DCIM") {
            return "camera.fill"
        } else if disk.isSource || disk.isDestination {
            return disk.isSource ? "arrow.up.doc.fill" : "arrow.down.doc.fill"
        } else {
            // İçeriği folder olan diskler için
            if disk.icon == "folder" {
                return "folder.fill"
            }
            return disk.icon
        }
    }
    
    // Color based on disk state
    var diskColor: Color {
        if !disk.hasFullAccess {
            return .yellow
        }
        if disk.isSource {
            return Color.blue
        } else if disk.isDestination {
            return Color.green
        } else {
            // Disk tipine göre renk ataması
            switch disk.diskType {
            case .internalDrive:
                return Color.gray
            case .externalDrive:
                return Color.orange
            case .cameraCard:
                return Color.red
            case .networkStorage:
                return Color.blue
            case .removableMedia:
                return Color.purple
            case .unknown:
                return Color.gray
            }
        }
    }
    
    // 3D görünümlü disk ikonları
    var modernDiskIcon: some View {
        Group {
            if !disk.hasFullAccess {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .symbolRenderingMode(.hierarchical)
            } else if disk.isSource {
                Image(systemName: "arrow.up.doc.fill")
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.hierarchical)
                    .symbolEffect(.pulse, options: .repeating)
            } else if disk.isDestination {
                Image(systemName: "arrow.down.doc.fill")
                    .foregroundColor(.green)
                    .symbolRenderingMode(.hierarchical)
                    .symbolEffect(.pulse, options: .repeating)
            } else {
                ZStack {
                    // Alt kısım - disk gölgesi
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .offset(y: 1)
                        .blur(radius: 2)
                    
                    // Ana disk
                    switch disk.diskType {
                    case .internalDrive:
                        // Dahili disk - metalik gri
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.9), Color.gray.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                            .overlay(
                                // Disk detayları
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 15, height: 15)
                                    .offset(x: 0, y: 0)
                            )
                            
                    case .externalDrive:
                        // Harici disk - sarı/turuncu
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange.opacity(0.9), Color.orange.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                            .overlay(
                                // Bağlantı ışığı
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 4, height: 4)
                                    .offset(x: 16, y: 16)
                            )
                            
                    case .cameraCard:
                        // Kamera kartı
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 36, height: 28)
                                
                            // Kart detayları
                            Rectangle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 28, height: 3)
                                .offset(y: -10)
                        }
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                        
                    case .networkStorage:
                        // Ağ depolama
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.blue.opacity(0.7)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            // Ağ simgesi
                            ForEach(0..<3) { i in
                                Path { path in
                                    path.move(to: CGPoint(x: -10 + Double(i) * 5, y: 6 - Double(i) * 4))
                                    path.addArc(center: CGPoint(x: 0, y: 0), 
                                              radius: 8 + Double(i) * 4,
                                              startAngle: .degrees(180),
                                              endAngle: .degrees(360),
                                              clockwise: false)
                                }
                                .stroke(Color.white.opacity(0.7 - Double(i) * 0.2), lineWidth: 1.5)
                            }
                        }
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                        
                    case .removableMedia:
                        // Çıkarılabilir medya - gümüş
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.9), Color.gray.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                            .overlay(
                                // Çıkarma butonu
                                Rectangle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 8, height: 2)
                                    .offset(x: 0, y: -16)
                            )
                            
                    case .unknown:
                        if disk.name.lowercased().contains("mac") || disk.name.lowercased().contains("macbook") {
                            Image(systemName: "laptopcomputer")
                                .foregroundStyle(.linearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                                .symbolRenderingMode(.hierarchical)
                        } else {
                            // Jenerik disk
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.5)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                        }
                    }
                }
            }
        }
        .frame(width: 60, height: 60)
    }
    
    // Header view with disk info
    var headerView: some View {
        HStack(alignment: .top, spacing: 15) {
            // Disk icon with color background and improved shadow
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                diskColor.opacity(0.15),
                                diskColor.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: diskColor.opacity(0.2), radius: 3, x: 0, y: 2)
                
                modernDiskIcon
            }
            .padding(5)
            
            // Disk info
            VStack(alignment: .leading, spacing: 4) {
                // Disk name with label
                HStack(spacing: 6) {
                    Text(disk.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let label = disk.label, !label.isEmpty {
                        Text(label)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.3))
                            .cornerRadius(10)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                // Path and status - truncate if too long
                if disk.hasFullAccess {
                    Text(disk.path)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 220, alignment: .leading)
                } else {
                    Text("Permission required")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.yellow)
                }
                
                // Capacity info and bar
                HStack(spacing: 4) {
                    Text("Free:")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text(disk.formattedFreeSpace)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    Text("of")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text(disk.formattedTotalSpace)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Usage type indicators with improved layout
            usageIndicatorsView
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 15)
        .background(headerBackground)
    }
    
    // Usage indicators view with improved styling
    var usageIndicatorsView: some View {
        Group {
            if disk.isSource || disk.isDestination {
                VStack(alignment: .trailing, spacing: 5) {
                    if disk.isSource {
                        HStack(spacing: 5) {
                            Text("Source")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.blue)
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if disk.isDestination {
                        HStack(spacing: 5) {
                            Text("Destination")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.green)
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .frame(minWidth: 85, alignment: .trailing)
            }
        }
    }
    
    // Header background with improved visuals
    var headerBackground: some View {
        ZStack {
            // Background color with improved border radius
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.8))
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            // Status glow effect with improved border radius
            if disk.isSource || disk.isDestination {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        disk.isSource ? Color.blue.opacity(0.4) : 
                        disk.isDestination ? Color.green.opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
                    .shadow(color: disk.isSource ? Color.blue.opacity(0.3) : Color.green.opacity(0.3), radius: 3, x: 0, y: 0)
            }
            
            // Hover effect with consistent border radius
            if isHovered {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
            }
        }
    }
    
    // Storage capacity bar with improved visuals
    var capacityBarView: some View {
        ZStack(alignment: .leading) {
            // Background bar
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.1))
                .frame(height: 8)
            
            // Used space bar with animation and gradient
            let usedWidth = CGFloat(1 - disk.freeSpacePercentage) * 100
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            diskColor.opacity(0.7),
                            diskColor
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: animateCapacity ? usedWidth : 0, height: 8)
                .animation(.easeOut(duration: 1.0), value: animateCapacity)
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    // Action buttons with improved styling
    var actionButtonsView: some View {
        HStack(spacing: 12) {
            // Set as source button
            actionButton(
                title: "Source",
                icon: "arrow.up",
                color: Color.blue,
                isActive: disk.isSource,
                isDisabled: !disk.hasFullAccess
            ) {
                onSourceClick()
            }
            .frame(maxWidth: .infinity)
            
            // Set as destination button
            actionButton(
                title: "Destination",
                icon: "arrow.down",
                color: Color.green,
                isActive: disk.isDestination,
                isDisabled: !disk.hasFullAccess
            ) {
                onDestinationClick()
            }
            .frame(maxWidth: .infinity)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            
            // Label and X buttons container
            labelAndUnuseButtonsView
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 15)
        .padding(.top, 5)
    }
    
    // Label and Unuse buttons
    var labelAndUnuseButtonsView: some View {
        HStack(spacing: 8) {
            // Label button
            Button {
                diskLabel = disk.label ?? ""
                showLabelSheet = true
            } label: {
                Image(systemName: "tag")
                    .font(.system(size: 12))
                    .foregroundColor(
                        disk.label != nil && !disk.label!.isEmpty ?
                        Color.orange : Color.white.opacity(0.6)
                    )
                    .padding(8)
                    .background(
                        disk.label != nil && !disk.label!.isEmpty ?
                        Color.orange.opacity(0.2) : Color.white.opacity(0.05)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Add label to disk")
            
            // Unuse button (if selected as source or destination)
            if disk.isSource || disk.isDestination {
                Button {
                    onUnuseClick()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Remove selection")
            }
        }
        .frame(width: 80, alignment: .trailing) // Fixed width for consistent layout
    }
    
    // Label sheet view
    var labelSheetView: some View {
        VStack(spacing: 20) {
            Text("Add Label")
                .font(.headline)
            
            TextField("Label", text: $diskLabel)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300)
            
            HStack {
                Button("Cancel") {
                    showLabelSheet = false
                }
                
                Button("Save") {
                    viewModel.setLabel(for: disk, label: diskLabel)
                    showLabelSheet = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(diskLabel.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 350, minHeight: 200)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Glass effect header with disk info
            headerView
            
            // Storage capacity bar with improved dimensions
            capacityBarView
            
            // Action buttons with improved spacing and dimensions
            actionButtonsView
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(white: 0.1).opacity(0.7))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hover
            }
        }
        .onAppear {
            // Animate capacity bar when disk appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateCapacity = true
            }
        }
        .sheet(isPresented: $showLabelSheet) {
            labelSheetView
        }
        .contentShape(Rectangle()) // Tıklama alanını düzenle
        .allowsHitTesting(true) // Görünümün tıklanabilirliğini etkinleştir
    }
    
    // Helper function to create action buttons
    private func actionButton(
        title: String,
        icon: String,
        color: Color,
        isActive: Bool,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                
                Text(title)
                    .font(.system(size: 12, weight: isActive ? .semibold : .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10) // Increased vertical padding for better touch target
            .frame(maxWidth: .infinity) // Full width to contain text
            .background(
                isActive ? color.opacity(0.3) :
                isDisabled ? Color.gray.opacity(0.1) : Color.white.opacity(0.07)
            )
            .foregroundColor(
                isActive ? .white :
                isDisabled ? Color.gray.opacity(0.5) : .white.opacity(0.8)
            )
            .cornerRadius(20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .allowsHitTesting(!isDisabled) // Devre dışı durumlarda tıklamaya izin verme
    }
} 