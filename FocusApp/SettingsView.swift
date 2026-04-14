import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var timerStore: FocusTimerStore
    @Environment(\.dismiss) private var dismiss

    @State private var focusMinutes = 25.0
    @State private var breakMinutes = 5.0

    var body: some View {
        NavigationStack {
            Form {
                Section("זמני עבודה") {
                    VStack(alignment: .leading) {
                        Text("משך פוקוס: \(Int(focusMinutes)) דקות")
                        Slider(value: $focusMinutes, in: 1...120, step: 1)
                    }

                    VStack(alignment: .leading) {
                        Text("משך הפסקה: \(Int(breakMinutes)) דקות")
                        Slider(value: $breakMinutes, in: 1...60, step: 1)
                    }
                }

                Section {
                    Button("שמור") {
                        timerStore.focusDurationMinutes = Int(focusMinutes)
                        timerStore.breakDurationMinutes = Int(breakMinutes)
                        timerStore.applyNewDurations()
                        dismiss()
                    }
                }
            }
            .navigationTitle("הגדרות")
            .onAppear {
                focusMinutes = Double(timerStore.focusDurationMinutes)
                breakMinutes = Double(timerStore.breakDurationMinutes)
            }
        }
    }
}
