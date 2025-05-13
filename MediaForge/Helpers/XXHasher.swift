import Foundation

/// Implementation of the xxHash64 algorithm for fast, non-cryptographic hashing
struct XXHasher {
    // xxHash prime constants
    private let prime1: UInt64 = 11400714785074694791
    private let prime2: UInt64 = 14029467366897019727
    private let prime3: UInt64 = 1609587929392839161
    private let prime4: UInt64 = 9650029242287828579
    private let prime5: UInt64 = 2870177450012600261
    
    // State variables
    private var v1: UInt64
    private var v2: UInt64
    private var v3: UInt64
    private var v4: UInt64
    private var totalLength: UInt64
    private var buffer = [UInt8](repeating: 0, count: 32)
    private var bufferSize: Int = 0
    
    /// Initialize a new hasher with a seed value
    init(seed: UInt64 = 0) {
        // Initialize internal state
        v1 = seed &+ prime1 &+ prime2
        v2 = seed &+ prime2
        v3 = seed
        v4 = seed &- prime1
        totalLength = 0
    }
    
    /// Update the hash with new data
    mutating func update(data: Data) {
        // Prevent crashes with empty data
        if data.isEmpty {
            return
        }
        
        var pos = 0
        let length = data.count
        totalLength += UInt64(length)
        
        // If we have data in the buffer, try to fill it first
        if bufferSize > 0 {
            let missing = 32 - bufferSize
            let toFill = min(missing, length)
            
            // Fill buffer with new data
            data.copyBytes(to: &buffer[bufferSize], from: 0..<toFill)
            bufferSize += toFill
            pos += toFill
            
            // If buffer is full, process it
            if bufferSize == 32 {
                processStripe(buffer, 0)
                bufferSize = 0
            }
            
            // If we've consumed all input, return
            if pos == length {
                return
            }
        }
        
        // Process 32-byte stripes
        let limit = length - 32
        while pos <= limit {
            processStripe(data, pos)
            pos += 32
        }
        
        // Store remaining bytes in buffer
        if pos < length {
            let remaining = length - pos
            data.copyBytes(to: &buffer, from: pos..<length)
            bufferSize = remaining
        }
    }
    
    /// Process a full 32-byte stripe
    private mutating func processStripe(_ data: Data, _ offset: Int) {
        // Read stride values directly from data
        let val1 = readUInt64(data, offset)
        let val2 = readUInt64(data, offset + 8)
        let val3 = readUInt64(data, offset + 16)
        let val4 = readUInt64(data, offset + 24)
        
        // Update internal state
        v1 = round(v1, val1)
        v2 = round(v2, val2)
        v3 = round(v3, val3)
        v4 = round(v4, val4)
    }
    
    /// Process a full 32-byte stripe from buffer
    private mutating func processStripe(_ buffer: [UInt8], _ offset: Int) {
        let val1 = readUInt64FromBuffer(buffer, offset)
        let val2 = readUInt64FromBuffer(buffer, offset + 8)
        let val3 = readUInt64FromBuffer(buffer, offset + 16)
        let val4 = readUInt64FromBuffer(buffer, offset + 24)
        
        // Update internal state
        v1 = round(v1, val1)
        v2 = round(v2, val2)
        v3 = round(v3, val3)
        v4 = round(v4, val4)
    }
    
    /// Internal round function
    private func round(_ acc: UInt64, _ input: UInt64) -> UInt64 {
        var acc = acc
        acc &+= input &* prime2
        acc = rotateLeft(acc, by: 31)
        acc &*= prime1
        return acc
    }
    
    /// Merge the internal state into a final hash value
    private func mergeAccumulators(_ acc: inout UInt64, _ h1: UInt64, _ h2: UInt64, _ h3: UInt64, _ h4: UInt64) {
        acc &+= rotateLeft(h1, by: 1) &+ rotateLeft(h2, by: 7) &+ rotateLeft(h3, by: 12) &+ rotateLeft(h4, by: 18)
    }
    
    /// Read a UInt64 from a Data object at a specific offset
    private func readUInt64(_ data: Data, _ offset: Int) -> UInt64 {
        var value: UInt64 = 0
        withUnsafeMutableBytes(of: &value) { buffer in
            data.copyBytes(to: buffer, from: offset..<(offset+8))
        }
        return value
    }
    
    /// Read a UInt64 from a byte buffer at a specific offset
    private func readUInt64FromBuffer(_ buffer: [UInt8], _ offset: Int) -> UInt64 {
        return buffer.withUnsafeBytes { ptr -> UInt64 in
            let address = ptr.baseAddress!.advanced(by: offset)
            return address.bindMemory(to: UInt64.self, capacity: 1).pointee
        }
    }
    
    /// Rotate left operation
    private func rotateLeft(_ value: UInt64, by count: UInt64) -> UInt64 {
        return (value << count) | (value >> (64 - count))
    }
    
    /// Finalize and return the hash value
    func finalize() -> UInt64 {
        var hash: UInt64
        
        // If we processed at least one complete stripe
        if totalLength >= 32 {
            // Use the accumulated state as a base
            hash = rotateLeft(v1, by: 1) &+ rotateLeft(v2, by: 7) &+ rotateLeft(v3, by: 12) &+ rotateLeft(v4, by: 18)
            
            // Merge the accumulators
            hash = mergeRound(hash, v1)
            hash = mergeRound(hash, v2)
            hash = mergeRound(hash, v3)
            hash = mergeRound(hash, v4)
        } else {
            // For short inputs, start with a seed
            hash = v3 + prime5
        }
        
        // Add length information
        hash += totalLength
        
        // Process remaining bytes in buffer
        var pos = 0
        while pos + 8 <= bufferSize {
            let val = readUInt64FromBuffer(buffer, pos)
            hash ^= round(0, val)
            hash = rotateLeft(hash, by: 27) &* prime1 &+ prime4
            pos += 8
        }
        
        // Process remaining 4 bytes if any
        if pos + 4 <= bufferSize {
            let val = readUInt32FromBuffer(buffer, pos)
            hash ^= UInt64(val) &* prime1
            hash = rotateLeft(hash, by: 23) &* prime2 &+ prime3
            pos += 4
        }
        
        // Process remaining bytes one by one
        while pos < bufferSize {
            let val = UInt64(buffer[pos])
            hash ^= val &* prime5
            hash = rotateLeft(hash, by: 11) &* prime1
            pos += 1
        }
        
        // Final avalanche
        hash ^= hash >> 33
        hash &*= prime2
        hash ^= hash >> 29
        hash &*= prime3
        hash ^= hash >> 32
        
        return hash
    }
    
    /// Read a UInt32 from a buffer
    private func readUInt32FromBuffer(_ buffer: [UInt8], _ offset: Int) -> UInt32 {
        return buffer.withUnsafeBytes { ptr -> UInt32 in
            let address = ptr.baseAddress!.advanced(by: offset)
            return address.bindMemory(to: UInt32.self, capacity: 1).pointee
        }
    }
    
    /// Merge round
    private func mergeRound(_ acc: UInt64, _ val: UInt64) -> UInt64 {
        let val = round(0, val)
        var acc = acc ^ val
        acc = acc &* prime1 &+ prime4
        return acc
    }
    
    /// Static method to generate hash in one step
    static func hash(data: Data, seed: UInt64 = 0) -> UInt64 {
        var hasher = XXHasher(seed: seed)
        hasher.update(data: data)
        return hasher.finalize()
    }
    
    /// Static method to generate hash string from a file path
    static func hash(filePath: String, seed: UInt64 = 0) -> String? {
        do {
            let url = URL(fileURLWithPath: filePath)
            var hasher = XXHasher(seed: seed)
            let fileHandle = try FileHandle(forReadingFrom: url)
            defer { fileHandle.closeFile() }
            
            // Dosyayı 1MB'lık parçalar halinde oku
            let bufferSize = 1024 * 1024
            while true {
                autoreleasepool {
                    let data = fileHandle.readData(ofLength: bufferSize)
                    if data.isEmpty { return }
                    hasher.update(data: data)
                }
            }
            
            let hash = hasher.finalize()
            return String(format: "%016llx", hash)
        } catch {
            print("xxHash calculation error: \(error.localizedDescription)")
            return nil
        }
    }
} 