package struct MemoryStats: Equatable, Sendable {
    package var physical: UInt64
    /// Activity Monitor's App memory: internal pages minus purgeable.
    package var app: UInt64
    package var wired: UInt64
    package var compressed: UInt64
    package var compressedOriginal: UInt64
    /// External (file-backed) plus purgeable: dropped on demand, so it counts as available.
    package var cached: UInt64
    package var swap = Swap()

    package struct Swap: Equatable, Sendable {
        package var used: UInt64
        package var total: UInt64
        package var swappedIn: UInt64
        package var swappedOut: UInt64

        package init(used: UInt64 = 0, total: UInt64 = 0, swappedIn: UInt64 = 0, swappedOut: UInt64 = 0) {
            self.used = used
            self.total = total
            self.swappedIn = swappedIn
            self.swappedOut = swappedOut
        }
    }

    /// Activity Monitor's "Memory Used": App + Wired + Compressed.
    package var used: UInt64 { app + wired + compressed }

    package var available: UInt64 { cached + free }

    package var free: UInt64 { physical - min(physical, used + cached) }

    package var usedFraction: Double {
        guard physical > 0 else { return 0 }
        return min(1, Double(used) / Double(physical))
    }

    package var compressionRatio: Double? {
        guard compressed > 0, compressedOriginal > 0 else { return nil }
        return Double(compressedOriginal) / Double(compressed)
    }

    /// `anonymous` is `internal_page_count`.
    package init(pageSize: UInt64, physical: UInt64, anonymous: UInt64, purgeable: UInt64,
                 external: UInt64, wired: UInt64, compressor: UInt64, uncompressed: UInt64 = 0, swap: Swap = Swap()) {
        self.physical = physical
        app = (anonymous - min(anonymous, purgeable)) * pageSize
        self.wired = wired * pageSize
        compressed = compressor * pageSize
        compressedOriginal = uncompressed * pageSize
        cached = (external + purgeable) * pageSize
        self.swap = swap
    }
}

package struct SwapRate: Equatable, Sendable {
    package var inPerSecond: Double
    package var outPerSecond: Double

    package init(inPerSecond: Double, outPerSecond: Double) {
        self.inPerSecond = inPerSecond
        self.outPerSecond = outPerSecond
    }

    package static func between(_ old: MemoryStats.Swap, _ new: MemoryStats.Swap, seconds: Double) -> SwapRate? {
        guard seconds > 0 else { return nil }
        func rate(_ old: UInt64, _ new: UInt64) -> Double { new >= old ? Double(new - old) / seconds : 0 }
        return SwapRate(inPerSecond: rate(old.swappedIn, new.swappedIn), outPerSecond: rate(old.swappedOut, new.swappedOut))
    }
}

package enum MemoryPart: CaseIterable, Sendable {
    case app
    case wired
    case compressed
    case cached
    case free
}

extension MemoryStats {
    package func bytes(_ part: MemoryPart) -> UInt64 {
        switch part {
        case .app: app
        case .wired: wired
        case .compressed: compressed
        case .cached: cached
        case .free: free
        }
    }

    package func fraction(_ part: MemoryPart) -> Double {
        physical > 0 ? Double(bytes(part)) / Double(physical) : 0
    }
}
