import Flutter
import LinkKit
import UIKit

public class PlaidLinkFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var linkSession: PlaidLinkSession?
  private var sessionCreationError: Error?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "plaid_link_flutter",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "plaid_link_flutter/events",
      binaryMessenger: registrar.messenger()
    )
    let instance = PlaidLinkFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getSdkVersion":
      result(Plaid.version)
    case "createPlaidLinkSession":
      createPlaidLinkSession(call, result: result)
    case "openLinkSession":
      openLinkSession(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func createPlaidLinkSession(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let token = arguments["token"] as? String,
      !token.isEmpty
    else {
      result(FlutterError(code: "INVALID_TOKEN", message: "A link token is required.", details: nil))
      return
    }

    let onSuccess: OnSuccessHandler = { [weak self] success in
      self?.sendEvent(type: "success", payload: success.asDictionary)
      self?.linkSession = nil
    }

    let onExit: OnExitHandler = { [weak self] exit in
      self?.sendEvent(type: "exit", payload: exit.asDictionary)
      self?.linkSession = nil
    }

    let onEvent: OnEventHandler = { [weak self] event in
      self?.sendEvent(type: "event", payload: event.asDictionary)
    }

    let onLoad: OnLoadHandler = {
      DispatchQueue.main.async {
        result(nil)
      }
    }

    let configuration = LinkTokenConfiguration(
      token: token,
      onSuccess: onSuccess,
      onExit: onExit,
      onEvent: onEvent,
      onLoad: onLoad
    )

    do {
      linkSession = try Plaid.createPlaidLinkSession(configuration: configuration)
      sessionCreationError = nil
    } catch {
      sessionCreationError = error
      result(
        FlutterError(
          code: "LINK_SESSION_CREATE_ERROR",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func openLinkSession(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let session = linkSession else {
      sendCreationExit(defaultMessage: "createPlaidLinkSession was not called.")
      result(nil)
      return
    }

    guard let viewController = UIApplication.shared.plaidTopViewController() else {
      result(FlutterError(code: "PLAID_NO_VC", message: "Could not find current view controller.", details: nil))
      return
    }

    let arguments = call.arguments as? [String: Any]
    let fullScreen = arguments?["fullScreen"] as? Bool ?? false

    DispatchQueue.main.async {
      if fullScreen {
        let presentationHandler: PresentationHandler = { linkViewController in
          linkViewController.modalPresentationStyle = .overFullScreen
          linkViewController.modalTransitionStyle = .coverVertical
          viewController.present(linkViewController, animated: true)
        }
        let dismissalHandler: DismissalHandler = { linkViewController in
          linkViewController.presentingViewController?.dismiss(animated: true)
        }
        session.open(using: .custom(presentationHandler, dismissalHandler))
      } else {
        session.open(using: .viewController(viewController))
      }
      result(nil)
    }
  }

  private func sendCreationExit(defaultMessage: String) {
    let errorMessage = sessionCreationError?.localizedDescription ?? defaultMessage
    sendEvent(
      type: "exit",
      payload: [
        "error": [
          "errorType": "creation error",
          "errorCode": "-1",
          "errorMessage": errorMessage,
          "displayMessage": errorMessage,
          "errorJson": "",
        ],
        "metadata": [
          "linkSessionId": "",
          "institution": "",
          "status": "",
          "requestId": "",
          "metadataJson": "",
        ],
      ]
    )
  }

  private func sendEvent(type: String, payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(["type": type, "payload": payload])
    }
  }
}

private extension UIApplication {
  func plaidTopViewController() -> UIViewController? {
    let scenes = connectedScenes.compactMap { $0 as? UIWindowScene }
    let keyWindow = scenes.flatMap(\.windows).first { $0.isKeyWindow }
    return keyWindow?.rootViewController?.plaidTopViewController()
  }
}

private extension UIViewController {
  func plaidTopViewController() -> UIViewController {
    if let presentedViewController = presentedViewController {
      return presentedViewController.plaidTopViewController()
    }
    if let navigationController = self as? UINavigationController {
      return navigationController.visibleViewController?.plaidTopViewController() ?? navigationController
    }
    if let tabBarController = self as? UITabBarController {
      return tabBarController.selectedViewController?.plaidTopViewController() ?? tabBarController
    }
    return self
  }
}

private extension Institution {
  var asDictionary: [String: Any] {
    ["name": name, "id": id]
  }
}

private extension Account {
  var asDictionary: [String: Any] {
    [
      "id": id,
      "name": name,
      "mask": mask ?? "",
      "subtype": subtype.description,
      "type": subtype.typeName,
      "verificationStatus": verificationStatus?.description ?? "",
    ]
  }
}

private extension AccountSubtype {
  var typeName: String {
    switch self {
    case .other: return "other"
    case .credit: return "credit"
    case .loan: return "loan"
    case .depository: return "depository"
    case .investment: return "investment"
    case .unknown(let type, _): return type
    @unknown default: return "UNKNOWN"
    }
  }
}

private extension LinkSuccess {
  var asDictionary: [String: Any] {
    [
      "publicToken": publicToken,
      "metadata": [
        "linkSessionId": metadata.linkSessionID,
        "institution": metadata.institution.asDictionary,
        "accounts": metadata.accounts.map { $0.asDictionary },
        "metadataJson": metadata.metadataJSON ?? "",
      ],
    ]
  }
}

private extension LinkExit {
  var asDictionary: [String: Any] {
    [
      "error": error?.asDictionary ?? [:],
      "metadata": [
        "status": metadata.status?.description ?? "",
        "institution": metadata.institution?.asDictionary ?? "",
        "requestId": metadata.requestID ?? "",
        "linkSessionId": metadata.linkSessionID ?? "",
        "metadataJson": metadata.metadataJSON ?? "",
      ],
    ]
  }
}

private extension LinkEvent {
  var asDictionary: [String: Any] {
    ["eventName": eventName.description, "metadata": metadata.asDictionary]
  }
}

private extension EventMetadata {
  var asDictionary: [String: Any] {
    [
      "errorType": errorCode?.description ?? "",
      "errorCode": errorCode?.errorCodeString ?? "",
      "errorMessage": errorMessage ?? "",
      "exitStatus": exitStatus?.description ?? "",
      "institutionId": institutionID ?? "",
      "institutionName": institutionName ?? "",
      "institutionSearchQuery": institutionSearchQuery ?? "",
      "accountNumberMask": accountNumberMask ?? "",
      "isUpdateMode": isUpdateMode ?? "",
      "matchReason": matchReason ?? "",
      "routingNumber": routingNumber ?? "",
      "selection": selection ?? "",
      "linkSessionId": linkSessionID,
      "mfaType": mfaType?.description ?? "",
      "requestId": requestID ?? "",
      "issueId": issueID ?? "",
      "issueDescription": issueDescription ?? "",
      "issueDetectedAt": issueDetectedAt.map(iso8601String) ?? "",
      "timestamp": iso8601String(from: timestamp),
      "viewName": viewName?.description ?? "",
      "metadataJson": metadataJSON ?? "",
    ]
  }
}

private extension ExitError {
  var asDictionary: [String: Any] {
    [
      "errorType": errorCode.description,
      "errorCode": errorCode.errorCodeString,
      "errorMessage": errorMessage,
      "displayMessage": displayMessage ?? "",
      "errorJson": errorJSON ?? "",
    ]
  }
}

private extension ExitErrorCode {
  var errorCodeString: String {
    switch self {
    case .apiError(let code): return code.description
    case .authError(let code): return code.description
    case .assetReportError(let code): return code.description
    case .internal(let code): return code
    case .institutionError(let code): return code.description
    case .itemError(let code): return code.description
    case .invalidInput(let code): return code.description
    case .invalidRequest(let code): return code.description
    case .rateLimitExceeded(let code): return code.description
    case .unknown(_, let code): return code
    @unknown default: return "UNKNOWN"
    }
  }
}

private func iso8601String(from date: Date) -> String {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime]
  return formatter.string(from: date)
}
