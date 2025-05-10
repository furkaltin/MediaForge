import Foundation
import CryptoKit

/// Manages creation and validation of Media Hash List (MHL) files
/// Implements ASC-MHL standard for file verification
class MediaHashList {
    /// MHL format version
    private static let mhlVersion = "1.3"
    
    /// Creator information
    private static let creatorName = "MediaForge"
    
    /// Hash algorithm to use
    enum HashAlgorithm: String {
        case md5 = "MD5"
        case sha1 = "SHA1"
        case xxHash64 = "xxHash64"
        
        var ascName: String {
            switch self {
            case .md5:
                return "md5"
            case .sha1:
                return "sha1"
            case .xxHash64:
                return "xxh64"
            }
        }
    }
    
    /// Generate an MHL file for a collection of files
    /// - Parameters:
    ///   - files: Array of file paths to include in the MHL
    ///   - mhlPath: Path where the MHL file will be saved
    ///   - algorithm: Hash algorithm to use
    ///   - comment: Optional comment to include in the MHL
    /// - Returns: True if MHL was created successfully
    static func generateMHL(
        for files: [String],
        mhlPath: String,
        algorithm: HashAlgorithm = .md5,
        comment: String? = nil
    ) -> Bool {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        // XML Header
        var lines = [String]()
        lines.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        lines.append("<hashlist version=\"\(mhlVersion)\">")
        lines.append("    <creatorinfo>")
        lines.append("        <name>\(creatorName)</name>")
        lines.append("        <version>\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")</version>")
        lines.append("        <datetime>\(timestamp)</datetime>")
        lines.append("    </creatorinfo>")
        
        if let commentText = comment, !commentText.isEmpty {
            lines.append("    <comment>\(escapeXML(commentText))</comment>")
        }
        
        // Calculate hashes for each file and add to MHL
        var hashesGenerated = 0
        
        for filePath in files {
            if let hash = calculateHash(filePath: filePath, algorithm: algorithm) {
                let url = URL(fileURLWithPath: filePath)
                let fileName = url.lastPathComponent
                let directory = url.deletingLastPathComponent().lastPathComponent
                
                // Get file attributes for size and modification date
                let fileManager = FileManager.default
                if let attrs = try? fileManager.attributesOfItem(atPath: filePath) {
                    let size = attrs[.size] as? Int64 ?? 0
                    let modDate = attrs[.modificationDate] as? Date ?? Date()
                    let modDateString = ISO8601DateFormatter().string(from: modDate)
                    
                    lines.append("    <hash>")
                    lines.append("        <file>\(escapeXML(fileName))</file>")
                    lines.append("        <dir>\(escapeXML(directory))</dir>")
                    lines.append("        <size>\(size)</size>")
                    lines.append("        <\(algorithm.ascName)>\(hash)</\(algorithm.ascName)>")
                    lines.append("        <lastmodificationdate>\(modDateString)</lastmodificationdate>")
                    lines.append("    </hash>")
                    
                    hashesGenerated += 1
                }
            }
        }
        
        lines.append("</hashlist>")
        
        // Skip if no hashes were generated
        if hashesGenerated == 0 {
            print("No valid hashes were generated for the MHL")
            return false
        }
        
        // Join lines and write to file
        let xmlContent = lines.joined(separator: "\n")
        
        // Try to write MHL file
        do {
            try xmlContent.write(to: URL(fileURLWithPath: mhlPath), atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Failed to write MHL file: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Verify files against an existing MHL
    /// - Parameters:
    ///   - mhlPath: Path to the MHL file
    ///   - basePath: Base path for the files (if they moved)
    /// - Returns: Verification result with details
    static func verifyMHL(mhlPath: String, basePath: String? = nil) -> VerificationResult {
        // Load and parse MHL
        guard let xmlData = try? Data(contentsOf: URL(fileURLWithPath: mhlPath)),
              let xmlDoc = try? XMLDocument(data: xmlData, options: []) else {
            return VerificationResult(
                success: false,
                message: "Failed to parse MHL file",
                verifiedFiles: [],
                missingFiles: [],
                invalidFiles: []
            )
        }
        
        // Extract file entries
        let hashNodes = try? xmlDoc.nodes(forXPath: "//hash")
        
        var verifiedFiles: [String] = []
        var missingFiles: [String] = []
        var invalidFiles: [String] = []
        
        for node in hashNodes ?? [] {
            if let fileNode = try? node.nodes(forXPath: "file").first,
               let fileNameText = fileNode.stringValue,
               let dirNode = try? node.nodes(forXPath: "dir").first,
               let dirText = dirNode.stringValue {
                
                // Determine which hash algorithm is used in this entry
                var algorithm: HashAlgorithm?
                var storedHash: String?
                
                for alg in [HashAlgorithm.md5, .sha1, .xxHash64] {
                    if let hashNode = try? node.nodes(forXPath: alg.ascName).first,
                       let hashValue = hashNode.stringValue {
                        algorithm = alg
                        storedHash = hashValue
                        break
                    }
                }
                
                guard let algorithm = algorithm, let storedHash = storedHash else {
                    continue
                }
                
                // Construct file path
                let filePath: String
                if let base = basePath {
                    filePath = URL(fileURLWithPath: base)
                        .appendingPathComponent(dirText)
                        .appendingPathComponent(fileNameText)
                        .path
                } else {
                    filePath = URL(fileURLWithPath: mhlPath)
                        .deletingLastPathComponent()
                        .appendingPathComponent(dirText)
                        .appendingPathComponent(fileNameText)
                        .path
                }
                
                // Check if file exists
                if FileManager.default.fileExists(atPath: filePath) {
                    // Calculate current hash
                    if let currentHash = calculateHash(filePath: filePath, algorithm: algorithm) {
                        if currentHash.lowercased() == storedHash.lowercased() {
                            verifiedFiles.append(filePath)
                        } else {
                            invalidFiles.append(filePath)
                        }
                    } else {
                        invalidFiles.append(filePath)
                    }
                } else {
                    missingFiles.append(filePath)
                }
            }
        }
        
        let success = invalidFiles.isEmpty && !verifiedFiles.isEmpty
        let message = success ? "All files verified successfully" : "Verification failed"
        
        return VerificationResult(
            success: success,
            message: message,
            verifiedFiles: verifiedFiles,
            missingFiles: missingFiles,
            invalidFiles: invalidFiles
        )
    }
    
    /// Calculate hash for a file
    /// - Parameters:
    ///   - filePath: Path to the file
    ///   - algorithm: Hash algorithm to use
    /// - Returns: Hash string or nil if calculation failed
    private static func calculateHash(filePath: String, algorithm: HashAlgorithm) -> String? {
        switch algorithm {
        case .md5:
            return FileTransferManager.calculateMD5(for: filePath)
        case .sha1:
            return FileTransferManager.calculateSHA1(for: filePath)
        case .xxHash64:
            return FileTransferManager.calculateXXHash64(for: filePath)
        }
    }
    
    /// Escape special characters in XML content
    private static func escapeXML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

/// Result of MHL verification
struct VerificationResult {
    let success: Bool
    let message: String
    let verifiedFiles: [String]
    let missingFiles: [String]
    let invalidFiles: [String]
    
    var verifiedCount: Int { verifiedFiles.count }
    var missingCount: Int { missingFiles.count }
    var invalidCount: Int { invalidFiles.count }
    var totalFiles: Int { verifiedCount + missingCount + invalidCount }
}

/// Extension for generating MHL history
extension MediaHashList {
    /// Generate an updated MHL file that includes history
    /// - Parameters:
    ///   - files: Array of file paths to include in the MHL
    ///   - mhlPath: Path where the MHL file will be saved
    ///   - previousMHLs: Array of paths to previous MHL files
    ///   - algorithm: Hash algorithm to use
    ///   - comment: Optional comment to include in the MHL
    /// - Returns: True if MHL was created successfully
    static func generateMHLWithHistory(
        for files: [String],
        mhlPath: String,
        previousMHLs: [String],
        algorithm: HashAlgorithm = .md5,
        comment: String? = nil
    ) -> Bool {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        // XML Header with lines array
        var lines = [String]()
        lines.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        lines.append("<hashlist version=\"\(mhlVersion)\">")
        lines.append("    <creatorinfo>")
        lines.append("        <name>\(creatorName)</name>")
        lines.append("        <version>\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")</version>")
        lines.append("        <datetime>\(timestamp)</datetime>")
        lines.append("    </creatorinfo>")
        
        if let commentText = comment, !commentText.isEmpty {
            lines.append("    <comment>\(escapeXML(commentText))</comment>")
        }
        
        // Add previous MHLs as history
        if !previousMHLs.isEmpty {
            lines.append("    <history>")
            
            for previousMHL in previousMHLs {
                let url = URL(fileURLWithPath: previousMHL)
                let mhlName = url.lastPathComponent
                
                // Only include MHL files in history
                if mhlName.lowercased().hasSuffix(".mhl") {
                    if let mhlData = try? Data(contentsOf: url) {
                        let hashValue = Insecure.SHA1.hash(data: mhlData).map { String(format: "%02hhx", $0) }.joined()
                        lines.append("        <hashlist>")
                        lines.append("            <path>\(escapeXML(mhlName))</path>")
                        lines.append("            <hash alg=\"sha1\">\(hashValue)</hash>")
                        lines.append("        </hashlist>")
                    }
                }
            }
            
            lines.append("    </history>")
        }
        
        // Calculate hashes for each file and add to MHL
        var hashesGenerated = 0
        
        for filePath in files {
            if let hash = calculateHash(filePath: filePath, algorithm: algorithm) {
                let url = URL(fileURLWithPath: filePath)
                let fileName = url.lastPathComponent
                let directory = url.deletingLastPathComponent().lastPathComponent
                
                // Get file attributes for size and modification date
                let fileManager = FileManager.default
                if let attrs = try? fileManager.attributesOfItem(atPath: filePath) {
                    let size = attrs[.size] as? Int64 ?? 0
                    let modDate = attrs[.modificationDate] as? Date ?? Date()
                    let modDateString = ISO8601DateFormatter().string(from: modDate)
                    
                    lines.append("    <hash>")
                    lines.append("        <file>\(escapeXML(fileName))</file>")
                    lines.append("        <dir>\(escapeXML(directory))</dir>")
                    lines.append("        <size>\(size)</size>")
                    lines.append("        <\(algorithm.ascName)>\(hash)</\(algorithm.ascName)>")
                    lines.append("        <lastmodificationdate>\(modDateString)</lastmodificationdate>")
                    lines.append("    </hash>")
                    
                    hashesGenerated += 1
                }
            }
        }
        
        lines.append("</hashlist>")
        
        // Skip if no hashes were generated
        if hashesGenerated == 0 {
            print("No valid hashes were generated for the MHL")
            return false
        }
        
        // Join lines and write to file
        let xmlContent = lines.joined(separator: "\n")
        
        // Try to write MHL file
        do {
            try xmlContent.write(to: URL(fileURLWithPath: mhlPath), atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Failed to write MHL file: \(error.localizedDescription)")
            return false
        }
    }
} 