import Foundation
import SwiftUI

/// A utility to run tests from the app
struct TestLauncher {
    
    /// Run all tests - can be called from a menu item or debug button
    static func runTests() {
        print("=== MediaForge Tests ===")
        print("Starting tests at \(Date())")
        
        // Choose which test to run
        let alert = NSAlert()
        alert.messageText = "MediaForge Tests"
        alert.informativeText = "Select a test to run:"
        
        alert.addButton(withTitle: "Manual Tests")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            runManualTests()
        default:
            print("Cancelled")
        }
    }
    
    /// Run the manual tests
    private static func runManualTests() {
        print("Manual tests are not available.")
    }
} 