import SwiftUI
import AppKit

/// View that shows sources and destinations
struct DisksView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    
    // Column layout for the grid - reduced from 5 to 3 columns with increased spacing
    let columns = Array(repeating: GridItem(.adaptive(minimum: 280, maximum: 350), spacing: 20), count: 3)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header section
            HStack {
                // Sources header
                Text("Sources")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("(\(viewModel.sources.count))")
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Add Transfer button (when sources and destinations are selected)
                if !viewModel.sources.isEmpty && !viewModel.destinations.isEmpty {
                    Button {
                        viewModel.createTransfers()
                        viewModel.startTransfers()
                        
                        // Notify to switch to transfers view
                        NotificationCenter.default.post(
                            name: Notification.Name("ShowTransfersView"),
                            object: nil
                        )
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right")
                            Text("Start \(viewModel.potentialTransferCount) Transfer\(viewModel.potentialTransferCount > 1 ? "s" : "")")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(6)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Create transfers from selected sources to destinations")
                }
                
                // Refresh button
                Button {
                    viewModel.refreshDisks()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.gray)
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("Refresh disk list")
            }
            .padding(.horizontal)
            
            // Selected sources section
            if !viewModel.sources.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(viewModel.sources) { disk in
                            DiskView(
                                disk: disk,
                                viewModel: viewModel,
                                onSourceClick: { viewModel.setDiskAsSource(disk) },
                                onDestinationClick: { viewModel.setDiskAsDestination(disk) },
                                onUnuseClick: { viewModel.setDiskAsUnused(disk) }
                            )
                            .frame(width: 300, height: 200)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 10)
            }
            
            Divider()
                .background(Color.gray.opacity(0.5))
                .padding(.horizontal)
            
            // Destinations header
            HStack {
                Text("Destinations")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("(\(viewModel.destinations.count))")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Selected destinations section
            if !viewModel.destinations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(viewModel.destinations) { disk in
                            DiskView(
                                disk: disk,
                                viewModel: viewModel,
                                onSourceClick: { viewModel.setDiskAsSource(disk) },
                                onDestinationClick: { viewModel.setDiskAsDestination(disk) },
                                onUnuseClick: { viewModel.setDiskAsUnused(disk) }
                            )
                            .frame(width: 300, height: 200)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 10)
            }
            
            Divider()
                .background(Color.gray.opacity(0.5))
                .padding(.horizontal)
            
            // Available disks header
            HStack {
                Text("Available Disks")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Available disks grid - improved layout
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.availableDisks.filter { !$0.isSource && !$0.isDestination }) { disk in
                        DiskView(
                            disk: disk,
                            viewModel: viewModel,
                            onSourceClick: { viewModel.setDiskAsSource(disk) },
                            onDestinationClick: { viewModel.setDiskAsDestination(disk) },
                            onUnuseClick: { viewModel.setDiskAsUnused(disk) }
                        )
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 200)
                    }
                }
                .padding()
            }
        }
        .padding(.vertical)
        .alert(isPresented: $viewModel.showPermissionAlert) {
            Alert(
                title: Text("Permission Required"),
                message: Text(viewModel.permissionErrorMessage),
                primaryButton: .default(Text("Settings")) {
                    viewModel.openSystemSettingsForPermissions()
                },
                secondaryButton: .cancel()
            )
        }
    }
} 