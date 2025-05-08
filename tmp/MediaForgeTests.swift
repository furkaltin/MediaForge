import XCTest
@testable import MediaForge

class MediaForgeTests: XCTestCase {
    
    func testDiskInitialization() {
        // Test the updated Disk initializer with the devicePath parameter
        let disk = Disk(
            id: "test-disk-id",
            name: "Test Disk",
            path: "/Volumes/TestDisk",
            devicePath: "/dev/disk2s1",
            icon: "externaldrive",
            totalSpace: 1000000000,
            freeSpace: 500000000,
            isRemovable: true
        )
        
        // Verify disk properties
        XCTAssertEqual(disk.id, "test-disk-id")
        XCTAssertEqual(disk.name, "Test Disk")
        XCTAssertEqual(disk.path, "/Volumes/TestDisk")
        XCTAssertEqual(disk.devicePath, "/dev/disk2s1")
        XCTAssertEqual(disk.totalSpace, 1000000000)
        XCTAssertEqual(disk.usedSpace, 500000000)
        XCTAssertEqual(disk.freeSpace, 500000000)
    }
    
    func testFileTransferProgress() {
        // Create expectation for async test
        let expectation = XCTestExpectation(description: "File transfer progress")
        
        // Create temporary test directories
        let tempDir = FileManager.default.temporaryDirectory
        let sourceDir = tempDir.appendingPathComponent("source", isDirectory: true)
        let destDir = tempDir.appendingPathComponent("destination", isDirectory: true)
        
        // Create source directory and test file
        try? FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        let testFile = sourceDir.appendingPathComponent("test.jpg")
        let testData = Data(repeating: 0, count: 1024) // 1KB test file
        try? testData.write(to: testFile)
        
        // Copy file with progress monitoring
        var progressUpdates = 0
        
        let progress = FileTransferManager.copyFile(
            from: testFile.path,
            to: destDir.appendingPathComponent("test.jpg").path,
            progressHandler: { current, total, filename in
                progressUpdates += 1
                print("Progress: \(current)/\(total) bytes for \(filename)")
            },
            completionHandler: { result in
                switch result {
                case .success:
                    XCTAssertTrue(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("test.jpg").path))
                    XCTAssertGreaterThan(progressUpdates, 0)
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("File transfer failed: \(error.localizedDescription)")
                }
            }
        )
        
        // Wait for expectation
        wait(for: [expectation], timeout: 5.0)
        
        // Clean up
        try? FileManager.default.removeItem(at: sourceDir)
        try? FileManager.default.removeItem(at: destDir)
    }
    
    func testDiskManagerCreatesValidDisks() {
        // This test verifies that the DiskManager.createDiskFromIODevice method works
        // by checking if we can get at least one valid disk from the system
        
        let disks = DiskManager.getAvailableDisks()
        
        // We should have at least one disk (the system disk)
        XCTAssertFalse(disks.isEmpty, "Should find at least one disk")
        
        // Check that each disk has valid properties
        for disk in disks {
            XCTAssertFalse(disk.name.isEmpty, "Disk should have a name")
            XCTAssertFalse(disk.path.isEmpty, "Disk should have a path")
            XCTAssertFalse(disk.devicePath.isEmpty, "Disk should have a device path")
            XCTAssertGreaterThan(disk.totalSpace, 0, "Disk should have positive total space")
        }
    }
} 