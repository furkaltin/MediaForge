import SwiftUI

/// View that displays a single disk with its properties
struct DiskView: View {
    @ObservedObject var disk: Disk
    var viewModel: MediaForgeViewModel
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Disk image with add button overlay
            ZStack {
                Image(systemName: disk.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(.white)
                
                // Permission warning indicator
                if !disk.hasFullAccess {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .resizable()
                                .frame(width: 22, height: 22)
                                .foregroundColor(.yellow)
                                .background(Circle().fill(Color.black))
                                .help("MediaForge doesn't have full access permission to this disk")
                            Spacer().frame(width: 4)
                        }
                        Spacer()
                    }
                }
                
                // Green add button for source/destination selection
                if !disk.isSource && !disk.isDestination {
                    HStack {
                        VStack {
                            Spacer()
                            Button {
                                if disk.isSource {
                                    viewModel.setDiskAsUnused(disk)
                                } else {
                                    viewModel.setDiskAsSource(disk)
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.green)
                                    .background(Circle().fill(Color.black))
                            }
                        }
                        Spacer()
                    }
                }
            }
            
            // Disk name
            Text(disk.name)
                .font(.headline)
                .foregroundColor(.white)
            
            // Permission status indicator for disks without full access
            if !disk.hasFullAccess {
                Text("Needs permission")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .onTapGesture {
                        viewModel.requestPermissionFor(disk) { success in
                            if !success {
                                viewModel.showPermissionErrorAlert(for: disk, isSource: false)
                            }
                        }
                    }
            } else {
                // Space indicator
                Text(disk.isSource ? 
                     "\(disk.formattedUsedSpace) in use" : 
                     "\(disk.formattedFreeSpace) free")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Menu for additional options
            Menu {
                if disk.isSource {
                    Button("Set as Unused") {
                        viewModel.setDiskAsUnused(disk)
                    }
                    Button("Set as Destination") {
                        viewModel.setDiskAsDestination(disk)
                    }
                } else if disk.isDestination {
                    Button("Set as Unused") {
                        viewModel.setDiskAsUnused(disk)
                    }
                    Button("Set as Source") {
                        viewModel.setDiskAsSource(disk)
                    }
                } else {
                    Button("Set as Source") {
                        viewModel.setDiskAsSource(disk)
                    }
                    Button("Set as Destination") {
                        viewModel.setDiskAsDestination(disk)
                    }
                }
                
                Divider()
                
                Button("Add Label...") {
                    // This will be implemented later
                }
                
                Button("Eject \(disk.name)") {
                    // This will be implemented later
                }
                
                Button("Rename \(disk.name)") {
                    // This will be implemented later
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 120, height: 140)
        .padding(.vertical, 10)
    }
} 