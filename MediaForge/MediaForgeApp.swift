//
//  MediaForgeApp.swift
//  MediaForge
//
//  Created by Selin Çağlar on 7.05.2025.
//

import SwiftUI

@main
struct MediaForgeApp: App {
    @StateObject private var viewModel = MediaForgeViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .preferredColorScheme(.dark)
                .environmentObject(viewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Add File menu
            CommandGroup(replacing: .newItem) {
                Button("New Transfer") {
                    // Post a notification to show the disk selection view
                    NotificationCenter.default.post(name: Notification.Name("ShowDisksView"), object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            // Add custom menus
            CommandMenu("Disks") {
                Button("Refresh Disk List") {
                    // Call into the view model to refresh disks
                    NotificationCenter.default.post(name: Notification.Name("RefreshDisks"), object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Divider()
                
                Button("Eject Selected Disk") {
                    // This will be implemented later
                }
                .keyboardShortcut("e", modifiers: .command)
            }
            
            CommandMenu("Transfers") {
                Button("Start All Transfers") {
                    viewModel.startTransfers()
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Pause All Transfers") {
                    // This will be implemented later
                }
                .keyboardShortcut("p", modifiers: .command)
                
                Button("Clear Completed Transfers") {
                    viewModel.clearCompletedTransfers()
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }
    }
}
