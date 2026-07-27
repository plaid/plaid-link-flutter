package com.plaid.plaid_link_flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.FrameLayout
import com.plaid.link.OnLinkContinuation
import com.plaid.link.OnLoadCallback
import com.plaid.link.Plaid
import com.plaid.link.PlaidHeadlessSession
import com.plaid.link.PlaidLayerSession
import com.plaid.link.PlaidLinkSession
import com.plaid.link.PlaidSession
import com.plaid.link.SubmissionData
import com.plaid.link.configuration.EmbeddedLinkTokenConfiguration
import com.plaid.link.configuration.LayerTokenConfiguration
import com.plaid.link.configuration.LinkTokenConfiguration
import com.plaid.link.event.LinkEvent
import com.plaid.link.event.LinkEventMetadata
import com.plaid.link.result.LinkAccount
import com.plaid.link.result.LinkError
import com.plaid.link.result.LinkExit
import com.plaid.link.result.LinkExitMetadata
import com.plaid.link.result.LinkInstitution
import com.plaid.link.result.LinkResult
import com.plaid.link.result.LinkSuccess
import com.plaid.link.result.LinkSuccessMetadata
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class PlaidLinkFlutterPlugin :
  FlutterPlugin,
  MethodCallHandler,
  EventChannel.StreamHandler,
  ActivityAware,
  PluginRegistry.ActivityResultListener {
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null
  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null
  private var linkSession: PlaidLinkSession? = null
  private var layerSession: PlaidLayerSession? = null
  private var headlessSession: PlaidHeadlessSession? = null
  private var activeSession: PlaidSession? = null
  private var sessionCreationError: Throwable? = null
  private var embeddedOpenInFlight = false

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(binding.binaryMessenger, "plaid_link_flutter")
    methodChannel.setMethodCallHandler(this)
    eventChannel = EventChannel(binding.binaryMessenger, "plaid_link_flutter/events")
    eventChannel.setStreamHandler(this)
    binding.platformViewRegistry.registerViewFactory(
      "plaid_link_flutter/embedded_search",
      PlaidEmbeddedSearchViewFactory(::sendEmbeddedEvent, { activity }, ::markEmbeddedOpen),
    )
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getSdkVersion" -> result.success(Plaid.VERSION_NAME)
      "createPlaidLinkSession" -> createPlaidLinkSession(call, result)
      "openLinkSession" -> openLinkSession(result)
      "createPlaidLayerSession" -> createPlaidLayerSession(call, result)
      "openLayerSession" -> openLayerSession(result)
      "submitLayerData" -> submitLayerData(call, result)
      "createPlaidHeadlessSession" -> createPlaidHeadlessSession(call, result)
      "startHeadlessSession" -> startHeadlessSession(result)
      "syncFinanceKit" ->
        result.error("UNSUPPORTED_ANDROID", "FinanceKit is only available on iOS", null)
      else -> result.notImplemented()
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    activityBinding?.removeActivityResultListener(this)
    activityBinding = null
    activity = null
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode != Plaid.LINK_REQUEST_CODE) {
      return false
    }

    // A Link result belongs to exactly one flow: the embedded view that launched it,
    // or the current top-level session. Dispatching to both cross-delivers callbacks
    // between embedded and regular sessions.
    val plaidResult = Plaid.parseResult(Plaid.LINK_REQUEST_CODE, resultCode, data)
    val wasEmbedded = embeddedOpenInFlight
    embeddedOpenInFlight = false
    when (plaidResult) {
      is LinkSuccess ->
        if (wasEmbedded) {
          PlaidEmbeddedResultDispatcher.dispatch(plaidResult)
        } else {
          sendEvent("success", plaidResult.toWritableMap())
          clearActiveSession()
        }
      is LinkExit ->
        if (wasEmbedded) {
          PlaidEmbeddedResultDispatcher.dispatch(plaidResult)
        } else {
          sendEvent("exit", plaidResult.toWritableMap())
          clearActiveSession()
        }
      null -> Unit
    }
    return true
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    // Release the process-global Link event listener so its lambda stops retaining
    // this plugin instance (and routing events to a torn-down engine).
    Plaid.setLinkEventListener { _ -> }
    linkSession = null
    layerSession = null
    headlessSession = null
    activeSession = null
    embeddedOpenInFlight = false
  }

  private fun createPlaidLinkSession(call: MethodCall, result: Result) {
    val token = call.argument<String>("token")
    if (token.isNullOrBlank()) {
      result.error("INVALID_TOKEN", "A link token is required.", null)
      return
    }

    val currentActivity = activity
    if (currentActivity == null) {
      result.error("PLAID_NO_ACTIVITY", "Could not find current activity.", null)
      return
    }

    try {
      Plaid.setLinkEventListener { event ->
        sendEvent("event", event.toWritableMap())
      }
      val config =
        LinkTokenConfiguration.Builder()
          .token(token)
          .onLoad(OnLoadCallback { sendEvent("load", emptyMap()) })
          .build()
      linkSession = Plaid.createPlaidLinkSession(currentActivity, config)
      activeSession = linkSession
      sessionCreationError = null
      result.success(null)
    } catch (error: Throwable) {
      sessionCreationError = error
      result.error(
        "LINK_SESSION_CREATE_ERROR",
        error.message ?: "Failed to create Link session.",
        null,
      )
    }
  }

  private fun openLinkSession(result: Result) {
    openSession(linkSession, "createPlaidLinkSession was not called.", result)
  }

  private fun createPlaidLayerSession(call: MethodCall, result: Result) {
    val token = call.argument<String>("token")
    if (token.isNullOrBlank()) {
      result.error("INVALID_TOKEN", "A link token is required.", null)
      return
    }
    val currentActivity = activity
    if (currentActivity == null) {
      result.error("PLAID_NO_ACTIVITY", "Could not find current activity.", null)
      return
    }

    try {
      Plaid.setLinkEventListener { event ->
        sendEvent("event", event.toWritableMap())
      }
      val config = LayerTokenConfiguration.Builder().token(token).build()
      layerSession = Plaid.createPlaidLayerSession(currentActivity, config)
      activeSession = layerSession
      sessionCreationError = null
      result.success(null)
    } catch (error: Throwable) {
      sessionCreationError = error
      result.error(
        "LAYER_SESSION_CREATE_ERROR",
        error.message ?: "Failed to create Layer session.",
        null,
      )
    }
  }

  private fun openLayerSession(result: Result) {
    openSession(layerSession, "createPlaidLayerSession was not called.", result)
  }

  private fun submitLayerData(call: MethodCall, result: Result) {
    val session = layerSession
    if (session == null) {
      result.error("PLAID_NO_LAYER_SESSION", "Layer session not found. Call createPlaidLayerSession first.", null)
      return
    }

    session.submit(
      SubmissionData(
        phoneNumber = call.argument<String>("phoneNumber"),
        dateOfBirth = call.argument<String>("dateOfBirth"),
        params = call.argument<Map<String, String>>("params"),
      ),
    )
    result.success(null)
  }

  private fun createPlaidHeadlessSession(call: MethodCall, result: Result) {
    val token = call.argument<String>("token")
    if (token.isNullOrBlank()) {
      result.error("INVALID_TOKEN", "A link token is required.", null)
      return
    }
    val currentActivity = activity
    if (currentActivity == null) {
      result.error("PLAID_NO_ACTIVITY", "Could not find current activity.", null)
      return
    }

    try {
      Plaid.setLinkEventListener { event ->
        sendEvent("event", event.toWritableMap())
      }
      val config =
        LinkTokenConfiguration.Builder()
          .token(token)
          .onLoad(OnLoadCallback { sendEvent("load", emptyMap()) })
          .build()
      headlessSession = Plaid.createPlaidHeadlessSession(currentActivity, config)
      activeSession = headlessSession
      sessionCreationError = null
      result.success(null)
    } catch (error: Throwable) {
      sessionCreationError = error
      result.error(
        "HEADLESS_SESSION_CREATE_ERROR",
        error.message ?: "Failed to create Headless session.",
        null,
      )
    }
  }

  private fun startHeadlessSession(result: Result) {
    openSession(headlessSession, "createPlaidHeadlessSession was not called.", result)
  }

  private fun openSession(session: PlaidSession?, missingSessionMessage: String, result: Result) {
    if (session == null) {
      result.error(
        "PLAID_NO_SESSION",
        sessionCreationError?.localizedMessage ?: missingSessionMessage,
        null,
      )
      return
    }

    val currentActivity = activity
    if (currentActivity == null) {
      result.error("PLAID_NO_ACTIVITY", "Could not find current activity.", null)
      return
    }

    try {
      embeddedOpenInFlight = false
      activeSession = session
      session.open(currentActivity)
      result.success(null)
    } catch (error: Throwable) {
      result.error("PLAID_OPEN_ERROR", error.message ?: "Failed to open Plaid session.", null)
    }
  }

  private fun clearActiveSession() {
    when (activeSession) {
      linkSession -> linkSession = null
      layerSession -> layerSession = null
      headlessSession -> headlessSession = null
    }
    activeSession = null
  }

  private fun markEmbeddedOpen() {
    embeddedOpenInFlight = true
  }

  private fun sendEvent(type: String, payload: Map<String, Any>) {
    activity?.runOnUiThread {
      eventSink?.success(mapOf("type" to type, "payload" to payload))
    }
  }

  private fun sendEmbeddedEvent(viewId: Int, type: String, payload: Map<String, Any>) {
    activity?.runOnUiThread {
      eventSink?.success(mapOf("type" to type, "viewId" to viewId, "payload" to payload))
    }
  }
}

private class PlaidEmbeddedSearchViewFactory(
  private val sendEmbeddedEvent: (Int, String, Map<String, Any>) -> Unit,
  private val activityProvider: () -> Activity?,
  private val markEmbeddedOpen: () -> Unit,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    val params = args as? Map<*, *> ?: emptyMap<Any, Any>()
    return PlaidEmbeddedSearchPlatformView(
      context = context,
      viewId = viewId,
      token = params["token"] as? String ?: "",
      sendEmbeddedEvent = sendEmbeddedEvent,
      activityProvider = activityProvider,
      markEmbeddedOpen = markEmbeddedOpen,
    )
  }
}

private class PlaidEmbeddedSearchPlatformView(
  context: Context,
  private val viewId: Int,
  token: String,
  private val sendEmbeddedEvent: (Int, String, Map<String, Any>) -> Unit,
  private val activityProvider: () -> Activity?,
  private val markEmbeddedOpen: () -> Unit,
) : PlatformView {
  private val container = FrameLayout(context)
  private val resultHandler: (LinkResult) -> Unit = ::handleResult

  init {
    if (token.isNotBlank()) {
      Plaid.setLinkEventListener { event ->
        sendEmbeddedEvent(viewId, "embeddedEvent", event.toWritableMap())
      }

      val config =
        EmbeddedLinkTokenConfiguration.Builder()
          .token(token)
          .onEmbeddedViewExit { exit ->
            sendEmbeddedEvent(viewId, "embeddedExit", exit.toWritableMap())
          }
          .build()

      val embeddedView =
        Plaid.createPlaidEmbeddedLinkView(
          context,
          config,
          OnLinkContinuation { session ->
            val activity = activityProvider() ?: return@OnLinkContinuation
            markEmbeddedOpen()
            session.open(activity)
          },
        )

      container.addView(
        embeddedView,
        FrameLayout.LayoutParams(
          FrameLayout.LayoutParams.MATCH_PARENT,
          FrameLayout.LayoutParams.MATCH_PARENT,
        ),
      )
      PlaidEmbeddedResultDispatcher.register(resultHandler)
      sendEmbeddedEvent(viewId, "embeddedLoad", emptyMap())
    }
  }

  override fun getView(): View = container

  override fun dispose() {
    PlaidEmbeddedResultDispatcher.unregister(resultHandler)
    container.removeAllViews()
  }

  private fun handleResult(result: LinkResult) {
    when (result) {
      is LinkSuccess -> sendEmbeddedEvent(viewId, "embeddedSuccess", result.toWritableMap())
      is LinkExit -> sendEmbeddedEvent(viewId, "embeddedExit", result.toWritableMap())
    }
  }
}

internal class SingleActiveDispatcher<T> {
  private var activeHandler: ((T) -> Unit)? = null

  fun register(handler: (T) -> Unit) {
    activeHandler = handler
  }

  fun unregister(handler: (T) -> Unit) {
    if (activeHandler == handler) {
      activeHandler = null
    }
  }

  fun dispatch(value: T) {
    activeHandler?.invoke(value)
  }
}

private object PlaidEmbeddedResultDispatcher {
  private val dispatcher = SingleActiveDispatcher<LinkResult>()

  fun register(handler: (LinkResult) -> Unit) = dispatcher.register(handler)

  fun unregister(handler: (LinkResult) -> Unit) = dispatcher.unregister(handler)

  fun dispatch(result: LinkResult) = dispatcher.dispatch(result)
}

internal fun LinkSuccess.toWritableMap(): Map<String, Any> =
  successPayload(
    publicToken = publicToken,
    metadata = metadata.toWritableMap(),
  )

internal fun LinkSuccessMetadata.toWritableMap(): Map<String, Any> =
  successMetadataPayload(
    linkSessionId = linkSessionId,
    institution = institution?.toWritableMap() ?: "",
    accounts = accounts.map { it.toWritableMap() },
    metadataJson = metadataJson.orEmpty(),
  )

internal fun LinkExit.toWritableMap(): Map<String, Any> =
  exitPayload(
    error = error?.toWritableMap() ?: emptyMap(),
    metadata = metadata.toWritableMap(),
  )

internal fun LinkExitMetadata.toWritableMap(): Map<String, Any> =
  exitMetadataPayload(
    status = status?.jsonValue.orEmpty(),
    institution = institution?.toWritableMap() ?: "",
    requestId = requestId.orEmpty(),
    linkSessionId = linkSessionId.orEmpty(),
    metadataJson = metadataJson.orEmpty(),
  )

internal fun LinkError.toWritableMap(): Map<String, Any> =
  errorPayload(
    errorType = errorCode.errorType.json,
    errorCode = errorCode.json,
    errorMessage = errorMessage,
    displayMessage = displayMessage.orEmpty(),
    errorJson = errorJson.orEmpty(),
  )

internal fun LinkEvent.toWritableMap(): Map<String, Any> =
  eventPayload(
    eventName = eventName.json,
    metadata = metadata.toWritableMap(),
  )

internal fun LinkEventMetadata.toWritableMap(): Map<String, Any> =
  eventMetadataPayload(
    errorType = errorType.orEmpty(),
    errorCode = errorCode.orEmpty(),
    errorMessage = errorMessage.orEmpty(),
    exitStatus = exitStatus.orEmpty(),
    institutionId = institutionId.orEmpty(),
    institutionName = institutionName.orEmpty(),
    institutionSearchQuery = institutionSearchQuery.orEmpty(),
    accountNumberMask = accountNumberMask.orEmpty(),
    isUpdateMode = isUpdateMode.orEmpty(),
    matchReason = matchReason.orEmpty(),
    routingNumber = routingNumber.orEmpty(),
    selection = selection.orEmpty(),
    linkSessionId = linkSessionId,
    mfaType = mfaType.orEmpty(),
    requestId = requestId.orEmpty(),
    issueId = issueId.orEmpty(),
    issueDescription = issueDescription.orEmpty(),
    issueDetectedAt = issueDetectedAt.orEmpty(),
    timestamp = timestamp,
    viewName = viewName?.jsonValue.orEmpty(),
    metadataJson = metadataJson.orEmpty(),
  )

internal fun LinkInstitution.toWritableMap(): Map<String, Any> =
  institutionPayload(name = name, id = id)

internal fun LinkAccount.toWritableMap(): Map<String, Any> =
  accountPayload(
    id = id,
    name = name.orEmpty(),
    mask = mask.orEmpty(),
    subtype = subtype.json,
    type = subtype.accountType.json,
    verificationStatus = verificationStatus?.json.orEmpty(),
  )

internal fun successPayload(publicToken: String, metadata: Map<String, Any>): Map<String, Any> =
  mapOf("publicToken" to publicToken, "metadata" to metadata)

internal fun successMetadataPayload(
  linkSessionId: String,
  institution: Any,
  accounts: List<Map<String, Any>>,
  metadataJson: String,
): Map<String, Any> =
  mapOf(
    "linkSessionId" to linkSessionId,
    "institution" to institution,
    "accounts" to accounts,
    "metadataJson" to metadataJson,
  )

internal fun exitPayload(error: Map<String, Any>, metadata: Map<String, Any>): Map<String, Any> =
  mapOf("error" to error, "metadata" to metadata)

internal fun exitMetadataPayload(
  status: String,
  institution: Any,
  requestId: String,
  linkSessionId: String,
  metadataJson: String,
): Map<String, Any> =
  mapOf(
    "status" to status,
    "institution" to institution,
    "requestId" to requestId,
    "linkSessionId" to linkSessionId,
    "metadataJson" to metadataJson,
  )

internal fun errorPayload(
  errorType: String,
  errorCode: String,
  errorMessage: String,
  displayMessage: String,
  errorJson: String,
): Map<String, Any> =
  mapOf(
    "errorType" to errorType,
    "errorCode" to errorCode,
    "errorMessage" to errorMessage,
    "displayMessage" to displayMessage,
    "errorJson" to errorJson,
  )

internal fun eventPayload(eventName: String, metadata: Map<String, Any>): Map<String, Any> =
  mapOf("eventName" to eventName, "metadata" to metadata)

internal fun eventMetadataPayload(
  errorType: String,
  errorCode: String,
  errorMessage: String,
  exitStatus: String,
  institutionId: String,
  institutionName: String,
  institutionSearchQuery: String,
  accountNumberMask: String,
  isUpdateMode: String,
  matchReason: String,
  routingNumber: String,
  selection: String,
  linkSessionId: String,
  mfaType: String,
  requestId: String,
  issueId: String,
  issueDescription: String,
  issueDetectedAt: String,
  timestamp: String,
  viewName: String,
  metadataJson: String,
): Map<String, Any> =
  mapOf(
    "errorType" to errorType,
    "errorCode" to errorCode,
    "errorMessage" to errorMessage,
    "exitStatus" to exitStatus,
    "institutionId" to institutionId,
    "institutionName" to institutionName,
    "institutionSearchQuery" to institutionSearchQuery,
    "accountNumberMask" to accountNumberMask,
    "isUpdateMode" to isUpdateMode,
    "matchReason" to matchReason,
    "routingNumber" to routingNumber,
    "selection" to selection,
    "linkSessionId" to linkSessionId,
    "mfaType" to mfaType,
    "requestId" to requestId,
    "issueId" to issueId,
    "issueDescription" to issueDescription,
    "issueDetectedAt" to issueDetectedAt,
    "timestamp" to timestamp,
    "viewName" to viewName,
    "metadataJson" to metadataJson,
  )

internal fun institutionPayload(name: String, id: String): Map<String, Any> =
  mapOf("name" to name, "id" to id)

internal fun accountPayload(
  id: String,
  name: String,
  mask: String,
  subtype: String,
  type: String,
  verificationStatus: String,
): Map<String, Any> =
  mapOf(
    "id" to id,
    "name" to name,
    "mask" to mask,
    "subtype" to subtype,
    "type" to type,
    "verificationStatus" to verificationStatus,
  )
