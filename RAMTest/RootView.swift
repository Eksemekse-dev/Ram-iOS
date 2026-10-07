import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TestTabView()
                .tabItem {
                    Label("Test", systemImage: "memorychip")
                }

            ResultTabView()
                .tabItem {
                    Label("Wynik", systemImage: "chart.bar")
                }
        }
    }
}

struct TestTabView: View {
    @EnvironmentObject private var filler: MemoryFiller

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Zapchane RAM")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(ByteCountFormatter.string(fromByteCount: Int64(clamping: filler.filledBytes), countStyle: .memory))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
            }

            if filler.lastCrashBytes > 0 {
                Text("Przed ostatnim wyłączeniem: \(ByteCountFormatter.string(fromByteCount: Int64(clamping: filler.lastCrashBytes), countStyle: .memory))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                filler.startTest()
            } label: {
                Text(filler.isRunning ? "Test działa…" : "Test")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(filler.isRunning)
            .padding(.horizontal, 32)

            Text("Przycisk zapycha pamięć aż system wyłączy aplikację. Postęp zapisuje się co 1 sekundę.")
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
            Text("Ostatni zapis")
                .font(.title2.weight(.bold))

            LabeledContent("RAM przed wyłączeniem") {
                Text(filler.lastCrashBytes == 0
                     ? "brak"
                     : ByteCountFormatter.string(fromByteCount: Int64(clamping: filler.lastCrashBytes), countStyle: .memory))
            }

            LabeledContent("Aktualnie zapchane") {
                Text(ByteCountFormatter.string(fromByteCount: Int64(clamping: filler.filledBytes), countStyle: .memory))
            }

            LabeledContent("Ostatni zapis do pliku") {
                if let date = filler.lastSavedAt {
                    Text(date, style: .time)
                } else {
                    Text("jeszcze nie zapisano")
                }
            }

            Spacer()
        }
        .padding()
    }
}
