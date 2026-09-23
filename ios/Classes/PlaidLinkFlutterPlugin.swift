import Flutter
import LinkKit
import UIKit

@objc(PlaidFlutterPlugin)
public final class PlaidFlutterPlugin: NSObject {
  @objc public static let sdkVersion: String = "1.1.0"
}

public class PlaidLinkFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private enum SessionKind {
    case link
    case layer
    case headless
  }

  private static let handoffCleanupDelay: TimeInterval = 3

  private var eventSink: FlutterEventSink?
  private var linkSession: PlaidLinkSession?
  private var layerSession: PlaidLayerSession?
  private var headlessSession: (any PlaidHeadlessSession)?
  private var sessionCreationError: Error?
  private var activeSessionId: Int?
  private var activeSessionKind: SessionKind?
  private var waitingForHandoffSessionId: Int?
  private var handoffCleanupWorkItem: DispatchWorkItem?

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
    eventChannel.setStreamHandler(instance)
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    registrar.register(
      PlaidEmbeddedSearchViewFactory(sendEmbeddedEvent: instance.sendEmbeddedEvent),
      withId: "plaid_link_flutter/embedded_search"
    )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getSdkVersion":
      result(Plaid.version)
    case "createPlaidLinkSession":
      createPlaidLinkSession(call, result: result)
    case "openLinkSession":
      openLinkSession(call, result: result)
    case "createPlaidLayerSession":
      createPlaidLayerSession(call, result: result)
    case "openLayerSession":
      openLayerSession(result: result)
    case "submitLayerData":
      submitLayerData(call, result: result)
    case "createPlaidHeadlessSession":
      createPlaidHeadlessSession(call, result: result)
    case "startHeadlessSession":
      startHeadlessSession(result: result)
    case "syncFinanceKit":
      syncFinanceKit(call, result: result)
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

    let sessionId = arguments["sessionId"] as? Int ?? -1

    let onSuccess: OnSuccessHandler = { [weak self] success in
      self?.sendEvent(type: "success", payload: success.asDictionary, sessionId: sessionId)
      self?.markSessionSucceeded(sessionId: sessionId)
    }

    let onExit: OnExitHandler = { [weak self] exit in
      self?.sendEvent(type: "exit", payload: exit.asDictionary, sessionId: sessionId)
      self?.clearActiveSession(sessionId: sessionId)
    }

    let onEvent: OnEventHandler = { [weak self] event in
      self?.sendEvent(type: "event", payload: event.asDictionary, sessionId: sessionId)
      self?.clearSucceededSessionOnHandoff(event: event, sessionId: sessionId)
    }

    let onLoad: OnLoadHandler = { [weak self] in
      self?.sendEvent(type: "load", payload: [:], sessionId: sessionId)
    }

    let configuration = LinkTokenConfiguration(
      token: token,
      onSuccess: onSuccess,
      onExit: onExit,
      onEvent: onEvent,
      onLoad: onLoad
    )

    do {
      clearActiveSession()
      linkSession = try Plaid.createPlaidLinkSession(configuration: configuration)
      markActiveSession(kind: .link, sessionId: sessionId)
      sessionCreationError = nil
      result(nil)
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

  private func createPlaidLayerSession(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let token = arguments["token"] as? String,
      !token.isEmpty
    else {
      result(FlutterError(code: "INVALID_TOKEN", message: "A link token is required.", details: nil))
      return
    }

    let sessionId = arguments["sessionId"] as? Int ?? -1

    let onSuccess: OnSuccessHandler = { [weak self] success in
      self?.sendEvent(type: "success", payload: success.asDictionary, sessionId: sessionId)
      self?.markSessionSucceeded(sessionId: sessionId)
    }

    let onExit: OnExitHandler = { [weak self] exit in
      self?.sendEvent(type: "exit", payload: exit.asDictionary, sessionId: sessionId)
      self?.clearActiveSession(sessionId: sessionId)
    }

    let onEvent: OnEventHandler = { [weak self] event in
      self?.sendEvent(type: "event", payload: event.asDictionary, sessionId: sessionId)
      self?.clearSucceededSessionOnHandoff(event: event, sessionId: sessionId)
    }

    let configuration = LayerTokenConfiguration(
      token: token,
      onSuccess: onSuccess,
      onExit: onExit,
      onEvent: onEvent
    )

    do {
      clearActiveSession()
      layerSession = try Plaid.createPlaidLayerSession(configuration: configuration)
      markActiveSession(kind: .layer, sessionId: sessionId)
      sessionCreationError = nil
      result(nil)
    } catch {
      sessionCreationError = error
      result(
        FlutterError(
          code: "LAYER_SESSION_CREATE_ERROR",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func createPlaidHeadlessSession(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let token = arguments["token"] as? String,
      !token.isEmpty
    else {
      result(FlutterError(code: "INVALID_TOKEN", message: "A link token is required.", details: nil))
      return
    }

    let sessionId = arguments["sessionId"] as? Int ?? -1

    let onSuccess: OnSuccessHandler = { [weak self] success in
      self?.sendEvent(type: "success", payload: success.asDictionary, sessionId: sessionId)
      self?.markSessionSucceeded(sessionId: sessionId)
    }

    let onExit: OnExitHandler = { [weak self] exit in
      self?.sendEvent(type: "exit", payload: exit.asDictionary, sessionId: sessionId)
      self?.clearActiveSession(sessionId: sessionId)
    }

    let onEvent: OnEventHandler = { [weak self] event in
      self?.sendEvent(type: "event", payload: event.asDictionary, sessionId: sessionId)
      self?.clearSucceededSessionOnHandoff(event: event, sessionId: sessionId)
    }

    let onLoad: OnLoadHandler = { [weak self] in
      self?.sendEvent(type: "load", payload: [:], sessionId: sessionId)
    }

    let configuration = LinkTokenConfiguration(
      token: token,
      onSuccess: onSuccess,
      onExit: onExit,
      onEvent: onEvent,
      onLoad: onLoad
    )

    do {
      clearActiveSession()
      headlessSession = try Plaid.createHeadlessSession(configuration: configuration)
      markActiveSession(kind: .headless, sessionId: sessionId)
      sessionCreationError = nil
      result(nil)
    } catch {
      sessionCreationError = error
      result(
        FlutterError(
          code: "HEADLESS_SESSION_CREATE_ERROR",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func openLinkSession(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let session = linkSession else {
      result(noSessionError(defaultMessage: "createPlaidLinkSession was not called."))
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

  private func openLayerSession(result: @escaping FlutterResult) {
    guard let session = layerSession else {
      result(noSessionError(defaultMessage: "createPlaidLayerSession was not called."))
      return
    }

    guard let viewController = UIApplication.shared.plaidTopViewController() else {
      result(FlutterError(code: "PLAID_NO_VC", message: "Could not find current view controller.", details: nil))
      return
    }

    DispatchQueue.main.async {
      session.open(using: .viewController(viewController))
      result(nil)
    }
  }

  private func submitLayerData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let session = layerSession else {
      result(
        FlutterError(
          code: "PLAID_NO_LAYER_SESSION",
          message: "Layer session not found. Call createPlaidLayerSession first.",
          details: nil
        )
      )
      return
    }

    let arguments = call.arguments as? [String: Any]
    let data = LayerSubmissionData(
      phoneNumber: arguments?["phoneNumber"] as? String,
      dateOfBirth: arguments?["dateOfBirth"] as? String,
      params: arguments?["params"] as? [String: String]
    )

    DispatchQueue.main.async {
      session.submit(data: data)
      result(nil)
    }
  }

  private func startHeadlessSession(result: @escaping FlutterResult) {
    guard let session = headlessSession else {
      result(noSessionError(defaultMessage: "createPlaidHeadlessSession was not called."))
      return
    }

    DispatchQueue.main.async {
      session.start()
      result(nil)
    }
  }

  private func syncFinanceKit(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let token = arguments["token"] as? String,
      !token.isEmpty
    else {
      result(FlutterError(code: "INVALID_TOKEN", message: "A link token is required.", details: nil))
      return
    }

    let requestAuthorizationIfNeeded =
      arguments["requestAuthorizationIfNeeded"] as? Bool ?? true
    let syncBehavior = arguments["syncBehavior"] as? Int ?? 0

    if #available(iOS 17.4, *) {
      // Only 1 selects simulated; any unexpected value falls back to the live default.
      let behavior: PlaidFinanceKit.SyncBehavior = syncBehavior == 1 ? .simulated : .live
      PlaidFinanceKit.sync(
        token: token,
        requestAuthorizationIfNeeded: requestAuthorizationIfNeeded,
        syncBehavior: behavior
      ) { syncResult in
        DispatchQueue.main.async {
          switch syncResult {
          case .success:
            result(nil)
          case .failure(let error):
            let details = error.asFinanceKitErrorDictionary
            result(
              FlutterError(
                code: details["errorCode"] as? String ?? "FINANCE_KIT_ERROR",
                message: details["errorMessage"] as? String ?? error.localizedDescription,
                details: details
              )
            )
          }
        }
      }
    } else {
      result(
        FlutterError(
          code: "UNSUPPORTED_IOS_VERSION",
          message: "FinanceKit requires iOS 17.4 or later",
          details: ["errorType": 4, "errorCode": "UNSUPPORTED_IOS_VERSION"]
        )
      )
    }
  }

  private func noSessionError(defaultMessage: String) -> FlutterError {
    FlutterError(
      code: "PLAID_NO_SESSION",
      message: sessionCreationError?.localizedDescription ?? defaultMessage,
      details: nil
    )
  }

  private func markActiveSession(kind: SessionKind, sessionId: Int) {
    activeSessionKind = kind
    activeSessionId = sessionId
    waitingForHandoffSessionId = nil
    cancelHandoffCleanup()
  }

  private func markSessionSucceeded(sessionId: Int) {
    guard activeSessionId == sessionId else {
      return
    }

    waitingForHandoffSessionId = sessionId
    cancelHandoffCleanup()

    let workItem = DispatchWorkItem { [weak self] in
      self?.clearActiveSession(sessionId: sessionId)
    }
    handoffCleanupWorkItem = workItem
    DispatchQueue.main.asyncAfter(
      deadline: .now() + Self.handoffCleanupDelay,
      execute: workItem
    )
  }

  private func clearSucceededSessionOnHandoff(event: LinkEvent, sessionId: Int) {
    guard event.eventName == .handoff, waitingForHandoffSessionId == sessionId else {
      return
    }
    clearActiveSession(sessionId: sessionId)
  }

  private func clearActiveSession(sessionId: Int? = nil) {
    if let sessionId, activeSessionId != sessionId {
      return
    }

    cancelHandoffCleanup()

    switch activeSessionKind {
    case .link:
      linkSession = nil
    case .layer:
      layerSession = nil
    case .headless:
      headlessSession = nil
    case nil:
      linkSession = nil
      layerSession = nil
      headlessSession = nil
    }

    activeSessionKind = nil
    activeSessionId = nil
    waitingForHandoffSessionId = nil
  }

  private func cancelHandoffCleanup() {
    handoffCleanupWorkItem?.cancel()
    handoffCleanupWorkItem = nil
  }

  private func sendEvent(type: String, payload: [String: Any], sessionId: Int? = nil) {
    DispatchQueue.main.async { [weak self] in
      var event: [String: Any] = ["type": type, "payload": payload]
      if let sessionId = sessionId {
        event["sessionId"] = sessionId
      }
      self?.eventSink?(event)
    }
  }

  private func sendEmbeddedEvent(viewId: Int64, type: String, payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(["type": type, "viewId": viewId, "payload": payload])
    }
  }
}

private struct LayerSubmissionData: SubmissionData {
  let phoneNumber: String?
  let dateOfBirth: String?
  let params: [String: String]?
}

private class PlaidEmbeddedSearchViewFactory: NSObject, FlutterPlatformViewFactory {
  private let sendEmbeddedEvent: (Int64, String, [String: Any]) -> Void

  init(sendEmbeddedEvent: @escaping (Int64, String, [String: Any]) -> Void) {
    self.sendEmbeddedEvent = sendEmbeddedEvent
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let arguments = args as? [String: Any]
    return PlaidEmbeddedSearchPlatformView(
      frame: frame,
      viewId: viewId,
      token: arguments?["token"] as? String ?? "",
      sendEmbeddedEvent: sendEmbeddedEvent
    )
  }
}

private class PlaidEmbeddedSearchPlatformView: NSObject, FlutterPlatformView {
  private let container: UIView
  private let viewId: Int64
  private let sendEmbeddedEvent: (Int64, String, [String: Any]) -> Void
  private var embeddedView: EmbeddedSearchUIView?

  init(
    frame: CGRect,
    viewId: Int64,
    token: String,
    sendEmbeddedEvent: @escaping (Int64, String, [String: Any]) -> Void
  ) {
    self.container = UIView(frame: frame)
    self.viewId = viewId
    self.sendEmbeddedEvent = sendEmbeddedEvent
    super.init()
    container.clipsToBounds = true
    createEmbeddedView(token: token)
  }

  func view() -> UIView {
    container
  }

  private func createEmbeddedView(token: String) {
    guard !token.isEmpty else {
      return
    }

    let configuration = EmbeddedLinkTokenConfiguration(
      token: token,
      onSuccess: { [weak self] success in
        self?.send("embeddedSuccess", success.asDictionary)
      },
      onExit: { [weak self] exit in
        self?.send("embeddedExit", exit.asDictionary)
      },
      onEvent: { [weak self] event in
        self?.send("embeddedEvent", event.asDictionary)
      }
    )

    guard let viewController = UIApplication.shared.plaidTopViewController() else {
      send("embeddedExit", [
        "error": [
          "errorCode": "NO_VIEW_CONTROLLER",
          "errorType": "INTERNAL_ERROR",
          "errorMessage": "Could not find current view controller.",
          "displayMessage": "Could not find current view controller.",
          "errorJson": "",
        ],
        "metadata": [
          "linkSessionId": "",
          "institution": "",
          "status": "",
          "requestId": "",
          "metadataJson": "",
        ],
      ])
      return
    }

    do {
      let view = try Plaid.createEmbeddedLinkUIView(
        configuration: configuration,
        presentationMethod: .viewController(viewController)
      )
      embeddedView = view
      view.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(view)
      NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: container.topAnchor),
        view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      ])
      send("embeddedLoad", [:])
    } catch {
      send("embeddedExit", [
        "error": [
          "errorCode": "CREATE_VIEW_ERROR",
          "errorType": "INTERNAL_ERROR",
          "errorMessage": error.localizedDescription,
          "displayMessage": error.localizedDescription,
          "errorJson": "",
        ],
        "metadata": [
          "linkSessionId": "",
          "institution": "",
          "status": "",
          "requestId": "",
          "metadataJson": "",
        ],
      ])
    }
  }

  private func send(_ type: String, _ payload: [String: Any]) {
    sendEmbeddedEvent(viewId, type, payload)
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

@available(iOS 17.4, *)
private extension FinanceKitError {
  var asFinanceKitErrorDictionary: [String: Any] {
    let errorType: Int
    let errorCode: String
    let errorMessage: String

    switch self {
    case .invalidToken:
      errorType = 0
      errorCode = "INVALID_TOKEN"
      errorMessage = localizedDescription
    case .permissionError:
      errorType = 1
      errorCode = "PERMISSION_ERROR"
      errorMessage = localizedDescription
    case .linkApiError:
      errorType = 2
      errorCode = "LINK_API_ERROR"
      errorMessage = localizedDescription
    case .permissionAccessError:
      errorType = 3
      errorCode = "PERMISSION_ACCESS_ERROR"
      errorMessage = localizedDescription
    case .unknown(let error):
      errorType = 4
      errorCode = "UNKNOWN"
      errorMessage = error.localizedDescription
    @unknown default:
      errorType = 4
      errorCode = "UNKNOWN"
      errorMessage = localizedDescription
    }

    return [
      "errorType": errorType,
      "errorCode": errorCode,
      "errorMessage": errorMessage,
    ]
  }
}

private func iso8601String(from date: Date) -> String {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime]
  return formatter.string(from: date)
}
