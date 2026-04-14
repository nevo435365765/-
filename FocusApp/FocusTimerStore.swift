import Foundation
import Combine

final class FocusTimerStore: ObservableObject {
    @Published var focusDurationMinutes: Int = 25
    @Published var breakDurationMinutes: Int = 5

    @Published private(set) var timeRemaining: Int = 25 * 60
    @Published private(set) var isRunning = false
    @Published private(set) var isBreak = false
    @Published private(set) var completedSessions = 0
    @Published private(set) var todayFocusedSeconds = 0
    @Published private(set) var history: [FocusSession] = []

    private var ticker: AnyCancellable?
    private let calendar = Calendar.current

    init() {
        loadFromDefaults()
        resetTimer()
    }

    deinit {
        ticker?.cancel()
    }

    func startPauseTapped() {
        isRunning ? pause() : start()
    }

    func resetTimer() {
        pause()
        timeRemaining = currentDuration * 60
    }

    func skipToNextPhase() {
        pause()
        finishPhase(manuallySkipped: true)
    }

    var progress: Double {
        let full = Double(currentDuration * 60)
        guard full > 0 else { return 0 }
        return 1 - (Double(timeRemaining) / full)
    }

    var phaseTitle: String {
        isBreak ? "הפסקה" : "פוקוס"
    }

    var currentDuration: Int {
        isBreak ? breakDurationMinutes : focusDurationMinutes
    }

    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var todayHoursText: String {
        let hours = Double(todayFocusedSeconds) / 3600
        return String(format: "%.1f שעות", hours)
    }

    func applyNewDurations() {
        let normalizedFocus = max(1, min(focusDurationMinutes, 120))
        let normalizedBreak = max(1, min(breakDurationMinutes, 60))
        focusDurationMinutes = normalizedFocus
        breakDurationMinutes = normalizedBreak

        if !isRunning {
            timeRemaining = currentDuration * 60
        }
    }

    private func start() {
        guard !isRunning else { return }
        isRunning = true

        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func pause() {
        isRunning = false
        ticker?.cancel()
        ticker = nil
    }

    private func tick() {
        guard timeRemaining > 0 else {
            finishPhase(manuallySkipped: false)
            return
        }

        timeRemaining -= 1
    }

    private func finishPhase(manuallySkipped: Bool) {
        if !isBreak && !manuallySkipped {
            let sessionDuration = focusDurationMinutes * 60
            completedSessions += 1
            todayFocusedSeconds += sessionDuration
            history.insert(FocusSession(durationInSeconds: sessionDuration), at: 0)
            trimHistoryIfNeeded()
            saveToDefaults()
        }

        isBreak.toggle()
        timeRemaining = currentDuration * 60

        if isRunning {
            // Continue automatically into next phase.
            start()
        }
    }

    private func trimHistoryIfNeeded() {
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
    }

    private func loadFromDefaults() {
        let defaults = UserDefaults.standard
        focusDurationMinutes = defaults.integer(forKey: Keys.focusDuration)
        breakDurationMinutes = defaults.integer(forKey: Keys.breakDuration)
        completedSessions = defaults.integer(forKey: Keys.completedSessions)

        let storedDay = defaults.object(forKey: Keys.trackedDay) as? Date
        let storedSeconds = defaults.integer(forKey: Keys.todayFocusedSeconds)

        if let storedDay, calendar.isDateInToday(storedDay) {
            todayFocusedSeconds = storedSeconds
        } else {
            todayFocusedSeconds = 0
        }

        if let historyData = defaults.data(forKey: Keys.history),
           let decoded = try? JSONDecoder().decode([FocusSession].self, from: historyData) {
            history = decoded
        }

        if focusDurationMinutes == 0 { focusDurationMinutes = 25 }
        if breakDurationMinutes == 0 { breakDurationMinutes = 5 }
    }

    private func saveToDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(focusDurationMinutes, forKey: Keys.focusDuration)
        defaults.set(breakDurationMinutes, forKey: Keys.breakDuration)
        defaults.set(completedSessions, forKey: Keys.completedSessions)
        defaults.set(todayFocusedSeconds, forKey: Keys.todayFocusedSeconds)
        defaults.set(Date(), forKey: Keys.trackedDay)

        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: Keys.history)
        }
    }

    private enum Keys {
        static let focusDuration = "focus.duration"
        static let breakDuration = "break.duration"
        static let completedSessions = "focus.sessions.count"
        static let todayFocusedSeconds = "focus.today.seconds"
        static let trackedDay = "focus.today.date"
        static let history = "focus.history"
    }
}
