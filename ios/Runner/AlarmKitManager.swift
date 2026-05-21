import Foundation
import UserNotifications
import AVFoundation

/// AlarmKitManager: iOS'ta uygulamanın kapalı olduğu/arka planda olduğu durumlar için
/// native bildirim yöneticisini kullanarak alarm zamanlamasını garanti altına alır.
@available(iOS 10.0, *)
class AlarmKitManager {
    static let shared = AlarmKitManager()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        // Ses, uyarı ve kritik bildirim izinlerini istiyoruz.
        center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if let error = error {
                print("Alarm Notification Authorization Error: \(error.localizedDescription)")
            }
            completion(granted)
        }
    }
    
    func scheduleAlarm(id: String, hour: Int, minute: Int, title: String, repeats: [Int]) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Uyanma vakti!"
        // Özel bir ses dosyanız varsa burada belirtebilirsiniz. Yoksa varsayılan alarm sesini çalar.
        content.sound = UNNotificationSound.defaultCritical
        
        // Zamanlama bileşenleri
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // Eğer her gün tekrar etmesi isteniyorsa repeats: true yapılır
        let isDaily = repeats.count > 0 
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: isDaily)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule native iOS alarm: \(error.localizedDescription)")
            } else {
                print("Native iOS Alarm scheduled successfully for \(hour):\(minute) (ID: \(id))")
            }
        }
    }
    
    func removeAlarm(id: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
        print("Native iOS Alarm \(id) cancelled")
    }
}
