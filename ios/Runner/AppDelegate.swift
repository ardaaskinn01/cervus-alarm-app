import Flutter
import UIKit
import UserNotifications
import MediaPlayer
import alarm

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var launchedAlarmId: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Uygulama LOCAL BİLDİRİMLE mi açıldı kontrol et
    // iOS 10+ için doğru yol: UNNotification kullanıcı bilgisi
    if let notification = launchOptions?[.remoteNotification] as? [String: Any],
       let alarmId = notification["alarmId"] as? String {
        launchedAlarmId = alarmId
    }
    
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let alarmKitChannel = FlutterMethodChannel(
        name: "com.app/alarm_kit",
        binaryMessenger: controller.binaryMessenger
    )
    
    alarmKitChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      // getLaunchedAlarmId: iOS versiyonundan bağımsız her zaman çalışır
      if call.method == "getLaunchedAlarmId" {
          result(self?.launchedAlarmId)
          self?.launchedAlarmId = nil // Bir kez alındıktan sonra temizle
          return
      }
      
      // *** ÖNEMLİ: iOS 17 değil, iOS 12.0 yeterlidir (AlarmKitManager @available(iOS 12.0))
      if #available(iOS 12.0, *) {
          switch call.method {
          
          case "requestAuthorization":
              AlarmKitManager.shared.requestAuthorization { success in
                  result(success)
              }
          
          // Eski scheduleAlarm (geriye dönük uyumluluk için tutuldu)
          case "scheduleAlarm":
              if let args = call.arguments as? [String: Any],
                 let id = args["id"] as? String,
                 let hour = args["hour"] as? Int,
                 let minute = args["minute"] as? Int,
                 let title = args["title"] as? String,
                 let repeats = args["repeats"] as? [Int] {
                  let sound = args["sound"] as? String ?? "hard_alarm.mp3"
                  AlarmKitManager.shared.scheduleAlarm(
                      id: id, hour: hour, minute: minute,
                      title: title, repeats: repeats, sound: sound
                  )
                  result(true)
              } else {
                  result(FlutterError(code: "INVALID_ARGS", message: "Arguments missing for scheduleAlarm", details: nil))
              }
          
          // YENİ scheduleAlarmChain - fireDate ile kesin zamanlama
          case "scheduleAlarmChain":
              if let args = call.arguments as? [String: Any],
                 let id = args["id"] as? String,
                 let fireDateEpoch = args["fireDate"] as? Double,
                 let title = args["title"] as? String {
                  let sound = args["sound"] as? String ?? "hard_alarm.mp3"
                  let count = args["count"] as? Int ?? 20
                  let intervalSeconds = args["intervalSeconds"] as? Int ?? 15
                  
                  // epoch saniyesinden Date objesine çevir
                  let fireDate = Date(timeIntervalSince1970: fireDateEpoch)
                  
                  AlarmKitManager.shared.scheduleAlarmChain(
                      id: id,
                      fireDate: fireDate,
                      title: title,
                      sound: sound,
                      count: count,
                      intervalSeconds: intervalSeconds
                  )
                  result(true)
              } else {
                  result(FlutterError(code: "INVALID_ARGS", message: "Arguments missing for scheduleAlarmChain", details: nil))
              }
          
          case "stopAlarm":
              if let args = call.arguments as? [String: Any],
                 let id = args["id"] as? String {
                  AlarmKitManager.shared.removeAlarm(id: id)
                  result(true)
              } else {
                  result(FlutterError(code: "INVALID_ARGS", message: "ID missing for stopAlarm", details: nil))
              }
          
          case "setSystemVolume":
              if let args = call.arguments as? [String: Any],
                 let volume = args["volume"] as? Float {
                  AlarmKitManager.shared.setSystemVolume(volume)
                  result(true)
              } else {
                  result(FlutterError(code: "INVALID_ARGS", message: "Volume missing", details: nil))
              }
          
          case "startVolumeEnforcement":
              let volume = (call.arguments as? [String: Any])?["volume"] as? Float ?? 1.0
              AlarmKitManager.shared.startVolumeEnforcement(volume: volume)
              result(true)
          
          case "stopVolumeEnforcement":
              AlarmKitManager.shared.stopVolumeEnforcement()
              result(true)
          
          default:
              result(FlutterMethodNotImplemented)
          }
      } else {
          // iOS 12'den eski sistemler için sessizce devam et
          result(nil)
      }
    })

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    SwiftAlarmPlugin.registerBackgroundTasks()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Cihazın sistem sesini zorla değiştiren fonksiyon (iOS için MPVolumeView hilesi)
  private func setSystemVolume(_ volume: Float) {
    AlarmKitManager.shared.setSystemVolume(volume)
  }

  // Bildirime tıklandığında (Uygulama açık/arkaplanda/kapalı iken)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    if let alarmId = userInfo["alarmId"] as? String {
        // Uygulama kapalıyken bildirime tıklandı - launchedAlarmId'yi güncelle
        // Flutter tarafı hazır olana kadar burada saklıyoruz
        if launchedAlarmId == nil {
            launchedAlarmId = alarmId
        }
        
        // Uygulama zaten açıksa doğrudan Flutter'a bildir
        let controller = window?.rootViewController as? FlutterViewController
        if let messenger = controller?.binaryMessenger {
            let alarmKitChannel = FlutterMethodChannel(
                name: "com.app/alarm_kit",
                binaryMessenger: messenger
            )
            alarmKitChannel.invokeMethod("onAlarmTapped", arguments: alarmId)
        }
    }
    completionHandler()
  }
  
  // Uygulama açıkken gelen bildirimi göster (ön planda)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Uygulama açıkken de alarm bildirimi ses + banner ile gösterilsin
    if #available(iOS 14.0, *) {
        completionHandler([.banner, .sound, .badge])
    } else {
        completionHandler([.alert, .sound, .badge])
    }
  }
}
