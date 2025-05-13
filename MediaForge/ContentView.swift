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
    
    // Sheet states
    @State private var showingSettingsSheet = false
    @State private var showingElementReview = false
    
    // Notification center token
    @State private var elementReviewToken: NSObjectProtocol?
    
    enum Tab {
        case dashboard, disks, transfers, settings, presets
    }
    
    var body: some View {
        ZStack {
            // Dynamic gradient background - enhanced for Sequoia
            backgroundGradient
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Sidebar - improved for Sequoia
                if showSidebar {
                    sidebar
                        .frame(width: 230)
                        .background(
                            ZStack {
                                // Modern Sequoia style blur with depth
                                Color.black.opacity(0.2)
                                    .background(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.1))
                                    .background(
                                        .thinMaterial,
                                        in: RoundedRectangle(cornerRadius: 20)
                                    )
                                    .blur(radius: 1)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.05),
                                            Color.clear,
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
                        .transition(.move(edge: .leading))
                }
                
                // Main content area with enhanced Sequoia glass effect
                ZStack {
                    // Modern blur and material effects
                    RoundedRectangle(cornerRadius: showSidebar ? 20 : 0)
                        .fill(Color.clear)
                        .background(
                            .regularMaterial,
                            in: RoundedRectangle(cornerRadius: showSidebar ? 20 : 0)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: showSidebar ? 20 : 0)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.1),
                                            Color.white.opacity(0.05),
                                            Color.clear,
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
                    
                    // Content based on selected tab
                    VStack(spacing: 0) {
                        // Toolbar - enhanced style
                        HStack {
                            // Toggle sidebar button - improved style
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showSidebar.toggle()
                                }
                            } label: {
                                Image(systemName: showSidebar ? "sidebar.left" : "sidebar.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(width: 34, height: 34)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.06))
                                            .background(
                                                .ultraThinMaterial,
                                                in: Circle()
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .contentShape(Circle())
                            .help(showSidebar ? "Kenar Çubuğunu Gizle" : "Kenar Çubuğunu Göster")
                            
                            // Status message - improved style
                            if !viewModel.statusMessage.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 14))
                                    Text(viewModel.statusMessage)
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Button {
                                        viewModel.statusMessage = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                    .contentShape(Circle())
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.1))
                                        .background(
                                            .ultraThinMaterial,
                                            in: Capsule()
                                        )
                                )
                            }
                            
                            Spacer()
                            
                            // Status information - improved style
                            HStack(spacing: 15) {
                                // Active transfers badge - improved style
                                if !viewModel.activeTransfers.isEmpty {
                                    HStack(spacing: 5) {
                                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 14))
                                        Text("\(viewModel.activeTransfers.count) Aktif")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary.opacity(0.9))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.green.opacity(0.1))
                                            .background(
                                                .ultraThinMaterial,
                                                in: Capsule()
                                            )
                                    )
                                }
                                
                                // Refresh button - improved style
                                Button {
                                    withAnimation {
                                        viewModel.refreshDisks()
                                    }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary.opacity(0.8))
                                        .frame(width: 34, height: 34)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.06))
                                                .background(
                                                    .ultraThinMaterial,
                                                    in: Circle()
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                                .contentShape(Circle())
                                .help("Diskleri Yenile")
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
            
            // Register for ShowElementReviewPanel notification
            elementReviewToken = NotificationCenter.default.addObserver(
                forName: Notification.Name("ShowElementReviewPanel"),
                object: nil,
                queue: .main
            ) { _ in
                showingElementReview = true
            }
        }
        .onDisappear {
            // Clean up notification observer
            if let token = elementReviewToken {
                NotificationCenter.default.removeObserver(token)
            }
        }
        .alert(isPresented: $viewModel.showPermissionAlert) {
            Alert(
                title: Text("Tam Disk Erişimi Gerekli"),
                message: Text("MediaForge, \(viewModel.permissionErrorDisk) diskine tam erişime ihtiyaç duyuyor. Lütfen Sistem Ayarları > Gizlilik ve Güvenlik > Tam Disk Erişimi bölümünden izin verin."),
                primaryButton: .default(Text("Sistem Ayarlarını Aç")) {
                    // Open the Security & Privacy pane in System Preferences
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                },
                secondaryButton: .cancel(Text("İptal"))
            )
        }
        .sheet(isPresented: $showingElementReview) {
            ElementReviewPanelView(viewModel: viewModel) { completed in
                showingElementReview = false
                
                if completed {
                    // Continue with transfer setup
                    viewModel.continueAfterElementReview()
                }
            }
        }
    }
    
    // Sidebar view - enhanced style for Sequoia
    var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo area with improved Sequoia styling
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("MEDIA")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                    
                    Text("FORGE")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text("Professional Media Transfer Tool")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 25)
            .background(
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.15, green: 0.15, blue: 0.22).opacity(0.7),
                            Color(red: 0.12, green: 0.12, blue: 0.18).opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Subtle pattern for depth
                    Color.white.opacity(0.02)
                        .background(
                            .ultraThinMaterial,
                            in: Rectangle()
                        )
                }
            )
            
            Divider()
                .background(Color.white.opacity(0.15))
                .padding(.horizontal, 20)
            
            // Navigation menu with improved Sequoia styling
            VStack(spacing: 8) {
                Spacer().frame(height: 10)
                navButton(title: "Dashboard", icon: "square.grid.2x2", tab: .dashboard)
                navButton(title: "Diskler", icon: "externaldrive.fill", tab: .disks)
                navButton(title: "Transferler", icon: "arrow.up.arrow.down", tab: .transfers)
                navButton(title: "Hazır Ayarlar", icon: "list.bullet.rectangle", tab: .presets)
                navButton(title: "Ayarlar", icon: "gear", tab: .settings)
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Status section with improved Sequoia styling
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Circle()
                        .fill(viewModel.activeTransfers.isEmpty ? Color.green : Color.orange)
                        .frame(width: 10, height: 10)
                        .shadow(color: viewModel.activeTransfers.isEmpty ? Color.green.opacity(0.5) : Color.orange.opacity(0.5), radius: 5)
                    
                    Text(viewModel.activeTransfers.isEmpty ? "Sistem Hazır" : "Transferler Aktif")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
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
                    Text("Bağlı Diskler:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("\(viewModel.availableDisks.count)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
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
                                .background(
                                    .ultraThinMaterial,
                                    in: Circle()
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 2)
                        )
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 25)
            .padding(.horizontal, 10)
            .background(
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.12, green: 0.12, blue: 0.18).opacity(0.4),
                            Color(red: 0.15, green: 0.15, blue: 0.22).opacity(0.6)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Subtle material effect for depth
                    Color.clear
                        .background(
                            .ultraThinMaterial,
                            in: Rectangle()
                        )
                }
            )
        }
    }
    
    // Navigation button with improved Sequoia styling
    func navButton(title: String, icon: String, tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 14) {
                // Icon with improved Sequoia styling
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
                            .fill(Color.clear)
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 12)
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
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                    }
                }
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
    }
    
    // Background gradient with enhanced animation for Sequoia
    var backgroundGradient: some View {
        ZStack {
            // Base gradient with subtle Sequoia style
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.12, green: 0.08, blue: 0.18),
                    Color(red: 0.08, green: 0.12, blue: 0.22)
                ]),
                startPoint: animateBackground ? .topLeading : .bottomLeading,
                endPoint: animateBackground ? .bottomTrailing : .topTrailing
            )
            
            // Enhanced ambient light effects
            ZStack {
                // Ambiental glow spots
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 90)
                    .offset(x: animateBackground ? 200 : -200, y: -100)
                
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 90)
                    .offset(x: animateBackground ? -250 : 250, y: 300)
                
                // Additional subtle glow for depth
                Circle()
                    .fill(Color.indigo.opacity(0.1))
                    .frame(width: 350, height: 350)
                    .blur(radius: 100)
                    .offset(x: animateBackground ? 100 : -100, y: animateBackground ? 200 : -200)
            }
            
            // Subtle noise texture overlay for depth
            Rectangle()
                .fill(Color.white.opacity(0.01))
                .blendMode(.overlay)
        }
    }
    
    // Dashboard view
    var dashboardView: some View {
        VStack(spacing: 25) {
            // Dashboard header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Medya Transfer Panosu")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Medya transferlerinizi izleyin ve yönetin")
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
                    title: "Diskler",
                    value: "\(viewModel.availableDisks.count)",
                    detail: "Bağlı",
                    icon: "externaldrive.fill",
                    color: .blue
                )
                
                // Source stats
                statsCard(
                    title: "Kaynaklar",
                    value: "\(viewModel.sources.count)",
                    detail: "Seçili",
                    icon: "arrow.up.doc",
                    color: .purple
                )
                
                // Destination stats
                statsCard(
                    title: "Hedefler",
                    value: "\(viewModel.destinations.count)",
                    detail: "Seçili",
                    icon: "arrow.down.doc",
                    color: .green
                )
                
                // Transfer stats
                statsCard(
                    title: "Transferler",
                    value: "\(viewModel.activeTransfers.count)",
                    detail: "Aktif",
                    icon: "arrow.triangle.2.circlepath",
                    color: .orange
                )
            }
            .padding(.horizontal, 10)
            
            // Quick actions
            VStack(alignment: .leading, spacing: 15) {
                Text("Hızlı Eylemler")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 15) {
                    // Setup disks action
                    actionButton(
                        title: "Cihazları Seç",
                        icon: "externaldrive.badge.plus",
                        description: "Kaynakları ve hedefleri yapılandır",
                        action: { selectedTab = .disks }
                    )
                    
                    // Start transfer action
                    actionButton(
                        title: "Transfer Başlat",
                        icon: "arrow.up.arrow.down.circle",
                        description: "Yeni bir medya transferi başlat",
                        isDisabled: viewModel.sources.isEmpty || viewModel.destinations.isEmpty,
                        action: {
                            viewModel.createTransfers()
                            viewModel.startTransfers()
                            selectedTab = .transfers
                        }
                    )
                    
                    // View transfers action
                    actionButton(
                        title: "Transferleri Görüntüle",
                        icon: "list.bullet.rectangle",
                        description: "Aktif ve tamamlanmış transferleri izle",
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
                        Text("Aktif Transfer Durumu")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button {
                            selectedTab = .transfers
                        } label: {
                            Text("Tümünü Görüntüle")
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
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black.opacity(0.2))
                                    .background(
                                        .ultraThinMaterial,
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                            )
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.1))
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 15)
                        )
                )
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // Stats card component - Sequoia style update
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
                    .fill(Color.clear)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 15)
                    )
                
                RoundedRectangle(cornerRadius: 15)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            }
        )
        .frame(maxWidth: .infinity)
    }
    
    // Action button component - Sequoia style update
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
                        .fill(Color.clear)
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 15)
                        )
                    
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
