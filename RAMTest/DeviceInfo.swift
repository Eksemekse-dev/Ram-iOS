import Foundation
import Security
import UIKit

struct DeviceInfo {
    let hasIncreasedMemoryLimit: Bool
    let iosName: String
    let iosVersion: String
    let deviceName: String
    let deviceIdentifier: String
    let processor: String

    static let current = DeviceInfo()

    private init() {
        hasIncreasedMemoryLimit = Self.readEntitlement("com.apple.developer.kernel.increased-memory-limit")
        iosName = UIDevice.current.systemName
        iosVersion = UIDevice.current.systemVersion
        deviceIdentifier = Self.machineIdentifier()
        let mapped = Self.deviceMap[deviceIdentifier]
        deviceName = mapped?.name ?? (UIDevice.current.model + " (\(deviceIdentifier))")
        let cores = Self.sysctlInt("hw.ncpu").map { "\($0) cores" } ?? ""
        let chip = mapped?.chip ?? Self.chipFromFamily() ?? "Unknown CPU"
        processor = cores.isEmpty ? chip : "\(chip), \(cores)"
    }

    private static func readEntitlement(_ key: String) -> Bool {
        guard let task = SecTaskCreateFromSelf(nil) else { return false }
        var error: Unmanaged<CFError>?
        guard let value = SecTaskCopyValueForEntitlement(task, key as CFString, &error) else {
            return false
        }
        if let flag = value as? Bool {
            return flag
        }
        return true
    }

    private static func machineIdentifier() -> String {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                String(cString: $0)
            }
        }
    }

    private static func sysctlInt(_ name: String) -> Int? {
        var size = MemoryLayout<Int32>.size
        var value: Int32 = 0
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
        return Int(value)
    }

    private static func cpuFamily() -> UInt32? {
        var size = MemoryLayout<UInt32>.size
        var value: UInt32 = 0
        guard sysctlbyname("hw.cpufamily", &value, &size, nil, 0) == 0 else { return nil }
        return value
    }

    private static func chipFromFamily() -> String? {
        guard let family = cpuFamily() else { return nil }
        switch family {
        case 0x07a07ddf: return "Apple A12 Bionic"
        case 0x573b5eec: return "Apple A13 Bionic"
        case 0x1b588bb3: return "Apple A14 Bionic"
        case 0xda33d83d: return "Apple A15 Bionic"
        case 0x8765ede7: return "Apple A16 Bionic"
        case 0x2876f5b5: return "Apple A17 Pro"
        case 0x75d4acb9: return "Apple A18"
        case 0x6f5129ac: return "Apple A18 Pro"
        default: return String(format: "Apple CPU (family 0x%08x)", family)
        }
    }

    private static let deviceMap: [String: (name: String, chip: String)] = [
        "i386": ("Simulator", "Simulator"),
        "x86_64": ("Simulator", "Simulator"),
        "arm64": ("Simulator", "Simulator"),
        "iPhone10,1": ("iPhone 8", "Apple A11 Bionic"),
        "iPhone10,4": ("iPhone 8", "Apple A11 Bionic"),
        "iPhone10,2": ("iPhone 8 Plus", "Apple A11 Bionic"),
        "iPhone10,5": ("iPhone 8 Plus", "Apple A11 Bionic"),
        "iPhone10,3": ("iPhone X", "Apple A11 Bionic"),
        "iPhone10,6": ("iPhone X", "Apple A11 Bionic"),
        "iPhone11,2": ("iPhone XS", "Apple A12 Bionic"),
        "iPhone11,4": ("iPhone XS Max", "Apple A12 Bionic"),
        "iPhone11,6": ("iPhone XS Max", "Apple A12 Bionic"),
        "iPhone11,8": ("iPhone XR", "Apple A12 Bionic"),
        "iPhone12,1": ("iPhone 11", "Apple A13 Bionic"),
        "iPhone12,3": ("iPhone 11 Pro", "Apple A13 Bionic"),
        "iPhone12,5": ("iPhone 11 Pro Max", "Apple A13 Bionic"),
        "iPhone12,8": ("iPhone SE (2nd generation)", "Apple A13 Bionic"),
        "iPhone13,1": ("iPhone 12 mini", "Apple A14 Bionic"),
        "iPhone13,2": ("iPhone 12", "Apple A14 Bionic"),
        "iPhone13,3": ("iPhone 12 Pro", "Apple A14 Bionic"),
        "iPhone13,4": ("iPhone 12 Pro Max", "Apple A14 Bionic"),
        "iPhone14,4": ("iPhone 13 mini", "Apple A15 Bionic"),
        "iPhone14,5": ("iPhone 13", "Apple A15 Bionic"),
        "iPhone14,2": ("iPhone 13 Pro", "Apple A15 Bionic"),
        "iPhone14,3": ("iPhone 13 Pro Max", "Apple A15 Bionic"),
        "iPhone14,6": ("iPhone SE (3rd generation)", "Apple A15 Bionic"),
        "iPhone14,7": ("iPhone 14", "Apple A15 Bionic"),
        "iPhone14,8": ("iPhone 14 Plus", "Apple A15 Bionic"),
        "iPhone15,2": ("iPhone 14 Pro", "Apple A16 Bionic"),
        "iPhone15,3": ("iPhone 14 Pro Max", "Apple A16 Bionic"),
        "iPhone15,4": ("iPhone 15", "Apple A16 Bionic"),
        "iPhone15,5": ("iPhone 15 Plus", "Apple A16 Bionic"),
        "iPhone16,1": ("iPhone 15 Pro", "Apple A17 Pro"),
        "iPhone16,2": ("iPhone 15 Pro Max", "Apple A17 Pro"),
        "iPhone17,1": ("iPhone 16 Pro", "Apple A18 Pro"),
        "iPhone17,2": ("iPhone 16 Pro Max", "Apple A18 Pro"),
        "iPhone17,3": ("iPhone 16", "Apple A18"),
        "iPhone17,4": ("iPhone 16 Plus", "Apple A18"),
        "iPhone17,5": ("iPhone 16e", "Apple A18"),
        "iPhone18,1": ("iPhone 17 Pro", "Apple A19 Pro"),
        "iPhone18,2": ("iPhone 17 Pro Max", "Apple A19 Pro"),
        "iPhone18,3": ("iPhone 17", "Apple A19"),
        "iPhone18,4": ("iPhone 17 Air", "Apple A19"),
        "iPad13,18": ("iPad (10th generation)", "Apple A14 Bionic"),
        "iPad13,19": ("iPad (10th generation)", "Apple A14 Bionic"),
        "iPad14,1": ("iPad mini (6th generation)", "Apple A15 Bionic"),
        "iPad14,2": ("iPad mini (6th generation)", "Apple A15 Bionic"),
        "iPad14,3": ("iPad Pro 11-inch (4th generation)", "Apple M2"),
        "iPad14,4": ("iPad Pro 11-inch (4th generation)", "Apple M2"),
        "iPad14,5": ("iPad Pro 12.9-inch (6th generation)", "Apple M2"),
        "iPad14,6": ("iPad Pro 12.9-inch (6th generation)", "Apple M2"),
        "iPad14,8": ("iPad Air (6th generation)", "Apple M2"),
        "iPad14,9": ("iPad Air (6th generation)", "Apple M2"),
        "iPad14,10": ("iPad Air 13-inch (M2)", "Apple M2"),
        "iPad14,11": ("iPad Air 13-inch (M2)", "Apple M2"),
        "iPad16,1": ("iPad mini (A17 Pro)", "Apple A17 Pro"),
        "iPad16,2": ("iPad mini (A17 Pro)", "Apple A17 Pro"),
        "iPad16,3": ("iPad Pro 11-inch (M4)", "Apple M4"),
        "iPad16,4": ("iPad Pro 11-inch (M4)", "Apple M4"),
        "iPad16,5": ("iPad Pro 13-inch (M4)", "Apple M4"),
        "iPad16,6": ("iPad Pro 13-inch (M4)", "Apple M4"),
    ]
}
