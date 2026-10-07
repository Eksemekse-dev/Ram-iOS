import Foundation
import Combine

final class MemoryFiller: ObservableObject {
    @Published private(set) var filledBytes: UInt64 = 0
    @Published private(set) var lastCrashBytes: UInt64 = 0
    @Published private(set) var isRunning = false
    @Published private(set) var lastSavedAt: Date?

    private var chunks: [UnsafeMutableRawPointer] = []
    private var chunkSizes: [Int] = []
    private let queue = DispatchQueue(label: "pl.ramtest.filler", qos: .userInitiated)
    private var persistTimer: Timer?
    private var runningFlag = false
    private let persistURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        persistURL = docs.appendingPathComponent("ram_progress.json")
        if let snapshot = Self.load(from: persistURL) {
            lastCrashBytes = snapshot.bytes
            filledBytes = snapshot.bytes
            lastSavedAt = snapshot.updatedAt
        }
    }

    deinit {
        persistTimer?.invalidate()
        freeAll()
    }

    func startTest() {
        queue.async { [weak self] in
            guard let self, !self.runningFlag else { return }
            self.runningFlag = true
            DispatchQueue.main.async {
                self.filledBytes = 0
                self.isRunning = true
            }
            self.fillLoop()
        }

        DispatchQueue.main.async { [weak self] in
            self?.startPersistTimer()
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
        chunkSizes.append(bytes)
        let total = chunks.enumerated().reduce(UInt64(0)) { sum, item in
            sum + UInt64(chunkSizes[item.offset])
        }
        DispatchQueue.main.async { [weak self] in
            self?.filledBytes = total
        }
        return true
    }

    private func startPersistTimer() {
        persistTimer?.invalidate()
        persistNow()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.persistNow()
        }
        RunLoop.main.add(timer, forMode: .common)
        persistTimer = timer
    }

    private func persistNow() {
        let snapshot = ProgressSnapshot(bytes: filledBytes, updatedAt: Date())
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(snapshot)
            try data.write(to: persistURL, options: .atomic)
            lastSavedAt = snapshot.updatedAt
        } catch {
            // Keep filling even if a single write fails.
        }
    }

    private func freeAll() {
        for pointer in chunks {
            free(pointer)
        }
        chunks.removeAll()
        chunkSizes.removeAll()
    }

    private static func load(from url: URL) -> ProgressSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ProgressSnapshot.self, from: data)
    }
}

private struct ProgressSnapshot: Codable {
    var bytes: UInt64
    var updatedAt: Date
}
