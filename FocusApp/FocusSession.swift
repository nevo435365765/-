import Foundation

struct FocusSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let durationInSeconds: Int

    init(id: UUID = UUID(), date: Date = .now, durationInSeconds: Int) {
        self.id = id
        self.date = date
        self.durationInSeconds = durationInSeconds
    }
}
