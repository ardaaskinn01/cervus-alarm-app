import Foundation
import AlarmKit
import AppIntents

@available(iOS 17.0, *)
class AlarmKitManager {
    static let shared = AlarmKitManager()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let success = try await AlarmManager.shared.requestAuthorization()
                completion(success)
            } catch {
                print("AlarmKit Authorization Error: \(error)")
                completion(false)
            }
        }
    }
    
    func scheduleAlarm(id: String, hour: Int, minute: Int, title: String, repeats: [Int]) {
        Task {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            // AlarmKit uses Alarm.Schedule for timing
            let schedule = Alarm.Schedule.daily(at: dateComponents)
            
            let configuration = AlarmConfiguration(
                title: title,
                body: "Uyanma vakti!",
                sound: .default,
                schedule: schedule
            )
            
            do {
                try await AlarmManager.shared.schedule(id: id, configuration: configuration)
                print("AlarmKit: Alarm scheduled successfully for \(hour):\(minute)")
            } catch {
                print("AlarmKit: Failed to schedule alarm: \(error)")
            }
        }
    }
    
    func removeAlarm(id: String) {
        Task {
            await AlarmManager.shared.cancel(id: id)
            print("AlarmKit: Alarm \(id) cancelled")
        }
    }
}
