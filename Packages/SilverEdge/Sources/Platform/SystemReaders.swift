import Darwin
import Foundation
import Domain

/// The two cheap kernel reads the menu bar needs, a few microseconds each.
package enum SystemReaders {
    /// `mach_host_self()` hands out a new send right per call; take it once.
    private static let host = mach_host_self()
    private static let pageSize: UInt64 = {
        var size: vm_size_t = 0
        return host_page_size(host, &size) == KERN_SUCCESS ? UInt64(size) : UInt64(getpagesize())
    }()

    package static func cpuTicks() -> CPUTicks? {
        var info = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics(host, HOST_CPU_LOAD_INFO, $0, &count) }
        }
        guard result == KERN_SUCCESS else { return nil }
        let ticks = info.cpu_ticks
        return CPUTicks(user: ticks.0, system: ticks.1, idle: ticks.2, nice: ticks.3)
    }

    package static func memory() -> MemoryStats? {
        var info = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics64(host, HOST_VM_INFO64, $0, &count) }
        }
        guard result == KERN_SUCCESS else { return nil }
        return MemoryStats(
            pageSize: pageSize, physical: ProcessInfo.processInfo.physicalMemory,
            anonymous: UInt64(info.internal_page_count), purgeable: UInt64(info.purgeable_count),
            external: UInt64(info.external_page_count), wired: UInt64(info.wire_count),
            compressor: UInt64(info.compressor_page_count), uncompressed: UInt64(info.total_uncompressed_pages_in_compressor),
            swap: swap(swappedIn: UInt64(info.swapins) * pageSize, swappedOut: UInt64(info.swapouts) * pageSize)
        )
    }

    private static func swap(swappedIn: UInt64, swappedOut: UInt64) -> MemoryStats.Swap {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        guard sysctlbyname("vm.swapusage", &usage, &size, nil, 0) == 0 else {
            return MemoryStats.Swap(swappedIn: swappedIn, swappedOut: swappedOut)
        }
        return MemoryStats.Swap(used: usage.xsu_used, total: usage.xsu_total, swappedIn: swappedIn, swappedOut: swappedOut)
    }

    /// Each core's cumulative ticks, in CPU number order.
    package static func coreTicks() -> [CPUTicks]? {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        guard host_processor_info(host, PROCESSOR_CPU_LOAD_INFO, &cpuCount, &info, &infoCount) == KERN_SUCCESS,
              let info else { return nil }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride))
        }
        let states = Int(CPU_STATE_MAX)
        return (0..<Int(cpuCount)).map { core in
            func ticks(_ state: Int32) -> UInt32 { UInt32(bitPattern: info[core * states + Int(state)]) }
            return CPUTicks(user: ticks(CPU_STATE_USER), system: ticks(CPU_STATE_SYSTEM), idle: ticks(CPU_STATE_IDLE), nice: ticks(CPU_STATE_NICE))
        }
    }

    /// Efficiency cores (perf level 1 on Apple silicon); 0 on a CPU with one kind of core.
    package static let efficiencyCoreCount: Int = {
        guard (sysctlInt("hw.nperflevels") ?? 1) >= 2 else { return 0 }
        return sysctlInt("hw.perflevel1.logicalcpu") ?? 0
    }()

    package static func loadAverage() -> LoadAverage {
        var averages = [Double](repeating: 0, count: 3)
        _ = getloadavg(&averages, 3)
        var boot = timeval()
        var size = MemoryLayout<timeval>.size
        let uptime = sysctlbyname("kern.boottime", &boot, &size, nil, 0) == 0
            ? Date().timeIntervalSince1970 - Double(boot.tv_sec) : 0
        return LoadAverage(one: averages[0], five: averages[1], fifteen: averages[2], uptime: uptime)
    }

    private static func sysctlInt(_ name: String) -> Int? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        return sysctlbyname(name, &value, &size, nil, 0) == 0 ? Int(value) : nil
    }

    package static func memoryPressure() -> MemoryPressure {
        sysctlInt("kern.memorystatus_vm_pressure_level").map { MemoryPressure(kernelLevel: Int32($0)) } ?? .normal
    }
}
