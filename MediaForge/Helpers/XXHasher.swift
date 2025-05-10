import Foundation

/// Implementation of the xxHash64 algorithm for fast, non-cryptographic hashing
struct XXHasher {
    // xxHash prime constants
    private let prime1: UInt64 = 11400714785074694791
    private let prime2: UInt64 = 14029467366897019727
    private let prime3: UInt64 = 1609587929392839161
    private let prime4: UInt64 = 9650029242287828579
    private let prime5: UInt64 = 2870177450012600261
    
    // State
    private var state: UInt64 = 0
    
    /// Initialize a new hasher with a seed value
    init(seed: UInt64 = 0) {
        state = seed + prime5
    }
    
    /// Update the hash with new data
    mutating func update(data: Data) {
        // Simple implementation that hashes the entire data at once
        let length = UInt64(data.count)
        
        // Process data
        var pos = 0
        while pos + 8 <= data.count {
            let chunk = data.subdata(in: pos..<pos+8)
            let val = chunk.withUnsafeBytes { bytes -> UInt64 in
                guard let ptr = bytes.baseAddress else { return 0 }
                return ptr.assumingMemoryBound(to: UInt64.self).pointee
            }
            
            state = rotateLeft(state + val * prime2, by: 31) * prime1
            pos += 8
        }
        
        // Process remaining bytes
        while pos < data.count {
            state = rotateLeft(state + UInt64(data[pos]) * prime5, by: 11) * prime1
            pos += 1
        }
        
        // Mix with length
        state ^= length
    }
    
    /// Rotate left operation
    private func rotateLeft(_ value: UInt64, by count: UInt64) -> UInt64 {
        return (value << count) | (value >> (64 - count))
    }
    
    /// Finalize and return the hash value
    func finalize() -> UInt64 {
        var h = state
        
        h = (h ^ (h >> 33)) * prime2
        h = (h ^ (h >> 29)) * prime3
        h = (h ^ (h >> 32))
        
        return h
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
            let data = try Data(contentsOf: url)
            let hash = XXHasher.hash(data: data, seed: seed)
            return String(format: "%016llx", hash)
        } catch {
            print("xxHash calculation error: \(error.localizedDescription)")
            return nil
        }
    }
} 