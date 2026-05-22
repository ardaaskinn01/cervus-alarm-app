import Foundation
import UserNotifications
import AVFoundation

/// AlarmKitManager: Israrcı alarm çalma sistemi.
/// iOS'ta bildirim sesleri döngüye girmediği için arka arkaya (successive)
/// 10 saniye arayla 6 adet bildirim planlayarak toplamda 1 dakikalık 
/// kesintisiz çalma döngüsü sağlar.
@available(iOS 10.0, *)
class AlarmKitManager {
    static let shared = AlarmKitManager()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            completion(granted)
        }
    }
    
    func scheduleAlarm(id: String, hour: Int, minute: Int, title: String, repeats: [Int], sound: String) {
        let center = UNUserNotificationCenter.current()
        
        // Önce bu ID ile başlayan tüm eski bildirimleri temizle
        removeAlarm(id: id)
        
        // 10 saniye arayla 6 adet bildirim planla (Toplam 60 saniye boyunca "susmayan" alarm)
        for i in 0...5 {
            let notificationId = i == 0 ? id : "\(id)_\(i)"
            let delayInSeconds = i * 10
            scheduleIndividualNotification(id: notificationId, hour: hour, minute: minute, second: delayInSeconds, title: title, sound: sound, repeats: repeats)
        }
    }
    
    private func scheduleIndividualNotification(id: String, hour: Int, minute: Int, second: Int, title: String, sound: String, repeats: [Int]) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "⏰ UYANMA VAKTİ! (Durdurmak için dokunun)"
        
        // Ana ID'yi userInfo'da saklıyoruz ki herhangi bir yedek bildirime tıklansa dahi ana alarm açılsın
        let baseId = id.components(separatedBy: "_").first ?? id
        content.userInfo = ["alarmId": baseId]
        
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
        
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
        
        // Tüm olası yedek ID'leri temizle (i=0..10 arası güvenli olsun)
        var idsToRemove = [id]
        for i in 1...10 {
            idsToRemove.append("\(id)_\(i)")
        }
        
        center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        center.removeDeliveredNotifications(withIdentifiers: idsToRemove)
        print("Persistent Alarm \(id) cleanup completed.")
    }
}
