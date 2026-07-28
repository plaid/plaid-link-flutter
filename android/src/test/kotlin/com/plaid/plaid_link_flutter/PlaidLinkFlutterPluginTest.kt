package com.plaid.plaid_link_flutter

import kotlin.test.Test
import kotlin.test.assertEquals

internal class PlaidLinkFlutterPluginTest {
  @Test
  fun successPayload_containsReactNativeShape() {
    val payload =
      successPayload(
        publicToken = "public-token",
        metadata =
          successMetadataPayload(
            linkSessionId = "session-id",
            institution = institutionPayload(name = "Plaid Bank", id = "ins_1"),
            accounts =
              listOf(
                accountPayload(
                  id = "account-id",
                  name = "Checking",
                  mask = "0000",
                  subtype = "checking",
                  type = "depository",
                  verificationStatus = "",
                ),
              ),
            metadataJson = "{}",
          ),
      )

    assertEquals("public-token", payload["publicToken"])
    val metadata = payload["metadata"] as Map<*, *>
    assertEquals("session-id", metadata["linkSessionId"])
    assertEquals(1, (metadata["accounts"] as List<*>).size)
  }

  @Test
  fun exitPayload_containsReactNativeShape() {
    val payload =
      exitPayload(
        error =
          errorPayload(
            errorType = "ITEM_ERROR",
            errorCode = "INVALID_CREDENTIALS",
            errorMessage = "Invalid credentials",
            displayMessage = "Try again",
            errorJson = "{}",
          ),
        metadata =
          exitMetadataPayload(
            status = "requires_credentials",
            institution = "",
            requestId = "request-id",
            linkSessionId = "session-id",
            metadataJson = "{}",
          ),
      )

    val error = payload["error"] as Map<*, *>
    val metadata = payload["metadata"] as Map<*, *>
    assertEquals("INVALID_CREDENTIALS", error["errorCode"])
    assertEquals("session-id", metadata["linkSessionId"])
  }

  @Test
  fun singleActiveDispatcher_onlyDispatchesToLatestHandler() {
    val dispatcher = SingleActiveDispatcher<String>()
    val received = mutableListOf<String>()
    val firstHandler: (String) -> Unit = { received.add("first:$it") }
    val secondHandler: (String) -> Unit = { received.add("second:$it") }

    dispatcher.register(firstHandler)
    dispatcher.register(secondHandler)
    dispatcher.dispatch("result")

    assertEquals(listOf("second:result"), received)
  }

  @Test
  fun singleActiveDispatcher_ignoresStaleUnregisters() {
    val dispatcher = SingleActiveDispatcher<String>()
    val received = mutableListOf<String>()
    val firstHandler: (String) -> Unit = { received.add("first:$it") }
    val secondHandler: (String) -> Unit = { received.add("second:$it") }

    dispatcher.register(firstHandler)
    dispatcher.register(secondHandler)
    dispatcher.unregister(firstHandler)
    dispatcher.dispatch("result")

    assertEquals(listOf("second:result"), received)
  }

  @Test
  fun eventMetadataPayload_includesRoutingNumberAndCoreFields() {
    val payload =
      eventPayload(
        eventName = "TRANSITION_VIEW",
        metadata =
          eventMetadataPayload(
            errorType = "",
            errorCode = "",
            errorMessage = "",
            exitStatus = "",
            institutionId = "ins_1",
            institutionName = "Plaid Bank",
            institutionSearchQuery = "",
            accountNumberMask = "",
            isUpdateMode = "true",
            matchReason = "",
            routingNumber = "110000000",
            selection = "",
            linkSessionId = "session-id",
            mfaType = "",
            requestId = "request-id",
            issueId = "",
            issueDescription = "",
            issueDetectedAt = "",
            timestamp = "2026-07-01T00:00:00Z",
            viewName = "CONNECTED",
            metadataJson = "{}",
          ),
      )

    assertEquals("TRANSITION_VIEW", payload["eventName"])
    val metadata = payload["metadata"] as Map<*, *>
    assertEquals("110000000", metadata["routingNumber"])
    assertEquals("true", metadata["isUpdateMode"])
    assertEquals("CONNECTED", metadata["viewName"])
    assertEquals("session-id", metadata["linkSessionId"])
  }

  @Test
  fun accountPayload_containsReactNativeShape() {
    val payload =
      accountPayload(
        id = "account-id",
        name = "Checking",
        mask = "0000",
        subtype = "checking",
        type = "depository",
        verificationStatus = "",
      )

    assertEquals("account-id", payload["id"])
    assertEquals("checking", payload["subtype"])
    assertEquals("depository", payload["type"])
  }
}
