//
//  ContentView.swift
//  MediaForge
//
//  Created by Selin Çağlar on 7.05.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: MediaForgeViewModel
    @State private var selectedTab: Tab = .dashboard
    @State private var showSidebar: Bool = true
    @State private var animateBackground = false
    
    enum Tab {
        case dashboard, disks, transfers, settings, presets
    }
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            backgroundGradient
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Sidebar
                if showSidebar {
                    sidebar
                        .frame(width: 220)
                        .background(
                            ZStack {
                                Color.black.opacity(0.4)
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.2))
                                    .blur(radius: 10)
                                    .padding(.trailing, -10)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .transition(.move(edge: .leading))
                }
                
                // Main content area with glass effect
                ZStack {
                    // Blurred content background
                    RoundedRectangle(cornerRadius: showSidebar ? 20 : 0)
                        .fill(Color.black.opacity(0.1))
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: showSidebar ? 20 : 0)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
                    
                    // Content based on selected tab
                    VStack(spacing: 0) {
                        // Toolbar
                        HStack {
                            // Toggle sidebar button
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showSidebar.toggle()
                                }
                            } label: {
                                Image(systemName: showSidebar ? "sidebar.left" : "sidebar.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 30, height: 30)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            
                            // Status message
                            if !viewModel.statusMessage.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                    Text(viewModel.statusMessage)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(1)
                                    
                                    Button {
                                        viewModel.statusMessage = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                            }
                            
                            Spacer()
                            
                            // Status information
                            HStack(spacing: 15) {
                                // Active transfers badge
                                if !viewModel.activeTransfers.isEmpty {
                                    HStack(spacing: 5) {
                                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                                            .foregroundColor(.green)
                                        Text("\(viewModel.activeTransfers.count) Active")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.black.opacity(0.2))
                                    .cornerRadius(20)
                                }
                                
                                // Refresh button
                                Button {
                                    withAnimation {
                                        viewModel.refreshDisks()
                                    }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .frame(width: 30, height: 30)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 15)
                        .padding(.bottom, 10)
                        
                        // Main content
                        ZStack {
                            switch selectedTab {
                            case .dashboard:
                                dashboardView
                            case .disks:
                                DisksView(viewModel: viewModel)
                            case .transfers:
                                TransfersView(viewModel: viewModel)
                            case .presets:
                                TransferPresetsView(viewModel: viewModel)
                            case .settings:
                                SettingsView(viewModel: viewModel)
                            }
                        }
                        .padding(10)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: showSidebar ? 20 : 0))
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
            }
            .padding(10)
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.activeTransfers.count) { _, newCount in
            if newCount > 0 && selectedTab != .transfers {
                withAnimation {
                    selectedTab = .transfers
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowDisksView"))) { _ in
            withAnimation {
                selectedTab = .disks
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowDashboardView"))) { _ in
            withAnimation {
                selectedTab = .dashboard
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowTransfersView"))) { _ in
            withAnimation {
                selectedTab = .transfers
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                self.animateBackground = true
            }
        }
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
    
    // Sidebar view
    var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo area with improved styling
            VStack(alignment: .leading, spacing: 5) {
                Text("MEDIA")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                
                Text("FORGE")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .offset(x: 10)
                
                Text("Professional Media Transfer Tool")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 25)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.18),
                        Color(red: 0.15, green: 0.15, blue: 0.22)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            Divider()
                .background(Color.white.opacity(0.15))
                .padding(.horizontal, 20)
            
            // Navigation menu with improved styling
            VStack(spacing: 8) {
                Spacer().frame(height: 10)
                navButton(title: "Dashboard", icon: "square.grid.2x2", tab: .dashboard)
                navButton(title: "Disks", icon: "externaldrive.fill", tab: .disks)
                navButton(title: "Transfers", icon: "arrow.up.arrow.down", tab: .transfers)
                navButton(title: "Presets", icon: "list.bullet.rectangle", tab: .presets)
                navButton(title: "Settings", icon: "gear", tab: .settings)
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Status section with improved styling
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Circle()
                        .fill(viewModel.activeTransfers.isEmpty ? Color.green : Color.orange)
                        .frame(width: 10, height: 10)
                        .shadow(color: viewModel.activeTransfers.isEmpty ? Color.green.opacity(0.5) : Color.orange.opacity(0.5), radius: 5)
                    
                    Text(viewModel.activeTransfers.isEmpty ? "System Ready" : "Transfers Active")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            viewModel.activeTransfers.isEmpty ? Color.green.opacity(0.3) : Color.orange.opacity(0.3),
                                            Color.clear
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                
                HStack {
                    Text("Disks Connected:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("\(viewModel.availableDisks.count)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.3, green: 0.3, blue: 0.6),
                                            Color(red: 0.2, green: 0.2, blue: 0.4)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 2)
                        )
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 25)
            .padding(.horizontal, 10)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.18).opacity(0.5),
                        Color(red: 0.15, green: 0.15, blue: 0.22).opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .background(
            ZStack {
                // Base background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.15, green: 0.15, blue: 0.22),
                        Color(red: 0.10, green: 0.10, blue: 0.15)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Subtle pattern overlay
                Rectangle()
                    .fill(Color.white.opacity(0.03))
                    .mask(
                        Image(systemName: "rectangle.grid.3x2")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(0.3)
                    )
                    .blur(radius: 0.5)
            }
        )
        .overlay(
            Rectangle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .frame(width: 1),
            alignment: .trailing
        )
        .contentShape(Rectangle())
    }
    
    // Navigation button with improved styling
    func navButton(title: String, icon: String, tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 14) {
                // Icon with improved styling
                ZStack {
                    if selectedTab == tab {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.7))
                        .frame(width: 36, height: 36)
                }
                
                Text(title)
                    .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                    .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.7))
                    .fixedSize(horizontal: true, vertical: false)
                    .lineLimit(1)
                
                Spacer()
                
                if selectedTab == tab {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .shadow(color: Color.white.opacity(0.5), radius: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.2, green: 0.2, blue: 0.33).opacity(0.9),
                                        Color(red: 0.15, green: 0.15, blue: 0.25).opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.2),
                                                Color.white.opacity(0.05),
                                                Color.clear
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
                    }
                }
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
    }
    
    // Background gradient with animation
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.05, blue: 0.1),
                Color(red: 0.1, green: 0.05, blue: 0.15),
                Color(red: 0.05, green: 0.1, blue: 0.2)
            ]),
            startPoint: animateBackground ? .topLeading : .bottomLeading,
            endPoint: animateBackground ? .bottomTrailing : .topTrailing
        )
        .overlay(
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: animateBackground ? 200 : -200, y: -100)
                
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: animateBackground ? -250 : 250, y: 300)
            }
        )
    }
    
    // Dashboard view
    var dashboardView: some View {
        VStack(spacing: 25) {
            // Dashboard header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Media Transfer Dashboard")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Monitor and manage your media transfers")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Stats cards
            HStack(spacing: 20) {
                // Disk stats
                statsCard(
                    title: "Disks",
                    value: "\(viewModel.availableDisks.count)",
                    detail: "Connected",
                    icon: "externaldrive.fill",
                    color: .blue
                )
                
                // Source stats
                statsCard(
                    title: "Sources",
                    value: "\(viewModel.sources.count)",
                    detail: "Selected",
                    icon: "arrow.up.doc",
                    color: .purple
                )
                
                // Destination stats
                statsCard(
                    title: "Destinations",
                    value: "\(viewModel.destinations.count)",
                    detail: "Selected",
                    icon: "arrow.down.doc",
                    color: .green
                )
                
                // Transfer stats
                statsCard(
                    title: "Transfers",
                    value: "\(viewModel.activeTransfers.count)",
                    detail: "Active",
                    icon: "arrow.triangle.2.circlepath",
                    color: .orange
                )
            }
            .padding(.horizontal, 10)
            
            // Quick actions
            VStack(alignment: .leading, spacing: 15) {
                Text("Quick Actions")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 15) {
                    // Setup disks action
                    actionButton(
                        title: "Select Devices",
                        icon: "externaldrive.badge.plus",
                        description: "Configure sources and destinations",
                        action: { selectedTab = .disks }
                    )
                    
                    // Start transfer action
                    actionButton(
                        title: "Start Transfer",
                        icon: "arrow.up.arrow.down.circle",
                        description: "Begin a new media transfer",
                        isDisabled: viewModel.sources.isEmpty || viewModel.destinations.isEmpty,
                        action: {
                            viewModel.createTransfers()
                            viewModel.startTransfers()
                            selectedTab = .transfers
                        }
                    )
                    
                    // View transfers action
                    actionButton(
                        title: "View Transfers",
                        icon: "list.bullet.rectangle",
                        description: "Monitor active and completed transfers",
                        action: { selectedTab = .transfers }
                    )
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Status footer
            if !viewModel.activeTransfers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Active Transfer Status")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button {
                            selectedTab = .transfers
                        } label: {
                            Text("View All")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(viewModel.activeTransfers.prefix(2)) { transfer in
                            HStack {
                                Image(systemName: "arrow.up.arrow.down.circle.fill")
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(transfer.source.name) → \(transfer.destination.name)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    // Progress bar
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 6)
                                        
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.green)
                                            .frame(width: CGFloat(transfer.progress) * 200, height: 6)
                                    }
                                    .frame(width: 200)
                                }
                                
                                Spacer()
                                
                                Text("\(Int(transfer.progress * 100))%")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(20)
                .background(Color.black.opacity(0.2))
                .cornerRadius(15)
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // Settings view placeholder
    var settingsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gear")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Settings")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Application settings and preferences will appear here.")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Stats card component
    func statsCard(title: String, value: String, detail: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(15)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 15)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            }
        )
        .frame(maxWidth: .infinity)
    }
    
    // Action button component
    func actionButton(title: String, icon: String, description: String, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isDisabled ? .gray : .white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(isDisabled ? .gray.opacity(0.5) : .white.opacity(0.5))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDisabled ? .gray : .white)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(isDisabled ? .gray.opacity(0.7) : .white.opacity(0.7))
                        .lineLimit(2)
                }
            }
            .padding(15)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isDisabled ? Color.black.opacity(0.2) : Color(red: 0.15, green: 0.15, blue: 0.2))
                    
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isDisabled ? Color.gray.opacity(0.2) : Color.white.opacity(0.1), lineWidth: 1)
                }
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

#Preview {
    ContentView()
        .environmentObject(MediaForgeViewModel())
}
