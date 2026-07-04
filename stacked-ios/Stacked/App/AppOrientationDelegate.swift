import UIKit

/// Bloqueia rotação no iPhone — só retrato.
final class AppOrientationDelegate: NSObject, UIApplicationDelegate {
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
