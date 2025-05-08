//
//  ContentView.swift
//  MediaForge
//
//  Created by Selin Çağlar on 7.05.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: MediaForgeViewModel
    @State private var showingTransfers = false
    
    var body: some View {
        ZStack {
            // Background color
            Color(red: 0.1, green: 0.1, blue: 0.1)
                .ignoresSafeArea()
            
            VStack {
                // Top navigation bar
                HStack {
                    Spacer()
                    
                    // Toggle button between Disks and Transfers
                    Button {
                        showingTransfers.toggle()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: showingTransfers ? "folder" : "arrow.triangle.2.circlepath")
                                .imageScale(.medium)
                            Text(showingTransfers ? "Show Disks" : "Show Transfers")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)
                    }
                    .foregroundColor(.white)
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Content area
                if showingTransfers {
                    TransfersView(viewModel: viewModel)
                } else {
                    DisksView(viewModel: viewModel)
                }
                
                Spacer()
            }
            .frame(minWidth: 800, minHeight: 600)
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.activeTransfers.count) { _, newCount in
            // When a transfer becomes active, switch to transfers view
            if newCount > 0 && !showingTransfers {
                showingTransfers = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowDisksView"))) { _ in
            // Switch to disks view when receiving this notification
            showingTransfers = false
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MediaForgeViewModel())
}
