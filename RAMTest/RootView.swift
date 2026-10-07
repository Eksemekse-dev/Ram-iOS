import SwiftUI

struct RootView: View {
    @EnvironmentObject private var filler: MemoryFiller

    var body: some View {
        TabView {
            TestTabView()
                .tabItem {
                    Label("Test", systemImage: "memorychip")
                }

            ResultTabView()
                .tabItem {
                    Label("Result", systemImage: "chart.bar")
                }
        }
        .alert("Last RAM result", isPresented: $filler.showLastResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The app filled \(formattedBytes(filler.lastCrashBytes)) before it was killed.")
        }
    }
}

struct TestTabView: View {
    @EnvironmentObject private var filler: MemoryFiller

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Filled RAM")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(formattedBytes(filler.filledBytes))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
            }

            Button {
                filler.startTest()
            } label: {
                Text(filler.isRunning ? "Test running…" : "Test")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(filler.isRunning)
            .padding(.horizontal, 32)

            Text("The Test button fills memory until the system kills the app.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }
}

struct ResultTabView: View {
    @EnvironmentObject private var filler: MemoryFiller

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last result")
                .font(.title2.weight(.bold))

            LabeledContent("RAM before exit") {
                Text(filler.lastCrashBytes == 0 ? "none" : formattedBytes(filler.lastCrashBytes))
            }

            LabeledContent("Currently filled") {
                Text(formattedBytes(filler.filledBytes))
            }

            Spacer()
        }
        .padding()
    }
}

func formattedBytes(_ bytes: UInt64) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(clamping: bytes), countStyle: .memory)
}
