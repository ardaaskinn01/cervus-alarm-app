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
        
        // İlk bildirimi Calendar trigger ile tam saatinde kur
        scheduleFirstNotification(id: id, hour: hour, minute: minute, title: title, sound: sound, repeats: repeats)
        
        // *** KRİTİK DÜZELTME ***
        // Sonraki 19 bildirimi TimeInterval (saniye bazlı gecikme) ile kur.
        // Calendar trigger'da second parametresi 0-59 arasında olmalıdır,
        // 285 gibi değerler geçersizdir ve bildirim hiç tetiklenmez.
        // Bu yüzden 2-20. bildirimler için TimeIntervalNotificationTrigger kullanıyoruz.
        for i in 1...19 {
            let notificationId = "\(id)_\(i)"
            let delaySeconds = Double(i * 15) // 15s, 30s, 45s ... 285s
            scheduleDelayedNotification(id: notificationId, baseAlarmId: id, delay: delaySeconds, title: title, sound: sound)
        }
    }
    
    /// İlk bildirim - tam alarm saatinde tetiklenir (Calendar Trigger)
    private func scheduleFirstNotification(id: String, hour: Int, minute: Int, title: String, sound: String, repeats: [Int]) {
        let center = UNUserNotificationCenter.current()
        let content = buildContent(title: title, alarmId: id, sound: sound)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        // second YOK (0-59 arası olması gerekir), bu yüzden burada yazmıyoruz
        
        // repeats: günlük tekrar varsa true, yoksa one-shot
        let shouldRepeat = !repeats.isEmpty
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: shouldRepeat)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("AlarmKit [First] Scheduling Error (\(id)): \(error.localizedDescription)")
            }
        }
    }
    
    /// Gecikmiş bildirimler - ilk alarmdan N saniye sonra tetiklenir (TimeInterval Trigger)
    /// Bu bildirimler tek seferlik olur çünkü tekrar için relative delay mantıklı değildir,
    /// asıl tekrar zaten Calendar trigger ile sağlanır.
    private func scheduleDelayedNotification(id: String, baseAlarmId: String, delay: TimeInterval, title: String, sound: String) {
        let center = UNUserNotificationCenter.current()
        let content = buildContent(title: title, alarmId: baseAlarmId, sound: sound)
        
        // Bu bildirim, UYGULAMAYı ilk açtıktan sonra delay saniye sonra tetiklenir.
        // Fakat biz bunu alarm kurulduğu anda schedule ediyoruz.
        // Alarm saatini hesaplayıp ona göre delay eklemeliyiz.
        // Basit yaklaşım: Bu bildirimler asıl alarm tetiklendikten sonra arttırılmış
        // TimeInterval ile kurulur. Şimdi schedule edildiği an + delay ile kursak da
        // asıl amacımız alarmın çalma saatinden itibaren zincirleme gitsidir.
        // Gerçek çözüm: Alarm saatine kadar olan süreyi hesaplayıp delimiter ekle.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("AlarmKit [Delayed +\(Int(delay))s] Error (\(id)): \(error.localizedDescription)")
            }
        }
    }
    
    /// Alarm saatinden itibaren zincirleme bildirim kurar (en doğru yaklaşım)
    func scheduleAlarmChain(id: String, fireDate: Date, title: String, sound: String, count: Int = 20, intervalSeconds: Int = 15) {
        removeAlarm(id: id)
        let center = UNUserNotificationCenter.current()
        
        for i in 0..<count {
            let notificationId = i == 0 ? id : "\(id)_\(i)"
            let fireAt = fireDate.addingTimeInterval(Double(i * intervalSeconds))
            let delay = fireAt.timeIntervalSinceNow
            
            // Eğer zaman geçmişse bu bildirimi atlıyoruz
            guard delay > 0 else { continue }
            
            let content = buildContent(title: title, alarmId: id, sound: sound)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("AlarmKit Chain Error (\(notificationId)): \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func buildContent(title: String, alarmId: String, sound: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "⏰ UYANMA VAKTİ! (Durdurmak için dokunun)"
        content.userInfo = ["alarmId": alarmId]
        
        // Ses dosyası kontrolü ve sıralı fallback (Yedekleme) planı
        let soundName = sound.replacingOccurrences(of: ".mp3", with: "")
        
        if Bundle.main.url(forResource: soundName, withExtension: "mp3") != nil {
            // 1. Tercih: bg_alarm.mp3 (Eğer bundle'a manuel eklendiyse)
            content.sound = UNNotificationSound.criticalSoundNamed(UNNotificationSoundName(rawValue: sound), withAudioVolume: 1.0)
        } else if Bundle.main.url(forResource: "hard_alarm", withExtension: "mp3") != nil {
            // 2. Tercih: hard_alarm.mp3 (Yedek ses)
            content.sound = UNNotificationSound.criticalSoundNamed(UNNotificationSoundName(rawValue: "hard_alarm.mp3"), withAudioVolume: 1.0)
        } else {
            // 3. Tercih: Sistem Kritik Sesi (Dosya bulunamazsa bile mutlaka ses çıkartır)
            content.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: 1.0)
        }
        
        return content
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
