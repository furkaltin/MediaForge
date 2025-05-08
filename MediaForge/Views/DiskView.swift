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
            return "exclamationmark.triangle"
        }
        
        if disk.diskType == .internalDrive {
            return "internaldrive"
        } else if disk.diskType == .externalDrive || disk.diskType == .removableMedia {
            return "externaldrive.badge.checkmark"
        } else if disk.path.contains("Camera") || disk.path.contains("DCIM") {
            return "camera"
        } else {
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
            return Color.purple
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Glass effect header with disk info
            HStack(alignment: .top, spacing: 15) {
                // Disk icon with color background
                ZStack {
                    Circle()
                        .fill(diskColor.opacity(0.2))
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: diskIcon)
                        .font(.system(size: 18))
                        .foregroundColor(diskColor)
                }
                .padding(5)
                
                // Disk info
                VStack(alignment: .leading, spacing: 4) {
                    // Disk name with label
                    HStack(spacing: 6) {
                        Text(disk.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if let label = disk.label, !label.isEmpty {
                            Text(label)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.3))
                                .cornerRadius(10)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    // Path and status
                    if disk.hasFullAccess {
                        Text(disk.path)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    } else {
                        Text("Permission required")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.yellow)
                    }
                    
                    // Capacity info and bar
                    HStack(spacing: 4) {
                        Text("Free:")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(disk.formattedFreeSpace)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        Text("of")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(disk.formattedTotalSpace)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Usage type indicators
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
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
            .background(
                ZStack {
                    // Background color with conditional border
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.8))
                    
                    // Status glow effect
                    if disk.isSource || disk.isDestination {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                disk.isSource ? Color.blue.opacity(0.4) : 
                                disk.isDestination ? Color.green.opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                    }
                    
                    // Hover effect
                    if isHovered {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    }
                }
            )
            
            // Storage capacity bar
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)
                
                // Used space bar with animation
                let usedWidth = CGFloat(1 - disk.freeSpacePercentage) * 100
                RoundedRectangle(cornerRadius: 4)
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
            
            // Action buttons
            HStack(spacing: 16) {
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
                .frame(minWidth: 90)
                
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
                .frame(minWidth: 110)
                
                Spacer()
                
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
                .padding(.trailing, 5)
                
                // Unuse button (if selected as source or destination)
                if disk.isSource || disk.isDestination {
                    Button {
                        onUnuseClick()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(6)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Remove selection")
                }
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 15)
            .padding(.top, 5)
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
            // Label editing sheet with glass effect
            VStack(spacing: 20) {
                HStack {
                    Text("Add Label")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        showLabelSheet = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Disk: \(disk.name)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Enter a label to help identify this disk:")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    TextField("Label", text: $diskLabel)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        showLabelSheet = false
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Button {
                        disk.setLabel(diskLabel)
                        showLabelSheet = false
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .frame(width: 350, height: 220)
            .background(
                ZStack {
                    Color.black.opacity(0.7)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.4))
                        .blur(radius: 10)
                }
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    // Custom action button with highlight effect
    func actionButton(
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
            .padding(.vertical, 8)
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
    }
} 