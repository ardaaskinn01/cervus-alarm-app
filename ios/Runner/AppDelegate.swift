import Flutter
import UIKit
import UserNotifications
import alarm

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let alarmKitChannel = FlutterMethodChannel(name: "com.app/alarm_kit",
                                              binaryMessenger: controller.binaryMessenger)
    
    alarmKitChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if #available(iOS 17.0, *) {
          switch call.method {
          case "requestAuthorization":
              AlarmKitManager.shared.requestAuthorization { success in
                  result(success)
              }
          case "scheduleAlarm":
              if let args = call.arguments as? [String: Any],
                 let id = args["id"] as? String,
                 let hour = args["hour"] as? Int,
                 let minute = args["minute"] as? Int,
                 let title = args["title"] as? String,
                 let repeats = args["repeats"] as? [Int] {
                  AlarmKitManager.shared.scheduleAlarm(id: id, hour: hour, minute: minute, title: title, repeats: repeats)
                  result(true)
              } else {
                  result(FlutterError(code: "INVALID_ARGS", message: "Arguments missing", details: nil))
              }
          case "stopAlarm":
              if let args = call.arguments as? [String: Any],
                 let id = args["id"] as? String {
                  AlarmKitManager.shared.removeAlarm(id: id)
                  result(true)
              } else {
                  result(FlutterError(code: "INVALID_ARGS", message: "ID missing", details: nil))
              }
          default:
              result(FlutterMethodNotImplemented)
          }
      } else {
          result(FlutterError(code: "UNSUPPORTED_IOS_VERSION", message: "AlarmKit requires iOS 17+", details: nil))
      }
    })

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    SwiftAlarmPlugin.registerBackgroundTasks()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
