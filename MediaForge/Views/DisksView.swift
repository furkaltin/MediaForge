import SwiftUI
import AppKit

/// View that shows sources and destinations
struct DisksView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    
    // Fixed height for disk cards to ensure consistency
    private let diskCardHeight: CGFloat = 180
    private let sectionWidth: CGFloat = 320
    
    var body: some View {
        HStack(spacing: 0) {
            // SOURCES SECTION - LEFT
            VStack(alignment: .leading, spacing: 15) {
                // Header
                HStack {
                    Text("Sources")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("(\(viewModel.sources.count))")
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Drop area for sources with plus button
                if viewModel.sources.isEmpty {
                    sourceDropArea
                } else {
                    // List of selected sources
                    sourcesListView
                }
                
                Spacer()
            }
            .frame(width: sectionWidth)
            .padding(.vertical)
            .background(Color.black.opacity(0.2))
            .cornerRadius(15)
            
            Spacer(minLength: 20)
            
            // AVAILABLE DISKS SECTION - CENTER
            VStack(alignment: .leading, spacing: 15) {
                // Header with refresh button
                HStack {
                    Text("Available Disks")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
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
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Refresh disk list")
                }
                .padding(.horizontal)
                
                // Available disks grid with scrolling
                availableDisksGridView
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            .background(Color.black.opacity(0.15))
            .cornerRadius(15)
            
            Spacer(minLength: 20)
            
            // DESTINATIONS SECTION - RIGHT
            VStack(alignment: .leading, spacing: 15) {
                // Header
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
                
                // Drop area for destinations with plus button
                if viewModel.destinations.isEmpty {
                    destinationDropArea
                } else {
                    // List of selected destinations
                    destinationsListView
                }
                
                Spacer()
            }
            .frame(width: sectionWidth)
            .padding(.vertical)
            .background(Color.black.opacity(0.2))
            .cornerRadius(15)
        }
        .padding(15)
        .background(Color.black.opacity(0.1))
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
    
    // SOURCES VIEWS
    var sourceDropArea: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(height: diskCardHeight * 2.8)
                    .background(Color.blue.opacity(0.05).cornerRadius(15))
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "arrow.up.doc.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text("Drag disks here\nor select from Available Disks")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        
                    Button {
                        // Show picker dialog to select custom folder
                        viewModel.selectCustomSourceFolder()
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                            Text("Add Custom Folder")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Spacer()
                }
                .padding()
            }
            .contentShape(Rectangle()) // Tıklama alanını sınırla
            .padding(.horizontal)
        }
    }
    
    var sourcesListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(viewModel.sources) { disk in
                    DiskView(
                        disk: disk,
                        viewModel: viewModel,
                        onSourceClick: { viewModel.setDiskAsSource(disk) },
                        onDestinationClick: { viewModel.setDiskAsDestination(disk) },
                        onUnuseClick: { viewModel.setDiskAsUnused(disk) }
                    )
                    .frame(height: diskCardHeight)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // DESTINATIONS VIEWS
    var destinationDropArea: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(height: diskCardHeight * 2.8)
                    .background(Color.green.opacity(0.05).cornerRadius(15))
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "arrow.down.doc.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green.opacity(0.7))
                    
                    Text("Drag disks here\nor select from Available Disks")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        
                    Button {
                        // Show picker dialog to select custom folder
                        viewModel.selectCustomDestinationFolder()
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                            Text("Add Custom Folder")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Spacer()
                }
                .padding()
            }
            .contentShape(Rectangle()) // Tıklama alanını sınırla
            .padding(.horizontal)
        }
    }
    
    var destinationsListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(viewModel.destinations) { disk in
                    DiskView(
                        disk: disk,
                        viewModel: viewModel,
                        onSourceClick: { viewModel.setDiskAsSource(disk) },
                        onDestinationClick: { viewModel.setDiskAsDestination(disk) },
                        onUnuseClick: { viewModel.setDiskAsUnused(disk) }
                    )
                    .frame(height: diskCardHeight)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // AVAILABLE DISKS VIEW
    var availableDisksGridView: some View {
        let availableDisks = viewModel.availableDisks.filter { !$0.isSource && !$0.isDestination }
        
        return ScrollView(.vertical, showsIndicators: false) {
            if !availableDisks.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320, maximum: 360), spacing: 15)], spacing: 15) {
                    ForEach(availableDisks) { disk in
                        DiskView(
                            disk: disk,
                            viewModel: viewModel,
                            onSourceClick: { viewModel.setDiskAsSource(disk) },
                            onDestinationClick: { viewModel.setDiskAsDestination(disk) },
                            onUnuseClick: { viewModel.setDiskAsUnused(disk) }
                        )
                        .frame(height: diskCardHeight)
                    }
                }
                .padding(.horizontal)
            } else {
                // Empty state message when no available disks
                VStack(spacing: 20) {
                    Image(systemName: "externaldrive.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            .linearGradient(colors: [.gray, .gray.opacity(0.6)], 
                                           startPoint: .top, 
                                           endPoint: .bottom)
                        )
                        .symbolRenderingMode(.hierarchical)
                        .symbolEffect(.pulse.byLayer, options: .repeating)
                    
                    Text("No available disks found")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Connect an external drive or memory card")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                    
                    Button {
                        viewModel.refreshDisks()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(60)
            }
        }
    }
} 