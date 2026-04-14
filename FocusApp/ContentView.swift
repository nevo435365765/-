import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var timerStore: FocusTimerStore
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(timerStore.phaseTitle)
                    .font(.largeTitle.bold())

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 16)

                    Circle()
                        .trim(from: 0, to: timerStore.progress)
                        .stroke(timerStore.isBreak ? .green : .blue,
                                style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.2), value: timerStore.progress)

                    Text(timerStore.formattedTime)
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
                .frame(width: 260, height: 260)
                .padding(.vertical, 12)

                HStack(spacing: 16) {
                    Button(timerStore.isRunning ? "עצור" : "התחל") {
                        timerStore.startPauseTapped()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("דלג") {
                        timerStore.skipToNextPhase()
                    }
                    .buttonStyle(.bordered)

                    Button("איפוס") {
                        timerStore.resetTimer()
                    }
                    .buttonStyle(.bordered)
                }

                statsSection
                historySection

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("FocusFlow")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("הגדרות", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(timerStore)
            }
        }
    }

    private var statsSection: some View {
        HStack {
            StatCard(title: "סשנים", value: "\(timerStore.completedSessions)", icon: "checkmark.circle")
            StatCard(title: "היום", value: timerStore.todayHoursText, icon: "clock")
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("היסטוריה")
                .font(.headline)

            if timerStore.history.isEmpty {
                Text("עדיין אין סשנים שהושלמו.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(timerStore.history.prefix(5)) { session in
                    HStack {
                        Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        Spacer()
                        Text("\(session.durationInSeconds / 60) דק׳")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
        .environmentObject(FocusTimerStore())
}
