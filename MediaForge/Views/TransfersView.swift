import SwiftUI
import AppKit

/// View that displays all transfers
struct TransfersView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var showDisksView = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Transfers")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Toggle between transfers and disks view
                Button {
                    showDisksView.toggle()
                } label: {
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white)
                        .rotationEffect(showDisksView ? .degrees(180) : .degrees(0))
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // List of transfers
            ScrollView {
                // No transfers placeholder
                if viewModel.transfers.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "arrow.up.arrow.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                        
                        Text("No Transfers")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Select sources and destinations, then create a transfer.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Active transfers
                    if !viewModel.activeTransfers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ACTIVE TRANSFERS")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.activeTransfers) { transfer in
                                TransferItemView(transfer: transfer)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Completed transfers
                    if !viewModel.completedTransfers.isEmpty {
                        HStack {
                            Text("COMPLETED TRANSFERS")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Button {
                                viewModel.clearCompletedTransfers()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.horizontal)
                        
                        ForEach(viewModel.completedTransfers) { transfer in
                            TransferItemView(transfer: transfer)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Failed transfers
                    if !viewModel.failedTransfers.isEmpty {
                        HStack {
                            Text("FAILED TRANSFERS")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Button {
                                viewModel.clearFailedTransfers()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.horizontal)
                        
                        ForEach(viewModel.failedTransfers) { transfer in
                            TransferItemView(transfer: transfer)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
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