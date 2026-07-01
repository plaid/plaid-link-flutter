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
}
