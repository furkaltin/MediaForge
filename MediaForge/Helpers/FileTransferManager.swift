import Foundation
import CryptoKit
import UniformTypeIdentifiers
import AppKit

/// Manages file transfer operations
class FileTransferManager {
    
    /// Error types that can occur during transfer
    enum TransferError: Error, LocalizedError {
        case fileNotFound
        case destinationNotWritable
        case copyFailed(Error)
        case checksumMismatch
        case cancelled
        case sourcePathInvalid
        case destinationPathInvalid
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "File not found"
            case .destinationNotWritable:
                return "Destination is not writable"
            case .copyFailed(let error):
                return "Copy failed: \(error.localizedDescription)"
            case .checksumMismatch:
                return "Checksum verification failed"
            case .cancelled:
                return "Transfer was cancelled"
            case .sourcePathInvalid:
                return "Source path is invalid"
            case .destinationPathInvalid:
                return "Destination path is invalid"
            case .permissionDenied:
                return "Permission denied for file access"
            }
        }
        
        var failureReason: String? {
            switch self {
            case .fileNotFound:
                return "The file could not be found at the specified location. Please verify the path."
            case .destinationNotWritable:
                return "The destination location cannot be written to. Please check permissions or disk space."
            case .copyFailed(let error):
                return "The copy operation failed: \(error.localizedDescription)"
            case .checksumMismatch:
                return "The file verification failed. The source and destination files do not match."
            case .cancelled:
                return "The transfer was cancelled by the user."
            case .sourcePathInvalid:
                return "The source path is invalid or inaccessible. Check if the path exists."
            case .destinationPathInvalid:
                return "The destination path is invalid. Check if the path exists and is accessible."
            case .permissionDenied:
                return "File system permission denied. Make sure the app has the necessary permissions to access the files."
            }
        }
    }
    
    /// Dictionary to store security-scoped bookmarks for persistent access
    private static var securityScopedBookmarks: [String: Data] = [:]
    
    /// Initialize important file access configurations
    static func initialize() {
        // Load any previously saved bookmarks from user defaults
        loadBookmarks()
    }
    
    /// Create security-scoped bookmark for a path
    static func createBookmarkFor(url: URL) -> Data? {
        // First, verify the path exists before attempting to create a bookmark
        if !FileManager.default.fileExists(atPath: url.path) {
            print("Cannot create bookmark: Path does not exist - \(url.path)")
            return nil
        }
        
        do {
            // Create bookmark with security scope
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            securityScopedBookmarks[url.path] = bookmarkData
            saveBookmarks()
            print("Successfully created bookmark for \(url.path)")
            return bookmarkData
        } catch {
            print("Failed to create bookmark for \(url.path): \(error)")
            return nil
        }
    }
    
    /// Access a path using security-scoped bookmark
    static func accessViaBookmark(path: String) -> Bool {
        // Check for existing bookmark
        if let bookmarkData = securityScopedBookmarks[path] {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if isStale {
                    // Update the bookmark if it's stale
                    if let newBookmark = createBookmarkFor(url: url) {
                        securityScopedBookmarks[path] = newBookmark
                        saveBookmarks()
                    }
                }
                
                // Start accessing the resource
                let success = url.startAccessingSecurityScopedResource()
                return success
            } catch {
                print("Failed to resolve bookmark for \(path): \(error)")
                return false
            }
        }
        
        // No existing bookmark, create one if possible
        let url = URL(fileURLWithPath: path)
        if let _ = createBookmarkFor(url: url) {
            return accessViaBookmark(path: path)
        }
        
        return false
    }
    
    /// Stop accessing a path using security-scoped bookmark
    static func stopAccessingPath(path: String) {
        if let bookmarkData = securityScopedBookmarks[path] {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                url.stopAccessingSecurityScopedResource()
            } catch {
                print("Error stopping resource access for \(path): \(error)")
            }
        }
    }
    
    /// Save bookmarks to user defaults
    private static func saveBookmarks() {
        let encodedBookmarks = securityScopedBookmarks.mapValues { data in
            return data.base64EncodedString()
        }
        UserDefaults.standard.set(encodedBookmarks, forKey: "MediaForgeBookmarks")
    }
    
    /// Load bookmarks from user defaults
    private static func loadBookmarks() {
        if let encoded = UserDefaults.standard.dictionary(forKey: "MediaForgeBookmarks") as? [String: String] {
            securityScopedBookmarks = encoded.compactMapValues { base64String in
                if let data = Data(base64Encoded: base64String) {
                    return data
                }
                return nil
            }
        }
    }
    
    /// Calculate MD5 checksum for a file
    static func calculateMD5(for filePath: String) -> String? {
        do {
            let fileURL = URL(fileURLWithPath: filePath)
            let data = try Data(contentsOf: fileURL)
            
            let digest = Insecure.MD5.hash(data: data)
            return digest.map { String(format: "%02hhx", $0) }.joined()
        } catch {
            print("MD5 calculation error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Validate file path exists and is accessible
    static func validatePath(_ path: String) -> Bool {
        // Early check for path existence
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        
        if !fileManager.fileExists(atPath: path, isDirectory: &isDir) {
            print("Path doesn't exist: \(path)")
            return false
        }
        
        // Try to access via security-scoped bookmark first
        if accessViaBookmark(path: path) {
            // Don't forget to stop accessing when done
            defer { stopAccessingPath(path: path) }
            
            // We successfully accessed it via bookmark
            return true
        }
        
        // Fall back to standard validation
        if isDir.boolValue {
            do {
                // Try to read directory contents
                _ = try fileManager.contentsOfDirectory(atPath: path)
                
                // Try to create a temporary file to check write permissions if it's a directory
                let tempFileName = UUID().uuidString
                let tempFilePath = path + "/" + tempFileName
                
                if fileManager.createFile(atPath: tempFilePath, contents: Data()) {
                    try fileManager.removeItem(atPath: tempFilePath)
                    print("Full read/write access confirmed for: \(path)")
                    
                    // Create a bookmark for this directory for persistent access
                    let url = URL(fileURLWithPath: path)
                    if createBookmarkFor(url: url) != nil {
                        print("Created bookmark for directory: \(path)")
                    }
                    
                    return true
                } else {
                    // We can read but not write
                    print("Read-only access to directory: \(path)")
                    return false
                }
            } catch {
                print("Cannot access directory: \(path), error: \(error.localizedDescription)")
                return false
            }
        } else {
            // For files, check if we can read attributes and contents
            do {
                // Check attributes
                _ = try fileManager.attributesOfItem(atPath: path)
                
                // For files, try to read the first few bytes
                let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
                defer { fileHandle.closeFile() }
                _ = fileHandle.readData(ofLength: 1)
                
                // Create a bookmark for this file for persistent access
                let url = URL(fileURLWithPath: path)
                if createBookmarkFor(url: url) != nil {
                    print("Created bookmark for file: \(path)")
                }
                
                print("File access permissions confirmed for: \(path)")
                return true
            } catch {
                print("Cannot access file: \(path), error: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    /// Request user permission for a specific path
    static func requestPermissionFor(path: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let openPanel = NSOpenPanel()
            openPanel.message = "Please select the folder or drive to grant access to MediaForge:"
            openPanel.prompt = "Grant Access"
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = false
            openPanel.allowsMultipleSelection = false
            
            // Try to set the initial directory
            if FileManager.default.fileExists(atPath: path) {
                openPanel.directoryURL = URL(fileURLWithPath: path)
            }
            
            if openPanel.runModal() == .OK, let url = openPanel.url {
                // Create a security-scoped bookmark
                if let _ = createBookmarkFor(url: url) {
                    completion(true)
                    return
                }
            }
            
            completion(false)
        }
    }
    
    /// Copy a file with progress reporting
    static func copyFile(
        from sourcePath: String, 
        to destinationPath: String, 
        progressHandler: @escaping (Int64, Int64, String) -> Void,
        completionHandler: @escaping (Result<String, TransferError>) -> Void
    ) -> Progress {
        // Create a Progress object to track and potentially cancel the operation
        let progress = Progress(totalUnitCount: 1)
        
        // Validate paths
        if !validatePath(sourcePath) {
            completionHandler(.failure(.sourcePathInvalid))
            return progress
        }
        
        // Print debug info
        print("Attempting to copy: \(sourcePath) to \(destinationPath)")
        
        // Ensure source exists
        guard FileManager.default.fileExists(atPath: sourcePath) else {
            print("Source file not found: \(sourcePath)")
            completionHandler(.failure(.fileNotFound))
            return progress
        }
        
        // Get source file size
        let fileSize = DiskManager.getSize(of: sourcePath)
        
        // Create destination directory if needed
        let destinationURL = URL(fileURLWithPath: destinationPath)
        let destinationDir = destinationURL.deletingLastPathComponent().path
        
        do {
            try FileManager.default.createDirectory(atPath: destinationDir, withIntermediateDirectories: true)
        } catch {
            print("Failed to create destination directory: \(error.localizedDescription)")
            completionHandler(.failure(.copyFailed(error)))
            return progress
        }
        
        // Get source file name for progress updates
        let sourceFileName = URL(fileURLWithPath: sourcePath).lastPathComponent
        progressHandler(0, fileSize, sourceFileName)
        
        // Start file copy in background
        DispatchQueue.global(qos: .userInitiated).async {
            let sourceURL = URL(fileURLWithPath: sourcePath)
            
            do {
                // Try simple copy method first
                do {
                    let sourceData = try Data(contentsOf: sourceURL)
                    try sourceData.write(to: destinationURL)
                    
                    // Verify size
                    let destinationSize = DiskManager.getSize(of: destinationPath)
                    if destinationSize != fileSize {
                        print("Size mismatch after copy: source=\(fileSize), dest=\(destinationSize)")
                        completionHandler(.failure(.checksumMismatch))
                        return
                    }
                    
                    progressHandler(fileSize, fileSize, sourceFileName)
                    completionHandler(.success("File copied successfully"))
                    return
                } catch {
                    print("Simple copy failed, trying stream method: \(error.localizedDescription)")
                    // Continue to the streaming method below
                }
                
                // Calculate source checksum
                guard let sourceChecksum = calculateMD5(for: sourcePath) else {
                    print("Could not calculate source checksum for: \(sourcePath)")
                    completionHandler(.failure(.fileNotFound))
                    return
                }
                
                // Open file handles
                guard let inputStream = InputStream(url: sourceURL) else {
                    print("Could not open input stream from: \(sourcePath)")
                    completionHandler(.failure(.fileNotFound))
                    return
                }
                
                guard let outputStream = OutputStream(url: destinationURL, append: false) else {
                    print("Could not open output stream to: \(destinationPath)")
                    completionHandler(.failure(.destinationNotWritable))
                    return
                }
                
                inputStream.open()
                outputStream.open()
                
                defer {
                    inputStream.close()
                    outputStream.close()
                }
                
                let bufferSize = 1024 * 1024 // 1MB buffer
                var buffer = [UInt8](repeating: 0, count: bufferSize)
                var totalBytesRead: Int64 = 0
                
                // Copy the file in chunks
                while inputStream.hasBytesAvailable {
                    // Check if operation was cancelled
                    if progress.isCancelled {
                        // Remove partial file
                        try? FileManager.default.removeItem(at: destinationURL)
                        completionHandler(.failure(.cancelled))
                        return
                    }
                    
                    let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
                    if bytesRead > 0 {
                        let bytesWritten = outputStream.write(buffer, maxLength: bytesRead)
                        if bytesWritten != bytesRead {
                            // Error occurred
                            print("Failed to write all bytes: \(bytesWritten) vs \(bytesRead)")
                            completionHandler(.failure(.copyFailed(NSError(domain: "FileTransferError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to write all bytes"]))))
                            return
                        }
                        
                        totalBytesRead += Int64(bytesRead)
                        progressHandler(totalBytesRead, fileSize, sourceFileName)
                        
                        // Update progress
                        progress.completedUnitCount = Int64(Double(totalBytesRead) / Double(fileSize) * 100)
                    } else if bytesRead < 0 {
                        // Error occurred
                        if let error = inputStream.streamError {
                            print("Stream read error: \(error.localizedDescription)")
                            completionHandler(.failure(.copyFailed(error)))
                        } else {
                            print("Unknown read error")
                            completionHandler(.failure(.copyFailed(NSError(domain: "FileTransferError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown read error"]))))
                        }
                        return
                    } else {
                        // EOF
                        break
                    }
                }
                
                // Verify the copy with checksum
                guard let destinationChecksum = calculateMD5(for: destinationPath) else {
                    print("Could not calculate destination checksum")
                    completionHandler(.failure(.fileNotFound))
                    return
                }
                
                if sourceChecksum == destinationChecksum {
                    print("Checksum verification successful")
                    completionHandler(.success(destinationChecksum))
                } else {
                    // Checksums don't match
                    print("Checksum mismatch: source=\(sourceChecksum), dest=\(destinationChecksum)")
                    try? FileManager.default.removeItem(at: destinationURL)
                    completionHandler(.failure(.checksumMismatch))
                }
            } catch {
                print("File copy error: \(error.localizedDescription)")
                completionHandler(.failure(.copyFailed(error)))
            }
        }
        
        return progress
    }
    
    /// Copy a directory with all its contents
    static func copyDirectory(
        from sourcePath: String,
        to destinationPath: String,
        progressHandler: @escaping (Int64, Int64, String) -> Void,
        completionHandler: @escaping (Result<Bool, TransferError>) -> Void
    ) -> Progress {
        let progress = Progress(totalUnitCount: 1)
        
        print("Attempting to copy image files from: \(sourcePath) to \(destinationPath)")
        
        // Validate source path
        if !validatePath(sourcePath) {
            print("Source path is invalid: \(sourcePath)")
            completionHandler(.failure(.sourcePathInvalid))
            return progress
        }
        
        // Get all files and total size
        var filesToCopy: [String] = []
        var totalSize: Int64 = 0
        var copiedSize: Int64 = 0
        var skippedItems: [String] = [] // Track skipped items
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Create recursive function to find all files
            func addFiles(in directory: String) -> Bool {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: directory)
                    for item in contents {
                        // Skip system directories and hidden files that cause permission issues
                        if item.hasPrefix(".") || item == "Trashes" || item == ".Trashes" {
                            print("Skipping system file/directory: \(item)")
                            skippedItems.append("\(directory)/\(item)")
                            continue
                        }
                        
                        // Skip known camera system/metadata files
                        let skipFiles = ["SONYCARD.IND", "DATABASE.BIN", "MEDIAPRO.XML", "AVIN0001.INP", "AVIN0001.BNP", "AVIN0001.INT"]
                        if skipFiles.contains(item) {
                            print("Skipping camera system file: \(item)")
                            skippedItems.append("\(directory)/\(item)")
                            continue
                        }
                        
                        let itemPath = directory + "/" + item
                        var isDir: ObjCBool = false
                        
                        if FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDir) {
                            if isDir.boolValue {
                                // No longer using try/throw here
                                if !addFiles(in: itemPath) {
                                    // Log the error but continue with other directories
                                    print("Skipping directory that couldn't be accessed: \(itemPath)")
                                    skippedItems.append(itemPath)
                                }
                            } else {
                                // Only include image files by checking extension
                                let fileExtension = (itemPath as NSString).pathExtension.lowercased()
                                let imageExtensions = ["jpg", "jpeg", "arw", "cr2", "cr3", "nef", "raw", "dng", "raf", "heic", "png", "tif", "tiff"]
                                
                                if imageExtensions.contains(fileExtension) {
                                    filesToCopy.append(itemPath)
                                    let itemSize = DiskManager.getSize(of: itemPath)
                                    totalSize += itemSize
                                    print("Adding image file to copy list: \(itemPath) (\(itemSize) bytes)")
                                } else {
                                    print("Skipping non-image file: \(itemPath)")
                                    skippedItems.append(itemPath)
                                }
                            }
                        }
                    }
                    return true
                } catch {
                    print("Error scanning directory \(directory): \(error.localizedDescription)")
                    // Don't throw here, just report the error and return false
                    if directory != sourcePath {
                        print("Skipping inaccessible directory: \(directory)")
                        skippedItems.append(directory)
                        return false
                    } else {
                        // If the source directory itself can't be accessed, propagate the error
                        completionHandler(.failure(.copyFailed(error)))
                        return false
                    }
                }
            }
            
            // Now call our recursive function
            let scanSuccess = addFiles(in: sourcePath)
            if !scanSuccess && filesToCopy.isEmpty {
                // If scanning failed and we didn't find any files, exit
                return
            }
            
            if filesToCopy.isEmpty {
                if skippedItems.isEmpty {
                    print("No image files found to copy in \(sourcePath)")
                    completionHandler(.failure(.fileNotFound))
                } else {
                    print("No image files found to copy. \(skippedItems.count) items were skipped due to filtering or permissions.")
                    let error = NSError(domain: "FileTransferError", 
                                       code: -1, 
                                       userInfo: [NSLocalizedDescriptionKey: "No image files found. Non-image files were skipped."])
                    completionHandler(.failure(.copyFailed(error)))
                }
                return
            }
            
            print("Found \(filesToCopy.count) image files to copy, total size: \(totalSize) bytes")
            if !skippedItems.isEmpty {
                print("\(skippedItems.count) items were skipped (non-image files or permission restrictions)")
            }
            
            // Report initial progress
            progressHandler(0, totalSize, "Preparing to copy \(filesToCopy.count) image files")
            
            // Create destination directory if needed
            do {
                try FileManager.default.createDirectory(atPath: destinationPath, withIntermediateDirectories: true)
            } catch {
                print("Failed to create destination directory: \(error.localizedDescription)")
                completionHandler(.failure(.destinationPathInvalid))
                return
            }
            
            // Variable to track if any file was successfully copied
            var anyFilesCopied = false
            var failedFiles: [String] = []
            
            // Copy each file
            var completedFiles = 0
            var activeTransfers = 0
            let maxConcurrentTransfers = 3 // Limit concurrent transfers to avoid overwhelming system
            
            // Create a dispatch group to track when all files are done
            let transferGroup = DispatchGroup()
            
            for filePath in filesToCopy {
                // Check if operation was cancelled
                if progress.isCancelled {
                    print("Transfer cancelled by user")
                    completionHandler(.failure(.cancelled))
                    return
                }
                
                // Determine relative path
                let relativePath = filePath.replacingOccurrences(of: sourcePath, with: "")
                let destinationFilePath = destinationPath + relativePath
                
                // Create subdirectory if needed
                let destinationFileDir = URL(fileURLWithPath: destinationFilePath).deletingLastPathComponent().path
                
                do {
                    try FileManager.default.createDirectory(atPath: destinationFileDir, withIntermediateDirectories: true)
                } catch {
                    print("Failed to create subdirectory \(destinationFileDir): \(error.localizedDescription)")
                    failedFiles.append(filePath)
                    continue // Skip this file but continue with others
                }
                
                // Copy the file
                let fileSize = DiskManager.getSize(of: filePath)
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                
                // Create a file-level progress handler
                let fileProgressHandler: (Int64, Int64, String) -> Void = { bytesTransferred, totalBytes, fileName in
                    // Calculate the global progress
                    let adjustedTransferred = copiedSize + bytesTransferred
                    
                    // Create a status message showing progress with file counts
                    let statusMessage = "Copying \(fileName) - \(completedFiles)/\(filesToCopy.count) files"
                    
                    progressHandler(adjustedTransferred, totalSize, statusMessage)
                    
                    // Update the overall progress
                    progress.completedUnitCount = Int64(Double(adjustedTransferred) / Double(totalSize) * 100)
                }
                
                print("Copying file: \(filePath) -> \(destinationFilePath)")
                
                // Enter the dispatch group before starting the file transfer
                transferGroup.enter()
                
                // Limit concurrent transfers
                activeTransfers += 1
                while activeTransfers >= maxConcurrentTransfers {
                    // Wait briefly before checking again
                    Thread.sleep(forTimeInterval: 0.1)
                    // Re-check cancellation during wait
                    if progress.isCancelled {
                        print("Transfer cancelled during throttling")
                        completionHandler(.failure(.cancelled))
                        return
                    }
                }
                
                // Copy the file
                _ = copyFile(
                    from: filePath,
                    to: destinationFilePath,
                    progressHandler: fileProgressHandler,
                    completionHandler: { result in
                        // Update tracking variables atomically
                        DispatchQueue.main.async {
                            activeTransfers -= 1
                            
                            switch result {
                            case .success:
                                // File copied successfully
                                copiedSize += fileSize
                                anyFilesCopied = true
                                completedFiles += 1
                                
                                // Update the status with new file count
                                let statusMessage = "Completed \(completedFiles)/\(filesToCopy.count) files"
                                progressHandler(copiedSize, totalSize, statusMessage)
                                
                                print("Successfully copied (\(completedFiles)/\(filesToCopy.count)): \(filePath)")
                            case .failure(let error):
                                // Handle file copy error
                                print("Failed to copy \(filePath): \(error.localizedDescription)")
                                failedFiles.append(filePath)
                            }
                            
                            // Leave the dispatch group when file is complete
                            transferGroup.leave()
                        }
                    }
                )
            }
            
            // Wait for all transfers to complete
            transferGroup.wait()
            
            // Report success if any files were copied, even if some failed
            if anyFilesCopied {
                if failedFiles.isEmpty && skippedItems.isEmpty {
                    print("All image files copied successfully")
                    completionHandler(.success(true))
                } else {
                    // At least some files were copied, but some failed
                    print("Transfer partially completed. \(failedFiles.count) files failed to copy. \(skippedItems.count) items were skipped.")
                    // Return success but with a note that it was partial
                    completionHandler(.success(true))
                }
            } else {
                // No files were copied at all
                print("Transfer failed: No image files could be copied.")
                let error = NSError(domain: "FileTransferError", 
                                   code: -1, 
                                   userInfo: [NSLocalizedDescriptionKey: "No image files could be copied. Check permissions."])
                completionHandler(.failure(.copyFailed(error)))
            }
        }
        
        return progress
    }
    
    /// Cancel and clean up a transfer operation
    static func cancelTransfer(_ transfer: FileTransfer) {
        // Implementation for cancellation logic
        // This would need to access the Progress object stored in the transfer
        print("Attempting to cancel transfer: \(transfer.source.name) -> \(transfer.destination.name)")
    }
} 