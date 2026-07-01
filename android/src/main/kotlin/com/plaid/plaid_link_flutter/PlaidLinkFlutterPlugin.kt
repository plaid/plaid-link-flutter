package com.plaid.plaid_link_flutter

import android.app.Activity
import android.content.Intent
import com.plaid.link.OnLoadCallback
import com.plaid.link.Plaid
import com.plaid.link.PlaidLinkSession
import com.plaid.link.configuration.LinkTokenConfiguration
import com.plaid.link.event.LinkEvent
import com.plaid.link.event.LinkEventMetadata
import com.plaid.link.result.LinkAccount
import com.plaid.link.result.LinkError
import com.plaid.link.result.LinkExit
import com.plaid.link.result.LinkExitMetadata
import com.plaid.link.result.LinkInstitution
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
  private var sessionCreationError: Throwable? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(binding.binaryMessenger, "plaid_link_flutter")
    methodChannel.setMethodCallHandler(this)
    eventChannel = EventChannel(binding.binaryMessenger, "plaid_link_flutter/events")
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getSdkVersion" -> result.success(Plaid.VERSION_NAME)
      "createPlaidLinkSession" -> createPlaidLinkSession(call, result)
      "openLinkSession" -> openLinkSession(result)
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

    when (val plaidResult = Plaid.parseResult(Plaid.LINK_REQUEST_CODE, resultCode, data)) {
      is LinkSuccess -> {
        sendEvent("success", plaidResult.toWritableMap())
        linkSession = null
      }
      is LinkExit -> {
        sendEvent("exit", plaidResult.toWritableMap())
        linkSession = null
      }
      null -> Unit
    }
    return true
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
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
          .onLoad(OnLoadCallback { result.success(null) })
          .build()
      linkSession = Plaid.createPlaidLinkSession(currentActivity, config)
      sessionCreationError = null
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
    val session = linkSession
    if (session == null) {
      sendCreationExit("createPlaidLinkSession was not called.")
      result.success(null)
      return
    }

    val currentActivity = activity
    if (currentActivity == null) {
      result.error("PLAID_NO_ACTIVITY", "Could not find current activity.", null)
      return
    }

    try {
      session.open(currentActivity)
      result.success(null)
    } catch (error: Throwable) {
      result.error("PLAID_OPEN_ERROR", error.message ?: "Failed to open Plaid session.", null)
    }
  }

  private fun sendCreationExit(defaultMessage: String) {
    val errorMessage = sessionCreationError?.localizedMessage ?: defaultMessage
    sendEvent(
      "exit",
      exitPayload(
        error =
          errorPayload(
            errorType = "creation error",
            errorCode = "-1",
            errorMessage = errorMessage,
            displayMessage = errorMessage,
            errorJson = "",
          ),
        metadata = emptyExitMetadata(),
      ),
    )
  }

  private fun sendEvent(type: String, payload: Map<String, Any>) {
    activity?.runOnUiThread {
      eventSink?.success(mapOf("type" to type, "payload" to payload))
    }
  }
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

internal fun emptyExitMetadata(): Map<String, Any> =
  exitMetadataPayload(
    linkSessionId = "",
    institution = "",
    status = "",
    requestId = "",
    metadataJson = "",
  )
