import Foundation
import Combine

final class MemoryFiller: ObservableObject {
    @Published private(set) var filledBytes: UInt64 = 0
    @Published private(set) var lastCrashBytes: UInt64 = 0
    @Published private(set) var isRunning = false
    @Published var showLastResult = false

    private var chunks: [UnsafeMutableRawPointer] = []
    private var totalBytes: UInt64 = 0
    private let queue = DispatchQueue(label: "pl.ramtest.filler", qos: .userInitiated)
    private var runningFlag = false
    private let persistURL: URL
    private var persistHandle: FileHandle?

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        persistURL = docs.appendingPathComponent("ram_progress.bin")
        let saved = Self.load(from: persistURL)
        lastCrashBytes = saved
        filledBytes = saved
        showLastResult = saved > 0
    }

    deinit {
        try? persistHandle?.close()
        freeAll()
    }

    func startTest() {
        queue.async { [weak self] in
            guard let self, !self.runningFlag else { return }
            self.runningFlag = true
            self.totalBytes = 0
            self.openPersistHandle()
            self.persist(0)
            DispatchQueue.main.async {
                self.filledBytes = 0
                self.isRunning = true
            }
            self.fillLoop()
        }
    }

    private func fillLoop() {
        var nextSize = 16 * 1024 * 1024
        while runningFlag {
            if allocate(bytes: nextSize) {
                continue
            }
            if nextSize > 1024 * 1024 {
                nextSize = 1024 * 1024
                continue
            }
            if nextSize > 64 * 1024 {
                nextSize = 64 * 1024
                continue
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
    }

    private func allocate(bytes: Int) -> Bool {
        guard let pointer = malloc(bytes) else { return false }
        memset(pointer, 0xA5, bytes)
        chunks.append(pointer)
        totalBytes += UInt64(bytes)
        persist(totalBytes)
        let total = totalBytes
        DispatchQueue.main.async { [weak self] in
            self?.filledBytes = total
        }
        return true
    }

    private func openPersistHandle() {
        try? persistHandle?.close()
        persistHandle = nil
        if !FileManager.default.fileExists(atPath: persistURL.path) {
            FileManager.default.createFile(atPath: persistURL.path, contents: Data(count: 8))
        }
        persistHandle = try? FileHandle(forWritingTo: persistURL)
    }

    private func persist(_ bytes: UInt64) {
        var value = bytes.littleEndian
        let data = withUnsafeBytes(of: &value) { Data($0) }
        do {
            if let handle = persistHandle {
                try handle.seek(toOffset: 0)
                try handle.write(contentsOf: data)
                try handle.synchronize()
            } else {
                try data.write(to: persistURL, options: .atomic)
            }
        } catch {
            try? data.write(to: persistURL, options: .atomic)
        }
    }

    private func freeAll() {
        for pointer in chunks {
            free(pointer)
        }
        chunks.removeAll()
    }

    private static func load(from url: URL) -> UInt64 {
        guard let data = try? Data(contentsOf: url), data.count >= 8 else { return 0 }
        return data.prefix(8).withUnsafeBytes { raw in
            UInt64(littleEndian: raw.load(as: UInt64.self))
        }
    }
}
