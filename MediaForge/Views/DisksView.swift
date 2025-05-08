import SwiftUI
import AppKit

/// View that shows sources and destinations
struct DisksView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var showTransferView = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Disks")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Toggle between disks and transfers view
                Button {
                    showTransferView.toggle()
                } label: {
                    Image(systemName: "chevron.up")
                        .foregroundColor(.white)
                        .rotationEffect(showTransferView ? .degrees(180) : .degrees(0))
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Sources section
                    VStack(alignment: .leading) {
                        Text("SOURCES")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.sources) { disk in
                                    DiskView(disk: disk, viewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Destinations section
                    VStack(alignment: .leading) {
                        Text("DESTINATIONS")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.destinations) { disk in
                                    DiskView(disk: disk, viewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Available disks section
                    VStack(alignment: .leading) {
                        Text("AVAILABLE DISKS")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.availableDisks.filter { !$0.isSource && !$0.isDestination }) { disk in
                                    DiskView(disk: disk, viewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            
            // Bottom controls
            HStack {
                Spacer()
                
                // Add transfers button
                Button {
                    viewModel.createTransfers()
                    viewModel.startTransfers()
                } label: {
                    Text("Add \(viewModel.potentialTransferCount) Transfer\(viewModel.potentialTransferCount > 1 ? "s" : "")")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue)
                        )
                }
                .disabled(viewModel.potentialTransferCount == 0)
                .opacity(viewModel.potentialTransferCount == 0 ? 0.5 : 1.0)
            }
            .padding()
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .alert(isPresented: $viewModel.showPermissionAlert) {
            Alert(
                title: Text("Permission Required"),
                message: Text(viewModel.permissionErrorMessage),
                primaryButton: .default(Text("Open System Settings")) {
                    if let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                        NSWorkspace.shared.open(settingsURL)
                    }
                },
                secondaryButton: .cancel(Text("OK"))
            )
        }
    }
} 