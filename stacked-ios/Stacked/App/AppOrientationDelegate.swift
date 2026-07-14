import UIKit
import UserNotifications

/// Bloqueia rotação no iPhone — só retrato.
final class AppOrientationDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return true
  }

  func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    switch UIDevice.current.userInterfaceIdiom {
    case .phone:
      return .portrait
    default:
      return [.portrait, .portraitUpsideDown]
    }
  }
}

// Sem delegate, o iOS entrega a notificação mas não mostra banner/som com o app em primeiro plano.
extension AppOrientationDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    rearmDailySummaryIfNeeded(notification)
    completionHandler([.banner, .sound, .badge])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    rearmDailySummaryIfNeeded(response.notification)
    completionHandler()
  }

  private func rearmDailySummaryIfNeeded(_ notification: UNNotification) {
    guard notification.request.identifier == NotificationService.dailySummaryIdentifier else { return }
    _Concurrency.Task { @MainActor in
      await NotificationService.shared.scheduleDailySummaryIfNeeded()
    }
  }
}
