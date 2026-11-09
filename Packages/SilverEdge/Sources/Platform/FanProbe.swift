import Foundation
import IOKit
import Domain

/// SMC fan speeds, no root: `AppleSMC` user client, struct method 2, an 80-byte parameter block
/// (as byte offsets), keys `FNum` and `F<n>Ac`/`Mn`/`Mx`. Holds the connection: keep only while shown.
@MainActor
package final class FanProbe {
    private enum Offset {
        static let key = 0
        static let dataSize = 28
        static let dataType = 32
        static let result = 40
        static let command = 42
        static let bytes = 48
        static let blockSize = 80
    }

    private enum Command {
        static let readBytes: UInt8 = 5
        static let readKeyInfo: UInt8 = 9
    }

    private static let structMethod: UInt32 = 2

    private struct Key {
        let code: UInt32
        let size: UInt32
        let type: UInt32
    }

    private struct Fan {
        let actual: Key
        let minimum: Double
        let maximum: Double
    }

    private var connection: io_connect_t = 0
    private var fans: [Fan] = []

    package init?() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        guard IOServiceOpen(service, mach_task_self_, 0, &connection) == KERN_SUCCESS else { return nil }
        let count = Int(value("FNum") ?? 0)
        for index in 0..<count {
            guard let actual = info("F\(index)Ac") else { continue }
            fans.append(Fan(actual: actual, minimum: value("F\(index)Mn") ?? 0, maximum: value("F\(index)Mx") ?? 0))
        }
        if fans.isEmpty {
            IOServiceClose(connection)
            return nil
        }
    }

    deinit {
        IOServiceClose(connection)
    }

    package func read() -> [FanStatus] {
        fans.map { FanStatus(rpm: value($0.actual) ?? 0, minimum: $0.minimum, maximum: $0.maximum) }
    }

    // MARK: - SMC

    private func value(_ name: String) -> Double? {
        info(name).flatMap(value)
    }

    private func value(_ key: Key) -> Double? {
        guard let output = call(key.code, command: Command.readBytes, size: key.size) else { return nil }
        let bytes = Array(output[Offset.bytes..<(Offset.bytes + Int(min(key.size, 32)))])
        switch Self.fourCC(key.type) {
        case "flt " where bytes.count >= 4:
            return Double(bytes.withUnsafeBytes { $0.loadUnaligned(as: Float.self) })
        case "fpe2" where bytes.count >= 2:
            return Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1])) / 4
        case "ui8 " where !bytes.isEmpty:
            return Double(bytes[0])
        case "ui16" where bytes.count >= 2:
            return Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
        default:
            return nil
        }
    }

    private func info(_ name: String) -> Key? {
        let code = name.utf8.reduce(UInt32(0)) { $0 << 8 | UInt32($1) }
        guard let output = call(code, command: Command.readKeyInfo, size: 0) else { return nil }
        return output.withUnsafeBytes {
            Key(code: code, size: $0.loadUnaligned(fromByteOffset: Offset.dataSize, as: UInt32.self),
                type: $0.loadUnaligned(fromByteOffset: Offset.dataType, as: UInt32.self))
        }
    }

    private func call(_ code: UInt32, command: UInt8, size: UInt32) -> [UInt8]? {
        var input = [UInt8](repeating: 0, count: Offset.blockSize)
        input.withUnsafeMutableBytes {
            $0.storeBytes(of: code, toByteOffset: Offset.key, as: UInt32.self)
            $0.storeBytes(of: size, toByteOffset: Offset.dataSize, as: UInt32.self)
            $0.storeBytes(of: command, toByteOffset: Offset.command, as: UInt8.self)
        }
        var output = [UInt8](repeating: 0, count: Offset.blockSize)
        var outputSize = output.count
        let result = input.withUnsafeBytes { inBytes in
            output.withUnsafeMutableBytes { outBytes in
                IOConnectCallStructMethod(connection, Self.structMethod, inBytes.baseAddress, inBytes.count, outBytes.baseAddress, &outputSize)
            }
        }
        guard result == KERN_SUCCESS, output[Offset.result] == 0 else { return nil }
        return output
    }

    private static func fourCC(_ value: UInt32) -> String {
        String(bytes: [24, 16, 8, 0].map { UInt8((value >> $0) & 0xff) }, encoding: .ascii) ?? ""
    }
}
