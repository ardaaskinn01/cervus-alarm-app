import Foundation
import UserNotifications
import AVFoundation

/// AlarmKitManager: Israrcı ve Yüksek Sesli alarm sistemi.
/// iOS'ta uygulama kapalıyken donanım sesini açamazsınız ancak 
/// "Critical Sound" özelliği ile donanım sesi kısık olsa bile 
/// bildirimin sesini %100 (Max Volume) çalmasını tetikleyebilirsiniz.
@available(iOS 12.0, *)
class AlarmKitManager {
    static let shared = AlarmKitManager()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        // CriticalAlert izni telefon sessizdeyken bile çalmasını sağlar.
        center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            completion(granted)
        }
    }
    
    func scheduleAlarm(id: String, hour: Int, minute: Int, title: String, repeats: [Int], sound: String) {
        removeAlarm(id: id)
        
        // 15 saniye arayla 20 bildirim (Toplam 5 dk döngü)
        for i in 0...19 {
            let notificationId = i == 0 ? id : "\(id)_\(i)"
            let delayInSeconds = i * 15
            scheduleIndividualNotification(id: notificationId, hour: hour, minute: minute, second: delayInSeconds, title: title, sound: sound, repeats: repeats)
        }
    }
    
    private func scheduleIndividualNotification(id: String, hour: Int, minute: Int, second: Int, title: String, sound: String, repeats: [Int]) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "⏰ UYANMA VAKTİ! (Durdurmak için dokunun)"
        
        let baseId = id.components(separatedBy: "_").first ?? id
        content.userInfo = ["alarmId": baseId]
        
        // CRITICAL SOUND: withAudioVolume: 1.0 değeri telefonun uyarı sesi kısık olsa bile en yüksekten çalmasını sağlar.
        content.sound = UNNotificationSound.criticalSoundNamed(UNNotificationSoundName(rawValue: sound), withAudioVolume: 1.0)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second
        
        let isDaily = repeats.count > 0 
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: isDaily)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Persistent Alarm Error (\(id)): \(error.localizedDescription)")
            }
        }
    }
    
    func removeAlarm(id: String) {
        let center = UNUserNotificationCenter.current()
        var idsToRemove = [id]
        for i in 1...25 {
            idsToRemove.append("\(id)_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        center.removeDeliveredNotifications(withIdentifiers: idsToRemove)
    }
}
