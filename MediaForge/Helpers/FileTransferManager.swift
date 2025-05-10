import Foundation
import CryptoKit
import UniformTypeIdentifiers
import AppKit
import os.lock

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
    private static let bookmarkQueue = DispatchQueue(label: "com.mediaforge.bookmarkQueue") // Serial queue for thread safety
    
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
            
            // Thread-safe dictionary update with serial queue
            bookmarkQueue.async {
                securityScopedBookmarks[url.path] = bookmarkData
                saveBookmarks()
            }
            
            print("Successfully created bookmark for \(url.path)")
            return bookmarkData
        } catch {
            print("Failed to create bookmark for \(url.path): \(error)")
            return nil
        }
    }
    
    /// Access a path using security-scoped bookmark
    static func accessViaBookmark(path: String) -> Bool {
        // Thread-safe dictionary read with serial queue
        var bookmarkData: Data?
        
        // Safely read from dictionary
        bookmarkQueue.sync {
            bookmarkData = securityScopedBookmarks[path]
        }
        
        // Check for existing bookmark
        if let bookmarkData = bookmarkData {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if isStale {
                    // Update the bookmark if it's stale
                    if let newBookmark = createBookmarkFor(url: url) {
                        bookmarkQueue.async {
                            securityScopedBookmarks[path] = newBookmark
                            saveBookmarks()
                        }
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
        var bookmarkData: Data?
        
        // Safely read from dictionary
        bookmarkQueue.sync {
            bookmarkData = securityScopedBookmarks[path]
        }
        
        if let bookmarkData = bookmarkData {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                url.stopAccessingSecurityScopedResource()
            } catch {
                print("Error stopping resource access for \(path): \(error)")
            }
        }
    }
    
    /// Save bookmarks to user defaults - Simple thread-safe version
    private static func saveBookmarks() {
        // Çalıştığımız thread zaten serial queue olduğu için
        // thread safety için ekstra bir şey yapmamız gerekmiyor
        var bookmarksCopy: [String: String] = [:]
        
        // Dictionary'yi Base64 stringlere dönüştür
        for (key, data) in securityScopedBookmarks {
            bookmarksCopy[key] = data.base64EncodedString()
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(bookmarksCopy, forKey: "MediaForgeBookmarks")
    }
    
    /// Load bookmarks from user defaults - Thread-safe version
    private static func loadBookmarks() {
        if let encoded = UserDefaults.standard.dictionary(forKey: "MediaForgeBookmarks") as? [String: String] {
            var loadedBookmarks: [String: Data] = [:]
            
            // Base64 string'leri Data'ya dönüştür
            for (key, base64String) in encoded {
                if let data = Data(base64Encoded: base64String) {
                    loadedBookmarks[key] = data
                }
            }
            
            // Thread-safe dictionary update - serial queue
            bookmarkQueue.async {
                securityScopedBookmarks = loadedBookmarks
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
    
    /// Calculate SHA1 checksum for a file
    static func calculateSHA1(for filePath: String) -> String? {
        do {
            let fileURL = URL(fileURLWithPath: filePath)
            let data = try Data(contentsOf: fileURL)
            
            let digest = Insecure.SHA1.hash(data: data)
            return digest.map { String(format: "%02hhx", $0) }.joined()
        } catch {
            print("SHA1 calculation error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Calculate xxHash64 checksum for a file
    static func calculateXXHash64(for filePath: String) -> String? {
        do {
            let fileURL = URL(fileURLWithPath: filePath)
            let data = try Data(contentsOf: fileURL)
            
            // Use our XXHasher implementation
            var hasher = XXHasher(seed: 0)
            hasher.update(data: data)
            let hash = hasher.finalize()
            
            return String(format: "%016llx", hash)
        } catch {
            print("xxHash64 calculation error: \(error.localizedDescription)")
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
        
        // Debug information for troubleshooting
        print("=== TRANSFER ATTEMPT ===")
        print("Copying from: \(sourcePath)")
        print("Copying to: \(destinationPath)")
        
        // Explicitly access source using security-scoped bookmark if available
        var didStartSourceAccess = false
        if accessViaBookmark(path: sourcePath) {
            didStartSourceAccess = true
            print("Successfully accessed source path via bookmark")
        }
        
        // Create destination directories up front
        let destinationURL = URL(fileURLWithPath: destinationPath)
        let destinationDir = destinationURL.deletingLastPathComponent().path
        
        do {
            try FileManager.default.createDirectory(atPath: destinationDir, withIntermediateDirectories: true)
            print("Created destination directory: \(destinationDir)")
        } catch {
            print("Failed to create destination directory: \(error.localizedDescription)")
            if didStartSourceAccess {
                stopAccessingPath(path: sourcePath)
            }
            completionHandler(.failure(.destinationNotWritable))
            return progress
        }
        
        // Ensure source exists
        guard FileManager.default.fileExists(atPath: sourcePath) else {
            print("Source file not found: \(sourcePath)")
            if didStartSourceAccess {
                stopAccessingPath(path: sourcePath)
            }
            completionHandler(.failure(.fileNotFound))
            return progress
        }
        
        // Get source file size
        var fileSize: Int64 = 0
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: sourcePath)
            if let size = attributes[.size] as? Int64 {
                fileSize = size
            } else {
                fileSize = DiskManager.getSize(of: sourcePath)
            }
            print("Source file size: \(fileSize) bytes")
        } catch {
            print("Error getting source file size: \(error.localizedDescription)")
            fileSize = DiskManager.getSize(of: sourcePath)
        }
        
        // Get source file name for progress updates
        let sourceFileName = URL(fileURLWithPath: sourcePath).lastPathComponent
        progressHandler(0, fileSize, sourceFileName)
        
        // Start file copy in background
        DispatchQueue.global(qos: .userInitiated).async {
            let sourceURL = URL(fileURLWithPath: sourcePath)
            
            // Make sure we release the security-scoped resource when done
            defer {
                if didStartSourceAccess {
                    stopAccessingPath(path: sourcePath)
                    print("Stopped accessing source path via bookmark")
                }
            }
            
            do {
                // Büyük dosyalar için optimize edilmiş kopyalama yöntemi
                if fileSize > 100_000_000 { // 100MB üzeri için
                    // Direkt FileManager.copyItem kullan - daha optimize ve hızlı
                    print("Using fast copy for large file (\(fileSize) bytes)")
                    
                    // Büyük dosyalarda ara ilerleme güncellemeleri için timer kullan
                    // Bu şekilde progress bar daha düzgün ilerleyecek
                    let updateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                        let destSize = DiskManager.getSize(of: destinationPath)
                        if destSize > 0 {
                            // Dosyanın ne kadarının kopyalandığını kontrol et
                            DispatchQueue.main.async {
                                // Kopyalanmış boyut transferi boyutunu geçmesin
                                let reportedSize = min(destSize, fileSize)
                                progressHandler(reportedSize, fileSize, sourceFileName)
                                progress.completedUnitCount = Int64(Double(reportedSize) / Double(fileSize) * 100)
                            }
                        }
                    }
                    
                    do {
                        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                        // Timer'ı durdur
                        updateTimer.invalidate()
                        
                        // Dosya boyutunu doğrulayın
                        let destSize = DiskManager.getSize(of: destinationPath)
                        if destSize != fileSize {
                            print("Size mismatch after copy: source=\(fileSize), dest=\(destSize)")
                            try? FileManager.default.removeItem(at: destinationURL)
                            throw TransferError.checksumMismatch
                        }
                        
                        // İşlem tamamlandı, progress bildirimi
                        DispatchQueue.main.async {
                            progressHandler(fileSize, fileSize, sourceFileName)
                        }
                        completionHandler(.success("File copied successfully"))
                    } catch {
                        // Timer'ı durdur
                        updateTimer.invalidate()
                        throw error
                    }
                    
                    return
                }
                
                // ---- Normal boyuttaki dosyalar için sonraki kopyalama metodları: ----
                
                // First, try using FileManager.copyItem which is the most reliable method
                print("Attempting copy using FileManager.copyItem")
                do {
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                    print("FileManager.copyItem succeeded")
                    
                    // Verify existence and size
                    if FileManager.default.fileExists(atPath: destinationPath) {
                        let destinationSize = DiskManager.getSize(of: destinationPath)
                        if destinationSize != fileSize {
                            print("Size mismatch after copy: source=\(fileSize), dest=\(destinationSize)")
                            try? FileManager.default.removeItem(at: destinationURL)
                            throw TransferError.checksumMismatch
                        }
                        
                        // Successful copy
                        DispatchQueue.main.async {
                            progressHandler(fileSize, fileSize, sourceFileName)
                        }
                        completionHandler(.success("File copied successfully"))
                        return
                    } else {
                        print("Destination file doesn't exist after copy")
                        throw TransferError.copyFailed(NSError(domain: "MediaForge", code: 1, userInfo: [NSLocalizedDescriptionKey: "Destination file not found after copy"]))
                    }
                } catch {
                    print("FileManager.copyItem failed: \(error.localizedDescription), trying Data method")
                    // Continue to the next method if this fails
                }
                
                // If first method failed, try simple Data method
                print("Attempting copy using Data read/write")
                do {
                    let sourceData = try Data(contentsOf: sourceURL, options: .mappedIfSafe)
                    try sourceData.write(to: destinationURL)
                    print("Data read/write succeeded")
                    
                    // Verify size
                    let destinationSize = DiskManager.getSize(of: destinationPath)
                    if destinationSize != fileSize {
                        print("Size mismatch after copy: source=\(fileSize), dest=\(destinationSize)")
                        try? FileManager.default.removeItem(at: destinationURL)
                        throw TransferError.checksumMismatch
                    }
                    
                    DispatchQueue.main.async {
                        progressHandler(fileSize, fileSize, sourceFileName)
                    }
                    completionHandler(.success("File copied successfully"))
                    return
                } catch {
                    print("Data read/write failed: \(error.localizedDescription), trying stream method")
                    // Continue to the stream method below
                }
                
                // Calculate source checksum before streaming copy
                print("Calculating source checksum")
                guard let sourceChecksum = calculateMD5(for: sourcePath) else {
                    print("Could not calculate source checksum for: \(sourcePath)")
                    throw TransferError.fileNotFound
                }
                print("Source checksum: \(sourceChecksum)")
                
                // Last resort: stream method with buffer
                print("Attempting copy using stream method")
                // Open file handles
                guard let inputStream = InputStream(url: sourceURL) else {
                    print("Could not open input stream from: \(sourcePath)")
                    throw TransferError.sourcePathInvalid
                }
                
                guard let outputStream = OutputStream(url: destinationURL, append: false) else {
                    print("Could not open output stream to: \(destinationPath)")
                    throw TransferError.destinationPathInvalid
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
                        throw TransferError.cancelled
                    }
                    
                    let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
                    if bytesRead > 0 {
                        let bytesWritten = outputStream.write(buffer, maxLength: bytesRead)
                        if bytesWritten != bytesRead {
                            // Error occurred
                            print("Failed to write all bytes: \(bytesWritten) vs \(bytesRead)")
                            throw TransferError.copyFailed(NSError(domain: "FileTransferError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to write all bytes"]))
                        }
                        
                        totalBytesRead += Int64(bytesRead)
                        
                        // UI güncellemelerini main thread'de yap
                        // Daha sık güncellemeler için condition ekleyelim
                        // Her 128KB'da bir güncelleme yapalım veya 100ms geçtiyse
                        var lastUpdateTime = Date()
                        let shouldUpdate = (totalBytesRead % (128 * 1024) == 0) || 
                                           (Date().timeIntervalSince(lastUpdateTime) > 0.1)
                        
                        if shouldUpdate {
                            lastUpdateTime = Date()
                            DispatchQueue.main.async {
                                progressHandler(totalBytesRead, fileSize, sourceFileName)
                                
                                // Update progress
                                progress.completedUnitCount = Int64(Double(totalBytesRead) / Double(fileSize) * 100)
                            }
                        }
                    } else if bytesRead < 0 {
                        // Error occurred
                        if let error = inputStream.streamError {
                            print("Stream read error: \(error.localizedDescription)")
                            throw TransferError.copyFailed(error)
                        } else {
                            print("Unknown read error")
                            throw TransferError.copyFailed(NSError(domain: "FileTransferError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown read error"]))
                        }
                    } else {
                        // EOF
                        break
                    }
                }
                
                // Verify the copy with checksum
                print("Calculating destination checksum")
                guard let destinationChecksum = calculateMD5(for: destinationPath) else {
                    print("Could not calculate destination checksum")
                    throw TransferError.fileNotFound
                }
                print("Destination checksum: \(destinationChecksum)")
                
                if sourceChecksum == destinationChecksum {
                    print("Checksum verification successful")
                    completionHandler(.success(destinationChecksum))
                } else {
                    // Checksums don't match
                    print("Checksum mismatch: source=\(sourceChecksum), dest=\(destinationChecksum)")
                    try? FileManager.default.removeItem(at: destinationURL)
                    throw TransferError.checksumMismatch
                }
            } catch let error as TransferError {
                print("Transfer error: \(error.localizedDescription)")
                completionHandler(.failure(error))
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
        
        print("=== DIRECTORY TRANSFER STARTED ===")
        print("Source path: \(sourcePath)")
        print("Destination path: \(destinationPath)")
        
        // Validate source path with explicit access
        var sourceAccessStarted = false
        if accessViaBookmark(path: sourcePath) {
            sourceAccessStarted = true
            print("Successfully accessed source directory via bookmark")
        }
        
        // Initial validation
        if !FileManager.default.fileExists(atPath: sourcePath) {
            print("Source directory does not exist: \(sourcePath)")
            if sourceAccessStarted {
                stopAccessingPath(path: sourcePath)
            }
            completionHandler(.failure(.sourcePathInvalid))
            return progress
        }

        // Create destination directory
        do {
            try FileManager.default.createDirectory(atPath: destinationPath, withIntermediateDirectories: true)
            print("Created destination directory: \(destinationPath)")
        } catch {
            print("Failed to create destination directory: \(error.localizedDescription)")
            if sourceAccessStarted {
                stopAccessingPath(path: sourcePath)
            }
            completionHandler(.failure(.destinationNotWritable))
            return progress
        }
        
        // Get all files and total size
        var filesToCopy: [String] = []
        var totalSize: Int64 = 0
        var copiedSize: Int64 = 0
        var skippedItems: [String] = [] // Track skipped items
        var errorMessages: [String] = [] // Track all errors for better reporting
        
        // Tarama işlemini background thread'de yapıyoruz
        DispatchQueue.global(qos: .userInitiated).async {
            // Make sure we release security-scoped access when done with scanning
            defer {
                if sourceAccessStarted {
                    stopAccessingPath(path: sourcePath)
                    print("Stopped accessing source directory via bookmark")
                }
            }
            
            // Create recursive function to find all files
            func addFiles(in directory: String) -> Bool {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: directory)
                    print("Found \(contents.count) items in \(directory)")
                    
                    if contents.isEmpty {
                        print("Directory is empty: \(directory)")
                    }
                    
                    for item in contents {
                        // Aralarda progress update için yield edelim ki UI donmasın
                        if #available(macOS 10.15, *) {
                            try Task.checkCancellation() // Modern yöntem
                        } else {
                            // İşlemin iptal edilip edilmediğini kontrol edelim
                            if progress.isCancelled {
                                print("Directory scan cancelled by user")
                                return false
                            }
                        }
                        
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
                        
                        // Check file existence with better error handling
                        let fileExists = FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDir)
                        if !fileExists {
                            print("File suddenly disappeared: \(itemPath)")
                            skippedItems.append(itemPath)
                            continue
                        }
                        
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
                                // Check file readability before adding
                                if FileManager.default.isReadableFile(atPath: itemPath) {
                                    filesToCopy.append(itemPath)
                                    
                                    // Get file size safely
                                    let itemSize: Int64
                                    do {
                                        let attributes = try FileManager.default.attributesOfItem(atPath: itemPath)
                                        if let size = attributes[.size] as? Int64 {
                                            itemSize = size
                                        } else {
                                            itemSize = DiskManager.getSize(of: itemPath)
                                        }
                                    } catch {
                                        // Fall back to DiskManager if attributes fail
                                        itemSize = DiskManager.getSize(of: itemPath)
                                    }
                                    
                                    totalSize += itemSize
                                    print("Adding image file to copy list: \(itemPath) (\(itemSize) bytes)")
                                } else {
                                    print("File is not readable: \(itemPath)")
                                    skippedItems.append(itemPath)
                                    errorMessages.append("No read permission for: \(itemPath)")
                                }
                            } else {
                                print("Skipping non-image file: \(itemPath)")
                                skippedItems.append(itemPath)
                            }
                        }
                    }
                    return true
                } catch {
                    print("Error scanning directory \(directory): \(error.localizedDescription)")
                    errorMessages.append("Directory scan error: \(directory) - \(error.localizedDescription)")
                    
                    // Don't throw here, just report the error and return false
                    if directory != sourcePath {
                        print("Skipping inaccessible directory: \(directory)")
                        skippedItems.append(directory)
                        return false
                    } else {
                        // If the source directory itself can't be accessed, propagate the error
                        DispatchQueue.main.async {
                            completionHandler(.failure(.copyFailed(error)))
                        }
                        return false
                    }
                }
            }
            
            // Now call our recursive function
            print("Starting recursive directory scan...")
            let scanSuccess = addFiles(in: sourcePath)
            if !scanSuccess && filesToCopy.isEmpty {
                // If scanning failed and we didn't find any files, exit
                print("Directory scan failed completely")
                return
            }
            
            if filesToCopy.isEmpty {
                if skippedItems.isEmpty {
                    print("No image files found to copy in \(sourcePath)")
                    DispatchQueue.main.async {
                        completionHandler(.failure(.fileNotFound))
                    }
                } else {
                    print("No image files found to copy. \(skippedItems.count) items were skipped due to filtering or permissions.")
                    // Create a more detailed error with comprehensive information
                    let errorInfo: [String: Any] = [
                        NSLocalizedDescriptionKey: "No image files found to copy",
                        NSLocalizedFailureReasonErrorKey: "Found \(skippedItems.count) non-image files or inaccessible files",
                        "skippedItems": skippedItems.prefix(10).joined(separator: ", "),
                        "errorMessages": errorMessages.prefix(5).joined(separator: "; ")
                    ]
                    let error = NSError(domain: "MediaForge.FileTransferManager", 
                                       code: 100, 
                                       userInfo: errorInfo)
                    DispatchQueue.main.async {
                        completionHandler(.failure(.copyFailed(error)))
                    }
                }
                return
            }
            
            print("Found \(filesToCopy.count) image files to copy, total size: \(totalSize) bytes")
            if !skippedItems.isEmpty {
                print("\(skippedItems.count) items were skipped (non-image files or permission restrictions)")
            }
            
            // Report initial progress
            DispatchQueue.main.async {
                progressHandler(0, totalSize, "Preparing to copy \(filesToCopy.count) image files")
            }
            
            // Check for existing files in destination to avoid overwriting without notification
            var existingFiles = 0
            for sourceFilePath in filesToCopy {
                // Get relative path from base source directory
                let relativePath = sourceFilePath.replacingOccurrences(of: sourcePath, with: "")
                let destinationFilePath = destinationPath + relativePath
                
                if FileManager.default.fileExists(atPath: destinationFilePath) {
                    existingFiles += 1
                }
            }
            
            if existingFiles > 0 {
                print("Warning: \(existingFiles) files already exist in the destination and may be overwritten")
            }
            
            // Variable to track if any file was successfully copied
            var anyFilesCopied = false
            var failedFiles: [String] = []
            
            // Copy each file
            var completedFiles = 0
            let operationQueue = OperationQueue()
            operationQueue.maxConcurrentOperationCount = 3 // Aynı anda en fazla 3 dosya kopyalayalım
            
            // Semafor kullanarak dosya kopyalama sayısını sınırlıyoruz ve takip ediyoruz
            let transferCompletionGroup = DispatchGroup()
            
            // Tüm dosyaları eşzamanlı olarak kopyalamak yerine, batch olarak işleyelim
            let batchSize = 10
            var fileIndex = 0
            
            // Bu fonksiyon, kuyruktaki bir sonraki batch dosyayı işlemek için kullanılır
            func processNextBatch() {
                // Eğer tüm dosyalar kuyruğa eklendiyse, işlem bitti
                if fileIndex >= filesToCopy.count {
                    return
                }
                
                // Bu batch'deki maks dosya sayısını hesapla
                let endIndex = min(fileIndex + batchSize, filesToCopy.count)
                
                // Bu batch'deki dosyaları kuyruğa ekle
                for i in fileIndex..<endIndex {
                    let filePath = filesToCopy[i]
                    
                    // Check if operation was cancelled
                    if progress.isCancelled {
                        print("Transfer cancelled by user")
                        DispatchQueue.main.async {
                            completionHandler(.failure(.cancelled))
                        }
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
                        errorMessages.append("Failed to create directory: \(destinationFileDir)")
                        failedFiles.append(filePath)
                        continue // Skip this file but continue with others
                    }
                    
                    // Copy the file
                    let fileSize: Int64
                    do {
                        let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
                        fileSize = attributes[.size] as? Int64 ?? DiskManager.getSize(of: filePath)
                    } catch {
                        fileSize = DiskManager.getSize(of: filePath)
                    }
                    
                    let _ = URL(fileURLWithPath: filePath).lastPathComponent
                    
                    // Create a file-level progress handler
                    let fileProgressHandler: (Int64, Int64, String) -> Void = { bytesTransferred, totalBytes, _ in
                        // Calculation of progress has to be thread-safe
                        let adjustedTransferred = copiedSize + bytesTransferred
                        
                        // Create a status message showing progress with file counts
                        // Dosya transferi başlar başlamaz sayacı güncelle, artık +1 kullanmıyoruz
                        // Bu şekilde sayaç daha düzgün artacak
                        let currentFileIndex = fileIndex + (i - fileIndex)
                        let statusMessage = "Copying \(relativePath) - \(currentFileIndex)/\(filesToCopy.count) files"
                        
                        // UI updates must be on main thread
                        DispatchQueue.main.async {
                            progressHandler(adjustedTransferred, totalSize, statusMessage)
                            
                            // Update the overall progress
                            progress.completedUnitCount = Int64(Double(adjustedTransferred) / Double(totalSize) * 100)
                        }
                    }
                    
                    print("Copying file (\(completedFiles + 1)/\(filesToCopy.count)): \(filePath) -> \(destinationFilePath)")
                    
                    // Enter the dispatch group before starting the file transfer
                    transferCompletionGroup.enter()
                    
                    // Create an operation for this file copy
                    let copyOperation = BlockOperation {
                        _ = copyFile(
                            from: filePath,
                            to: destinationFilePath,
                            progressHandler: fileProgressHandler,
                            completionHandler: { result in
                                defer {
                                    // Leave the dispatch group when file is complete
                                    transferCompletionGroup.leave()
                                }
                                
                                switch result {
                                case .success:
                                    // Thread safety için senkronize edelim
                                    objc_sync_enter(self)
                                    copiedSize += fileSize
                                    anyFilesCopied = true
                                    completedFiles += 1
                                    objc_sync_exit(self)
                                    
                                    // Update the status with new file count (on main thread)
                                    DispatchQueue.main.async {
                                        let statusMessage = "Completed \(completedFiles)/\(filesToCopy.count) files"
                                        progressHandler(copiedSize, totalSize, statusMessage)
                                    }
                                    
                                    print("Successfully copied (\(completedFiles)/\(filesToCopy.count)): \(filePath)")
                                case .failure(let error):
                                    // Handle file copy error
                                    print("Failed to copy \(filePath): \(error.localizedDescription)")
                                    
                                    objc_sync_enter(self)
                                    failedFiles.append(filePath)
                                    errorMessages.append("Copy failed: \(filePath) - \(error.localizedDescription)")
                                    objc_sync_exit(self)
                                }
                            }
                        )
                    }
                    
                    // Kopyalama işlemini kuyruğa ekle
                    operationQueue.addOperation(copyOperation)
                }
                
                // İndeksi güncelle
                fileIndex = endIndex
                
                // İşlemlerin tamamlanmasını bekliyoruz, tamamlandığında bir sonraki batch'i işliyoruz
                transferCompletionGroup.notify(queue: .global(qos: .userInitiated)) {
                    // Bu batch bitti, bir sonrakini işle
                    processNextBatch()
                    
                    // Eğer son batch işlendiyse ve tüm dosyalar tamamlandıysa, sonucu bildir
                    if fileIndex >= filesToCopy.count && operationQueue.operationCount == 0 {
                        // Tüm batch'ler tamamlandı, sonucu raporla
                        finishTransfer()
                    }
                }
            }
            
            // Transfer sonuçlandığında çağrılacak fonksiyon
            func finishTransfer() {
                // Report success if any files were copied, even if some failed
                if anyFilesCopied {
                    if failedFiles.isEmpty && skippedItems.isEmpty {
                        print("All image files copied successfully")
                        DispatchQueue.main.async {
                            completionHandler(.success(true))
                        }
                    } else {
                        // At least some files were copied, but some failed
                        print("Transfer partially completed. \(failedFiles.count) files failed to copy. \(skippedItems.count) items were skipped.")
                        
                        // If we have a specific error message we can pass, do so
                        if !errorMessages.isEmpty {
                            let errorSummary = errorMessages.prefix(3).joined(separator: "; ")
                            let _ = NSError(
                                domain: "MediaForge.FileTransferManager",
                                code: 101,
                                userInfo: [
                                    NSLocalizedDescriptionKey: "Transfer partially completed",
                                    NSLocalizedFailureReasonErrorKey: "\(failedFiles.count) files failed to copy. \(errorSummary)",
                                    "failedCount": failedFiles.count,
                                    "skippedCount": skippedItems.count,
                                    "completedCount": completedFiles
                                ]
                            )
                            // We still return success since some files were copied, but include error details
                            print("Partial success with errors: \(errorSummary)")
                        }
                        
                        // Return success but with a note that it was partial
                        DispatchQueue.main.async {
                            completionHandler(.success(true))
                        }
                    }
                } else {
                    // No files were copied at all
                    print("Transfer failed: No image files could be copied.")
                    let errorDetail = errorMessages.prefix(5).joined(separator: "; ")
                    let error = NSError(domain: "MediaForge.FileTransferManager", 
                                       code: 102, 
                                       userInfo: [
                                        NSLocalizedDescriptionKey: "No image files could be copied",
                                        NSLocalizedFailureReasonErrorKey: "Check permissions and file access. \(errorDetail)",
                                        "errorDetails": errorMessages
                                       ])
                    DispatchQueue.main.async {
                        completionHandler(.failure(.copyFailed(error)))
                    }
                }
            }
            
            // İlk batch'i işlemeye başla
            processNextBatch()
        }
        
        return progress
    }
    
    /// Cancel and clean up a transfer operation
    static func cancelTransfer(_ transfer: FileTransfer) {
        // Implementation for cancellation logic
        // This would need to access the Progress object stored in the transfer
        print("Attempting to cancel transfer: \(transfer.source.name) -> \(transfer.destination.name)")
    }
    
    /// Cascading copy mode - determines how transfers are prioritized
    enum CascadingCopyMode {
        case disabled            // Standard copy - all destinations at once
        case firstRunPriority    // First run to fast destination, then second run
        case secondaryFromFirst  // First run followed immediately by transfers from first destination
        
        var description: String {
            switch self {
            case .disabled:
                return "Disabled (Standard Copy)"
            case .firstRunPriority:
                return "First Run Priority"
            case .secondaryFromFirst:
                return "Complete Transfer from First Destination"
            }
        }
    }
    
    /// Report format types for generating transfer reports
    enum ReportFormat: String, CaseIterable, Identifiable {
        case pdf = "PDF"
        case html = "HTML"
        case csv = "CSV"
        case json = "JSON"
        
        var id: String { self.rawValue }
        
        var fileExtension: String {
            self.rawValue.lowercased()
        }
    }
    
    /// Transfer a file with cascading copy feature
    /// - Parameters:
    ///   - sourcePath: Source file path
    ///   - destinations: Array of destination paths
    ///   - preset: Transfer preset to use
    ///   - progressHandler: Progress update handler
    ///   - completionHandler: Called when transfer is complete
    static func transferWithCascading(
        sourcePath: String,
        destinations: [String],
        preset: TransferPreset,
        progressHandler: @escaping (Double, Int64, Int64, String, String) -> Void,
        completionHandler: @escaping (Result<[String], Error>) -> Void
    ) {
        // Validate source path
        guard FileManager.default.fileExists(atPath: sourcePath) else {
            completionHandler(.failure(TransferError.fileNotFound))
            return
        }
        
        // Must have at least one destination
        guard !destinations.isEmpty else {
            completionHandler(.failure(TransferError.destinationPathInvalid))
            return
        }
        
        // Skip if preset explicitly disables cascading or only one destination
        let cascadingMode: CascadingCopyMode = destinations.count < 2 || !preset.isCascadingEnabled ? .disabled : .secondaryFromFirst
        
        switch cascadingMode {
        case .disabled:
            // Standard copy to all destinations simultaneously
            transferFileToMultipleDestinations(
                sourcePath: sourcePath, 
                destinationPaths: destinations,
                checksumMethod: preset.checksumAlgorithm.rawValue,
                verificationBehavior: preset.verificationBehavior.rawValue,
                progressHandler: progressHandler,
                completionHandler: completionHandler
            )
            
        case .firstRunPriority, .secondaryFromFirst:
            // First, get the primary destination (assumed to be fastest)
            let primaryDestination = destinations.first!
            let secondaryDestinations = Array(destinations.dropFirst())
            
            // First run to primary destination
            transferFile(
                sourcePath: sourcePath,
                destinationPath: primaryDestination,
                checksumMethod: preset.checksumAlgorithm.rawValue,
                verificationBehavior: preset.verificationBehavior.rawValue,
                progressHandler: { bytesTransferred, totalBytes, fileName, status in
                    // Report progress with indication this is first run
                    progressHandler(Double(bytesTransferred) / Double(totalBytes), bytesTransferred, totalBytes, fileName, "First Run: \(status)")
                }, 
                completionHandler: { result in
                    switch result {
                    case .success(let primaryDestPath):
                        // First run completed successfully, now start second run from primary dest to other destinations
                        let primaryFilePath = URL(fileURLWithPath: primaryDestPath).path
                        
                        // After first run is complete, transfer to all secondary destinations
                        transferFileToMultipleDestinations(
                            sourcePath: primaryFilePath, 
                            destinationPaths: secondaryDestinations,
                            checksumMethod: preset.checksumAlgorithm.rawValue,
                            verificationBehavior: preset.verificationBehavior.rawValue, 
                            progressHandler: { progress, bytesTransferred, totalBytes, fileName, status in
                                // Report progress with indication this is second run
                                progressHandler(progress, bytesTransferred, totalBytes, fileName, "Second Run: \(status)")
                            },
                            completionHandler: { secondResult in
                                switch secondResult {
                                case .success(let allPaths):
                                    // Return all paths including the primary destination
                                    completionHandler(.success([primaryDestPath] + allPaths))
                                case .failure(let error):
                                    completionHandler(.failure(error))
                                }
                            }
                        )
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                }
            )
        }
    }
    
    /// Generate a transfer report
    /// - Parameters:
    ///   - transfers: Completed transfers to include in report
    ///   - format: Report format
    ///   - outputPath: Where to save the report
    ///   - completionHandler: Called when report is generated
    static func generateReport(
        transfers: [FileTransfer],
        format: ReportFormat,
        outputPath: String,
        completionHandler: @escaping (Result<String, Error>) -> Void
    ) {
        // Create a background queue for report generation
        let reportQueue = DispatchQueue(label: "com.mediaforge.reportGeneration", qos: .userInitiated)
        
        reportQueue.async {
            // Skip if no transfers
            guard !transfers.isEmpty else {
                DispatchQueue.main.async {
                    completionHandler(.failure(NSError(domain: "com.mediaforge.reports", code: 1, userInfo: [NSLocalizedDescriptionKey: "No transfers to include in report"])))
                }
                return
            }
            
            // Ensure output directory exists
            let outputURL = URL(fileURLWithPath: outputPath)
            let outputDir = outputURL.deletingLastPathComponent()
            
            do {
                if !FileManager.default.fileExists(atPath: outputDir.path) {
                    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
                }
                
                // Generate report content based on format
                var reportContent = ""
                
                switch format {
                case .pdf:
                    // Generate PDF (placeholder - would use a PDF generation library in reality)
                    reportContent = generatePDFReport(transfers: transfers)
                case .html:
                    reportContent = generateHTMLReport(transfers: transfers)
                case .csv:
                    reportContent = generateCSVReport(transfers: transfers)
                case .json:
                    reportContent = generateJSONReport(transfers: transfers)
                }
                
                // Write report to file
                try reportContent.write(to: outputURL, atomically: true, encoding: .utf8)
                
                // Return success on main thread
                DispatchQueue.main.async {
                    completionHandler(.success(outputPath))
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler(.failure(error))
                }
            }
        }
    }
    
    /// Generate a PDF report (placeholder implementation)
    private static func generatePDFReport(transfers: [FileTransfer]) -> String {
        // In a real implementation, we'd use a PDF generation library
        // This is a placeholder that would be replaced with actual PDF generation code
        
        var content = "MediaForge Transfer Report\n"
        content += "=======================\n\n"
        
        content += "Generated: \(Date())\n\n"
        
        for (index, transfer) in transfers.enumerated() {
            content += "Transfer #\(index + 1)\n"
            content += "Source: \(transfer.source.name)\n"
            content += "Destination: \(transfer.destination.name)\n"
            content += "Status: \(transfer.status.description)\n"
            content += "Files: \(transfer.completedFiles)/\(transfer.totalFiles)\n"
            content += "Total Size: \(ByteCountFormatter.string(fromByteCount: transfer.totalBytesToTransfer, countStyle: .file))\n"
            content += "-------------------\n"
        }
        
        return content
    }
    
    /// Generate an HTML report
    private static func generateHTMLReport(transfers: [FileTransfer]) -> String {
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>MediaForge Transfer Report</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
                .report { max-width: 900px; margin: 0 auto; padding: 20px; }
                table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
                th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
                th { background-color: #f2f2f2; }
                .success { color: green; }
                .failure { color: red; }
                .header { border-bottom: 2px solid #333; padding-bottom: 10px; margin-bottom: 20px; }
            </style>
        </head>
        <body>
            <div class="report">
                <div class="header">
                    <h1>MediaForge Transfer Report</h1>
                    <p>Generated: \(Date())</p>
                </div>
                
                <h2>Transfer Summary</h2>
                <table>
                    <tr>
                        <th>#</th>
                        <th>Source</th>
                        <th>Destination</th>
                        <th>Status</th>
                        <th>Files</th>
                        <th>Size</th>
                    </tr>
        """
        
        for (index, transfer) in transfers.enumerated() {
            let statusClass = transfer.status == .completed ? "success" : "failure"
            
            html += """
            <tr>
                <td>\(index + 1)</td>
                <td>\(transfer.source.name)</td>
                <td>\(transfer.destination.name)</td>
                <td class="\(statusClass)">\(transfer.status.description)</td>
                <td>\(transfer.completedFiles)/\(transfer.totalFiles)</td>
                <td>\(ByteCountFormatter.string(fromByteCount: transfer.totalBytesToTransfer, countStyle: .file))</td>
            </tr>
            """
        }
        
        html += """
                </table>
            </div>
        </body>
        </html>
        """
        
        return html
    }
    
    /// Generate a CSV report
    private static func generateCSVReport(transfers: [FileTransfer]) -> String {
        var csv = "Index,Source,Destination,Status,CompletedFiles,TotalFiles,TotalSize\n"
        
        for (index, transfer) in transfers.enumerated() {
            csv += "\(index + 1),"
            csv += "\"\(transfer.source.name)\","
            csv += "\"\(transfer.destination.name)\","
            csv += "\"\(transfer.status.description)\","
            csv += "\(transfer.completedFiles),"
            csv += "\(transfer.totalFiles),"
            csv += "\"\(ByteCountFormatter.string(fromByteCount: transfer.totalBytesToTransfer, countStyle: .file))\"\n"
        }
        
        return csv
    }
    
    /// Generate a JSON report
    private static func generateJSONReport(transfers: [FileTransfer]) -> String {
        var reportData: [String: Any] = [:]
        reportData["timestamp"] = ISO8601DateFormatter().string(from: Date())
        reportData["totalTransfers"] = transfers.count
        
        var transfersArray: [[String: Any]] = []
        
        for (index, transfer) in transfers.enumerated() {
            var transferDict: [String: Any] = [:]
            transferDict["index"] = index + 1
            transferDict["source"] = transfer.source.name
            transferDict["destinationName"] = transfer.destination.name
            transferDict["destinationPath"] = transfer.destination.path
            transferDict["status"] = transfer.status.description
            transferDict["completedFiles"] = transfer.completedFiles
            transferDict["totalFiles"] = transfer.totalFiles
            transferDict["totalBytes"] = transfer.totalBytesToTransfer
            transferDict["bytesTransferred"] = transfer.bytesTransferred
            
            transfersArray.append(transferDict)
        }
        
        reportData["transfers"] = transfersArray
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: reportData, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            print("Error generating JSON: \(error)")
            return "{\"error\": \"Failed to generate JSON report\"}"
        }
    }
    
    /// Transfer a file to a single destination
    /// - Parameters:
    ///   - sourcePath: Source file path
    ///   - destinationPath: Destination path
    ///   - checksumMethod: Checksum method to use
    ///   - verificationBehavior: How to verify the file
    ///   - progressHandler: Progress updates
    ///   - completionHandler: Called when transfer completes
    static func transferFile(
        sourcePath: String,
        destinationPath: String,
        checksumMethod: String,
        verificationBehavior: String,
        progressHandler: @escaping (Int64, Int64, String, String) -> Void,
        completionHandler: @escaping (Result<String, Error>) -> Void
    ) {
        // Get file URL
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destinationURL = URL(fileURLWithPath: destinationPath).appendingPathComponent(sourceURL.lastPathComponent)
        
        // Create destination directory if needed
        do {
            let destinationFolder = destinationURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: destinationFolder.path) {
                try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
            }
        } catch {
            completionHandler(.failure(error))
            return
        }
        
        // Get file info
        let fileManager = FileManager.default
        
        do {
            let fileAttributes = try fileManager.attributesOfItem(atPath: sourcePath)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            let fileName = sourceURL.lastPathComponent
            
            // Start the transfer
            progressHandler(0, fileSize, fileName, "Starting transfer")
            
            // Simple file copy for demonstration
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            
            // Verify the file if requested
            if verificationBehavior != "none" {
                progressHandler(fileSize, fileSize, fileName, "Verifying file")
                
                // Calculate checksums
                let sourceChecksum: String?
                let destChecksum: String?
                
                switch checksumMethod {
                case "xxHash64":
                    sourceChecksum = calculateXXHash64(for: sourcePath)
                    destChecksum = calculateXXHash64(for: destinationURL.path)
                case "md5":
                    sourceChecksum = calculateMD5(for: sourcePath)
                    destChecksum = calculateMD5(for: destinationURL.path)
                case "sha1":
                    sourceChecksum = calculateSHA1(for: sourcePath)
                    destChecksum = calculateSHA1(for: destinationURL.path)
                default:
                    // Default to xxHash64 as it's fastest
                    sourceChecksum = calculateXXHash64(for: sourcePath)
                    destChecksum = calculateXXHash64(for: destinationURL.path)
                }
                
                // Compare checksums
                if sourceChecksum != destChecksum {
                    // Verification failed
                    let error = NSError(
                        domain: "com.mediaforge.transfer",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Verification failed for \(fileName)"]
                    )
                    
                    // Try to clean up the failed file
                    try? fileManager.removeItem(at: destinationURL)
                    
                    completionHandler(.failure(error))
                    return
                }
            }
            
            // Complete the transfer
            progressHandler(fileSize, fileSize, fileName, "Transfer complete")
            completionHandler(.success(destinationURL.path))
        } catch {
            completionHandler(.failure(error))
        }
    }
    
    /// Transfer a file to multiple destinations
    /// - Parameters:
    ///   - sourcePath: Source file path
    ///   - destinationPaths: Array of destination paths
    ///   - checksumMethod: Checksum method to use
    ///   - verificationBehavior: How to verify the file
    ///   - progressHandler: Progress updates
    ///   - completionHandler: Called when all transfers complete
    static func transferFileToMultipleDestinations(
        sourcePath: String,
        destinationPaths: [String],
        checksumMethod: String,
        verificationBehavior: String,
        progressHandler: @escaping (Double, Int64, Int64, String, String) -> Void,
        completionHandler: @escaping (Result<[String], Error>) -> Void
    ) {
        // Skip if no destinations
        guard !destinationPaths.isEmpty else {
            completionHandler(.success([]))
            return
        }
        
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let fileName = sourceURL.lastPathComponent
        
        // Get file info
        let fileManager = FileManager.default
        
        do {
            let fileAttributes = try fileManager.attributesOfItem(atPath: sourcePath)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            
            // Track completed transfers
            var completedDestinations: [String] = []
            var failedDestinations: [(String, Error)] = []
            let group = DispatchGroup()
            let queue = DispatchQueue(label: "com.mediaforge.transfers", attributes: .concurrent)
            let progressLock = NSLock()
            
            // Process each destination
            for destinationPath in destinationPaths {
                group.enter()
                
                queue.async {
                    self.transferFile(
                        sourcePath: sourcePath,
                        destinationPath: destinationPath,
                        checksumMethod: checksumMethod,
                        verificationBehavior: verificationBehavior,
                        progressHandler: { bytesTransferred, totalBytes, name, status in
                            // Update progress with normalized details
                            // Lock to avoid race conditions on progress reporting from different destinations
                            progressLock.lock()
                            let progress = Double(bytesTransferred) / Double(totalBytes)
                            progressHandler(progress, bytesTransferred, totalBytes, name, "\(destinationPath): \(status)")
                            progressLock.unlock()
                        },
                        completionHandler: { result in
                            switch result {
                            case .success(let destPath):
                                // Keep track of completed destination
                                progressLock.lock()
                                completedDestinations.append(destPath)
                                progressLock.unlock()
                            case .failure(let error):
                                // Keep track of failed destination
                                progressLock.lock()
                                failedDestinations.append((destinationPath, error))
                                progressLock.unlock()
                            }
                            
                            group.leave()
                        }
                    )
                }
            }
            
            // When all transfers complete
            group.notify(queue: .main) {
                if failedDestinations.isEmpty {
                    // All transfers succeeded
                    completionHandler(.success(completedDestinations))
                } else {
                    // At least one transfer failed
                    let errors = failedDestinations.map { "\($0.0): \($0.1.localizedDescription)" }.joined(separator: ", ")
                    let error = NSError(
                        domain: "com.mediaforge.transfer",
                        code: 3,
                        userInfo: [
                            NSLocalizedDescriptionKey: "One or more transfers failed: \(errors)",
                            "failedDestinations": failedDestinations.map { $0.0 }
                        ]
                    )
                    
                    completionHandler(.failure(error))
                }
            }
        } catch {
            completionHandler(.failure(error))
        }
    }
} 
