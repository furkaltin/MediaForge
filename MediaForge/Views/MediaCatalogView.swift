import SwiftUI
import Foundation

/// Main view for the media catalog feature
struct MediaCatalogView: View {
    @ObservedObject var viewModel: MediaForgeViewModel
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var selectedSortOption = SortOption.dateDesc
    @State private var showingAddCollection = false
    @State private var selectedItems: Set<UUID> = []
    @State private var showingComparisonView = false
    @State private var comparisonSelectedItem: CatalogItem?
    @State private var comparisonSecondaryItem: CatalogItem?
    
    enum SortOption: String, CaseIterable {
        case nameAsc = "Name (A-Z)"
        case nameDesc = "Name (Z-A)"
        case dateAsc = "Date (Oldest)"
        case dateDesc = "Date (Newest)"
        case typeAsc = "Type (A-Z)"
        case typeDesc = "Type (Z-A)"
    }
    
    var filteredItems: [CatalogItem] {
        var items = viewModel.catalogItems
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.filePath.localizedCaseInsensitiveContains(searchText) ||
                item.metadata.values.contains { value in
                    value.localizedCaseInsensitiveContains(searchText)
                } ||
                item.customMetadata.values.contains { value in
                    value.localizedCaseInsensitiveContains(searchText)
                } ||
                item.tags.contains { tag in
                    tag.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .nameAsc:
            items.sort { $0.name < $1.name }
        case .nameDesc:
            items.sort { $0.name > $1.name }
        case .dateAsc:
            items.sort { $0.dateAdded < $1.dateAdded }
        case .dateDesc:
            items.sort { $0.dateAdded > $1.dateAdded }
        case .typeAsc:
            items.sort { $0.type < $1.type }
        case .typeDesc:
            items.sort { $0.type > $1.type }
        }
        
        return items
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Media Catalog")
                    .font(.headline)
                
                Spacer()
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search media...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .frame(width: 250)
                
                Picker("Sort", selection: $selectedSortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 150)
                
                Button(action: {
                    // Add new media
                    showFileImporter()
                }) {
                    Image(systemName: "plus")
                }
                
                Button(action: {
                    // Export selected items
                    if !selectedItems.isEmpty {
                        exportSelectedItems()
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(selectedItems.isEmpty)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Content area
            HSplitView {
                // Collections sidebar
                VStack {
                    List {
                        // All items section
                        Section(header: Text("Library")) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("All Media")
                                Spacer()
                                Text("\(viewModel.catalogItems.count)")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            
                            HStack {
                                Image(systemName: "star.fill")
                                Text("Favorites")
                                Spacer()
                                Text("\(viewModel.catalogItems.filter { $0.rating ?? 0 >= 4 }.count)")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Verified")
                                Spacer()
                                Text("\(viewModel.catalogItems.filter { $0.isVerified }.count)")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Custom collections
                        Section(header: 
                            HStack {
                                Text("Collections")
                                Spacer()
                                Button(action: {
                                    showingAddCollection = true
                                }) {
                                    Image(systemName: "plus.circle")
                                        .font(.caption)
                                }
                            }
                        ) {
                            ForEach(viewModel.mediaCollections) { collection in
                                HStack {
                                    if let color = collection.color {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 12, height: 12)
                                    } else {
                                        Circle()
                                            .fill(Color.gray)
                                            .frame(width: 12, height: 12)
                                    }
                                    
                                    Text(collection.name)
                                    
                                    Spacer()
                                    
                                    Text("\(collection.items.count)")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                                .contextMenu {
                                    Button("Rename Collection") {
                                        // Rename action
                                    }
                                    
                                    Button("Change Color") {
                                        // Change color action
                                    }
                                    
                                    Divider()
                                    
                                    Button("Delete Collection") {
                                        viewModel.removeMediaCollection(collection)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(SidebarListStyle())
                }
                .frame(minWidth: 220)
                
                // Media grid/list view
                VStack {
                    // View style picker
                    Picker("View", selection: $selectedTab) {
                        Text("Grid").tag(0)
                        Text("List").tag(1)
                        Text("Details").tag(2)
                        Text("Timeline").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    TabView(selection: $selectedTab) {
                        // Grid view
                        mediaGridView
                            .tag(0)
                        
                        // List view
                        mediaListView
                            .tag(1)
                        
                        // Details view
                        mediaDetailsView
                            .tag(2)
                        
                        // Timeline view
                        timelineView
                            .tag(3)
                    }
                    .tabViewStyle(DefaultTabViewStyle())
                }
            }
        }
        .sheet(isPresented: $showingAddCollection) {
            addCollectionView
        }
        .sheet(isPresented: $showingComparisonView) {
            if let item = comparisonSelectedItem {
                MediaComparisonView(viewModel: viewModel, primaryItem: item, secondaryItem: comparisonSecondaryItem)
            }
        }
    }
    
    // Grid view of media items
    var mediaGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)], spacing: 16) {
                ForEach(filteredItems) { item in
                    mediaItemCell(item)
                }
            }
            .padding()
        }
    }
    
    // Individual media item cell for grid view
    func mediaItemCell(_ item: CatalogItem) -> some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                
                // Item thumbnail or placeholder
                if item.type.contains("video") {
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                } else if item.type.contains("audio") {
                    Image(systemName: "waveform")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "doc")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                
                // Verification badge
                if item.isVerified {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .background(Circle().fill(Color.white))
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.caption)
                    .lineLimit(1)
                
                HStack {
                    if let resolution = item.resolution {
                        Text(resolution)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if item.rating ?? 0 > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= (item.rating ?? 0) ? "star.fill" : "star")
                                    .font(.system(size: 8))
                                    .foregroundColor(i <= (item.rating ?? 0) ? .yellow : .gray)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .background(selectedItems.contains(item.id) ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            toggleItemSelection(item.id)
        }
        .contextMenu {
            Button("View Media") {
                // Open media viewer
            }
            
            Button("Edit Metadata") {
                // Open metadata editor
            }
            
            Button("Compare Media") {
                showComparisonTool(for: item)
            }
            
            Menu("Add to Collection") {
                ForEach(viewModel.mediaCollections) { collection in
                    Button(collection.name) {
                        // Add to collection
                        let updatedCollection = collection
                        updatedCollection.items.append(item.id)
                        viewModel.updateMediaCollection(updatedCollection)
                    }
                }
            }
            
            Divider()
            
            Button("Delete") {
                viewModel.removeCatalogItem(item)
            }
        }
    }
    
    // List view of media items
    var mediaListView: some View {
        List {
            ForEach(filteredItems) { item in
                HStack {
                    if selectedItems.contains(item.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text(item.type)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let duration = item.duration {
                                Text(MediaCatalogView.formatDuration(duration))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if item.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                    
                    Text(formatDate(item.dateAdded))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleItemSelection(item.id)
                }
            }
        }
    }
    
    // Details view with table of media items
    var mediaDetailsView: some View {
        VStack {
            HStack {
                Text("Name")
                    .fontWeight(.bold)
                    .frame(width: 200, alignment: .leading)
                
                Text("Type")
                    .fontWeight(.bold)
                    .frame(width: 100, alignment: .leading)
                
                Text("Resolution")
                    .fontWeight(.bold)
                    .frame(width: 120, alignment: .leading)
                
                Text("Duration")
                    .fontWeight(.bold)
                    .frame(width: 100, alignment: .leading)
                
                Text("Date Added")
                    .fontWeight(.bold)
                    .frame(width: 120, alignment: .leading)
                
                Text("Status")
                    .fontWeight(.bold)
                    .frame(width: 100, alignment: .leading)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            
            List {
                ForEach(filteredItems) { item in
                    HStack {
                        // Name with icon
                        HStack {
                            if item.type.contains("video") {
                                Image(systemName: "film")
                                    .foregroundColor(.blue)
                            } else if item.type.contains("audio") {
                                Image(systemName: "waveform")
                                    .foregroundColor(.purple)
                            } else if item.type.contains("image") {
                                Image(systemName: "photo")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "doc")
                                    .foregroundColor(.gray)
                            }
                            
                            Text(item.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(width: 200, alignment: .leading)
                        
                        // Type
                        Text(item.type)
                            .frame(width: 100, alignment: .leading)
                        
                        // Resolution
                        Text(item.resolution ?? "—")
                            .frame(width: 120, alignment: .leading)
                        
                        // Duration
                        Text(item.duration != nil ? MediaCatalogView.formatDuration(item.duration!) : "—")
                            .frame(width: 100, alignment: .leading)
                        
                        // Date added
                        Text(formatDate(item.dateAdded))
                            .frame(width: 120, alignment: .leading)
                        
                        // Status
                        HStack {
                            Circle()
                                .fill(statusColor(for: item))
                                .frame(width: 8, height: 8)
                            
                            Text(statusText(for: item))
                        }
                        .frame(width: 100, alignment: .leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .background(selectedItems.contains(item.id) ? Color.blue.opacity(0.1) : Color.clear)
                    .onTapGesture {
                        toggleItemSelection(item.id)
                    }
                }
            }
        }
    }
    
    // Timeline view with chronological display
    var timelineView: some View {
        VStack(spacing: 0) {
            // Timeline controls
            HStack {
                Text("Timeline")
                    .font(.headline)
                
                Spacer()
                
                // Scale control
                HStack {
                    Text("Scale:")
                        .font(.caption)
                    
                    Slider(value: .constant(1.0), in: 0.1...10)
                        .frame(width: 100)
                }
                
                // Sort and filter options
                Picker("Sort by:", selection: .constant("Creation Time")) {
                    Text("Creation Time").tag("Creation Time")
                    Text("Timecode").tag("Timecode")
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 150)
                
                // Group by picker
                Picker("Group by:", selection: .constant("None")) {
                    Text("None").tag("None")
                    Text("Camera").tag("Camera")
                    Text("Scene").tag("Scene")
                    Text("Take").tag("Take")
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 150)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Main timeline scroll view
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    // Time ruler
                    TimelineRulerView()
                        .frame(height: 30)
                        .padding(.leading, 120) // Align with clip starts
                    
                    // Timeline tracks
                    ForEach(groupedTimelineItems.keys.sorted(), id: \.self) { group in
                        VStack(alignment: .leading, spacing: 2) {
                            // Group header
                            HStack {
                                Text(group)
                                    .font(.headline)
                                    .padding(.vertical, 4)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .background(Color.blue.opacity(0.1))
                            
                            // Clips in this group
                            ForEach(groupedTimelineItems[group] ?? [], id: \.id) { item in
                                TimelineClipView(item: item)
                            }
                        }
                        .padding(.bottom, 10)
                    }
                }
                .padding()
            }
        }
    }
    
    // Timeline ruler showing time markers
    struct TimelineRulerView: View {
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Ruler line
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 1)
                        .offset(y: 15)
                    
                    // Time markers
                    ForEach(0..<Int(geometry.size.width / 100) + 1, id: \.self) { index in
                        VStack(spacing: 2) {
                            // Hour tick
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: 1, height: 10)
                            
                            // Hour label
                            Text(formatTimeForRuler(hours: index))
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        .position(x: CGFloat(index * 100), y: 8)
                    }
                    
                    // Minute markers (every 10 min)
                    ForEach(0..<Int(geometry.size.width / 10) + 1, id: \.self) { index in
                        if index % 10 != 0 {
                            Rectangle()
                                .fill(Color.gray.opacity(0.7))
                                .frame(width: 1, height: 5)
                                .position(x: CGFloat(index * 10), y: 8)
                        }
                    }
                }
            }
        }
        
        private func formatTimeForRuler(hours: Int) -> String {
            return "\(hours):00"
        }
    }
    
    // A single clip in the timeline
    struct TimelineClipView: View {
        let item: CatalogItem
        
        // Computed properties for visual display
        private var clipColor: Color {
            if item.type.contains("video") {
                return .blue
            } else if item.type.contains("audio") {
                return .purple
            } else if item.type.contains("image") {
                return .green
            } else {
                return .gray
            }
        }
        
        private var clipWidth: CGFloat {
            // Base width on duration, with a minimum size
            let baseDuration: TimeInterval = item.duration ?? 30
            return max(100, CGFloat(baseDuration) * 2) // 2 pixels per second
        }
        
        var body: some View {
            HStack(spacing: 0) {
                // Metadata sidebar
                VStack(alignment: .trailing) {
                    Text(item.name)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    if let resolution = item.resolution {
                        Text(resolution)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 100, alignment: .trailing)
                .padding(.trailing, 8)
                
                // Clip visualization
                ZStack(alignment: .leading) {
                    // Clip background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(clipColor.opacity(0.2))
                        .frame(width: clipWidth, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(clipColor, lineWidth: 1)
                        )
                    
                    // Clip label
                    HStack {
                        // Type icon
                        Group {
                            if item.type.contains("video") {
                                Image(systemName: "film")
                            } else if item.type.contains("audio") {
                                Image(systemName: "waveform")
                            } else if item.type.contains("image") {
                                Image(systemName: "photo")
                            } else {
                                Image(systemName: "doc")
                            }
                        }
                        .foregroundColor(clipColor)
                        
                        // Name and duration
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.caption)
                                .lineLimit(1)
                            
                            if let duration = item.duration {
                                Text(MediaCatalogView.formatDuration(duration))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
                .padding(.vertical, 2)
            }
            .contentShape(Rectangle())
            .contextMenu {
                Button("View Media") {
                    // Open media viewer
                }
                
                Button("Edit Metadata") {
                    // Open metadata editor
                }
                
                Divider()
                
                Button("Select Media") {
                    // Add to selection
                }
            }
        }
    }
    
    // Format duration as a string
    static func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "—"
    }
    
    // Format date as a string
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    // Computed property for grouped timeline items
    var groupedTimelineItems: [String: [CatalogItem]] {
        let items = filteredItems
        
        // Default grouping - all in one group
        var groupedItems: [String: [CatalogItem]] = ["All Media": items]
        
        // Group by specific metadata field if selected
        // This would be expanded based on the grouping selection
        
        return groupedItems
    }
    
    // Add collection sheet
    var addCollectionView: some View {
        VStack {
            Text("Create New Collection")
                .font(.headline)
                .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Collection Name")
                    .font(.subheadline)
                
                TextField("Enter name...", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 8)
                
                Text("Color")
                    .font(.subheadline)
                
                HStack {
                    ForEach([Color.red, .orange, .yellow, .green, .blue, .purple, .gray], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                            .padding(4)
                    }
                }
                
                Text("Notes")
                    .font(.subheadline)
                
                TextEditor(text: .constant(""))
                    .frame(height: 100)
                    .border(Color.gray.opacity(0.2))
            }
            .padding()
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    showingAddCollection = false
                }
                
                Spacer()
                
                Button("Create Collection") {
                    // Create collection (just dismiss for now)
                    showingAddCollection = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 400, height: 400)
    }
    
    // Helper methods
    
    func toggleItemSelection(_ id: UUID) {
        if selectedItems.contains(id) {
            selectedItems.remove(id)
        } else {
            selectedItems.insert(id)
        }
    }
    
    func statusColor(for item: CatalogItem) -> Color {
        switch item.verificationState {
        case .verified:
            return .green
        case .failed, .mismatch:
            return .red
        case .verifying:
            return .orange
        case .notVerified:
            return .gray
        }
    }
    
    func statusText(for item: CatalogItem) -> String {
        return item.verificationState.rawValue
    }
    
    func showFileImporter() {
        // Would trigger file import dialog
        // Not implemented here since we can't show system dialogs in SwiftUI preview
    }
    
    func exportSelectedItems() {
        // Would prompt export dialog
        // Not implemented here since we can't show system dialogs in SwiftUI preview
    }
    
    func showComparisonTool(for item: CatalogItem) {
        comparisonSelectedItem = item
        
        // If there are already items selected in the catalog view, use the first one as the comparison item
        if selectedItems.count > 0 {
            // Find a different item for comparison
            let potentialComparisonItem = filteredItems.first { 
                $0.id != item.id && selectedItems.contains($0.id)
            }
            comparisonSecondaryItem = potentialComparisonItem
        } else {
            comparisonSecondaryItem = nil
        }
        
        showingComparisonView = true
    }
}

struct MediaCatalogView_Previews: PreviewProvider {
    static var previews: some View {
        MediaCatalogView(viewModel: MediaForgeViewModel())
    }
} 