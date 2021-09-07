import Flutter
import UIKit
import AAILivenessSDK

public class SwiftLivenessPlugin: NSObject, FlutterPlugin {
    private static let CHANNEL_NAME = "guardian_liveness"

      private let IS_DEVICE_SUPPORT_LIVENESS = "isDeviceSupportLiveness"
      private let INIT_LIVENESS = "initLiveness"
      private let DETECT_LIVENESS = "detectLiveness"

      private var hasInitializedSDK: Bool = false

      public static func register(with registrar: FlutterPluginRegistrar) {
          let channel = FlutterMethodChannel(name: CHANNEL_NAME, binaryMessenger: registrar.messenger())

          let instance = SwiftLivenessPlugin()
          registrar.addMethodCallDelegate(instance, channel: channel)
  //        instance.initNavigationController()
      }

      public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
          switch (call.method) {
              case IS_DEVICE_SUPPORT_LIVENESS:
                  #if targetEnvironment(simulator)
                      result(false)
                  #else
                      result(true)
                  #endif
                  break
              case INIT_LIVENESS:
                  if !hasInitializedSDK {
                      AAILivenessSDK.initOffline()
                      hasInitializedSDK = true
                  }
                  result(nil)
                  break
              case DETECT_LIVENESS:
                  let vc = AAILivenessViewController()

                  vc.result = result
                  vc.modalPresentationStyle = .fullScreen
                  let rootViewController = UIApplication.shared.keyWindow?.rootViewController
                  rootViewController?.present(vc, animated: true, completion: nil)
                  break
              default:
                  result(FlutterMethodNotImplemented)
                  break
          }
      }
}
