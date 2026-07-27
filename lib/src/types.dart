class LinkSuccess {
  const LinkSuccess({required this.publicToken, required this.metadata});

  factory LinkSuccess.fromMap(Map<Object?, Object?> map) {
    return LinkSuccess(
      publicToken: map.stringValue('publicToken'),
      metadata: LinkSuccessMetadata.fromMap(map.mapValue('metadata')),
    );
  }

  final String publicToken;
  final LinkSuccessMetadata metadata;
}

class LinkSuccessMetadata {
  const LinkSuccessMetadata({
    required this.accounts,
    required this.linkSessionId,
    this.institution,
    this.metadataJson,
  });

  factory LinkSuccessMetadata.fromMap(Map<Object?, Object?> map) {
    return LinkSuccessMetadata(
      accounts:
          map.listValue('accounts').map((value) {
            return LinkAccount.fromMap(value.asMap());
          }).toList(),
      institution: map
          .optionalMapValue('institution')
          ?.let(LinkInstitution.fromMap),
      linkSessionId: map.stringValue('linkSessionId'),
      metadataJson: map.optionalStringValue('metadataJson'),
    );
  }

  final LinkInstitution? institution;
  final List<LinkAccount> accounts;
  final String linkSessionId;
  final String? metadataJson;
}

class LinkExit {
  const LinkExit({this.error, required this.metadata});

  factory LinkExit.fromMap(Map<Object?, Object?> map) {
    return LinkExit(
      error: map.optionalMapValue('error')?.let(LinkError.fromMap),
      metadata: LinkExitMetadata.fromMap(map.mapValue('metadata')),
    );
  }

  final LinkError? error;
  final LinkExitMetadata metadata;
}

class LinkExitMetadata {
  const LinkExitMetadata({
    required this.linkSessionId,
    required this.requestId,
    this.status,
    this.institution,
    this.metadataJson,
  });

  factory LinkExitMetadata.fromMap(Map<Object?, Object?> map) {
    return LinkExitMetadata(
      status: map.optionalStringValue('status'),
      institution: map
          .optionalMapValue('institution')
          ?.let(LinkInstitution.fromMap),
      linkSessionId: map.stringValue('linkSessionId'),
      requestId: map.stringValue('requestId'),
      metadataJson: map.optionalStringValue('metadataJson'),
    );
  }

  final String? status;
  final LinkInstitution? institution;
  final String linkSessionId;
  final String requestId;
  final String? metadataJson;
}

class LinkEvent {
  const LinkEvent({required this.eventName, required this.metadata});

  factory LinkEvent.fromMap(Map<Object?, Object?> map) {
    return LinkEvent(
      eventName: map.stringValue('eventName'),
      metadata: LinkEventMetadata.fromMap(map.mapValue('metadata')),
    );
  }

  final String eventName;
  final LinkEventMetadata metadata;
}

class LinkEventMetadata {
  const LinkEventMetadata({
    required this.linkSessionId,
    required this.viewName,
    this.timestamp,
    this.accountNumberMask,
    this.mfaType,
    this.requestId,
    this.errorCode,
    this.errorMessage,
    this.errorType,
    this.exitStatus,
    this.institutionId,
    this.institutionName,
    this.institutionSearchQuery,
    this.isUpdateMode,
    this.matchReason,
    this.routingNumber,
    this.issueId,
    this.issueDescription,
    this.issueDetectedAt,
    this.selection,
    this.metadataJson,
  });

  factory LinkEventMetadata.fromMap(Map<Object?, Object?> map) {
    return LinkEventMetadata(
      accountNumberMask: map.optionalStringValue('accountNumberMask'),
      linkSessionId: map.stringValue('linkSessionId'),
      mfaType: map.optionalStringValue('mfaType'),
      requestId: map.optionalStringValue('requestId'),
      viewName: map.stringValue('viewName'),
      errorCode: map.optionalStringValue('errorCode'),
      errorMessage: map.optionalStringValue('errorMessage'),
      errorType: map.optionalStringValue('errorType'),
      exitStatus: map.optionalStringValue('exitStatus'),
      institutionId: map.optionalStringValue('institutionId'),
      institutionName: map.optionalStringValue('institutionName'),
      institutionSearchQuery: map.optionalStringValue('institutionSearchQuery'),
      isUpdateMode: map.boolValue('isUpdateMode'),
      matchReason: map.optionalStringValue('matchReason'),
      routingNumber: map.optionalStringValue('routingNumber'),
      issueId: map.optionalStringValue('issueId'),
      issueDescription: map.optionalStringValue('issueDescription'),
      issueDetectedAt: map.optionalStringValue('issueDetectedAt'),
      selection: map.optionalStringValue('selection'),
      timestamp: map.dateTimeValue('timestamp'),
      metadataJson:
          map.optionalStringValue('metadataJson') ??
          map.optionalStringValue('metadata_json'),
    );
  }

  final String? accountNumberMask;
  final String linkSessionId;
  final String? mfaType;
  final String? requestId;
  final String viewName;
  final String? errorCode;
  final String? errorMessage;
  final String? errorType;
  final String? exitStatus;
  final String? institutionId;
  final String? institutionName;
  final String? institutionSearchQuery;
  final bool? isUpdateMode;
  final String? matchReason;
  final String? routingNumber;
  final String? issueId;
  final String? issueDescription;
  final String? issueDetectedAt;
  final String? selection;
  final DateTime? timestamp;
  final String? metadataJson;
}

class LinkError {
  const LinkError({
    required this.errorCode,
    required this.errorType,
    required this.errorMessage,
    this.displayMessage,
    this.errorJson,
  });

  factory LinkError.fromMap(Map<Object?, Object?> map) {
    return LinkError(
      errorCode: map.stringValue('errorCode'),
      errorType: map.stringValue('errorType'),
      errorMessage: map.stringValue('errorMessage'),
      displayMessage: map.optionalStringValue('displayMessage'),
      errorJson: map.optionalStringValue('errorJson'),
    );
  }

  final String errorCode;
  final String errorType;
  final String errorMessage;
  final String? displayMessage;
  final String? errorJson;
}

class LinkInstitution {
  const LinkInstitution({required this.id, required this.name});

  factory LinkInstitution.fromMap(Map<Object?, Object?> map) {
    return LinkInstitution(
      id: map.stringValue('id'),
      name: map.stringValue('name'),
    );
  }

  final String id;
  final String name;
}

class LinkAccount {
  const LinkAccount({
    required this.id,
    required this.type,
    required this.subtype,
    this.name,
    this.mask,
    this.verificationStatus,
  });

  factory LinkAccount.fromMap(Map<Object?, Object?> map) {
    return LinkAccount(
      id: map.stringValue('id'),
      name: map.optionalStringValue('name'),
      mask: map.optionalStringValue('mask'),
      type: map.stringValue('type'),
      subtype: map.stringValue('subtype'),
      verificationStatus: map.optionalStringValue('verificationStatus'),
    );
  }

  final String id;
  final String? name;
  final String? mask;
  final String type;
  final String subtype;
  final String? verificationStatus;
}

class SubmissionData {
  const SubmissionData({this.phoneNumber, this.dateOfBirth, this.params});

  final String? phoneNumber;
  final String? dateOfBirth;
  final Map<String, String>? params;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'params': params,
    };
  }
}

class FinanceKitConfiguration {
  const FinanceKitConfiguration({
    required this.token,
    this.requestAuthorizationIfNeeded = true,
    this.syncBehavior = FinanceKitSyncBehavior.live,
  });

  final String token;
  final bool requestAuthorizationIfNeeded;
  final FinanceKitSyncBehavior syncBehavior;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'token': token,
      'requestAuthorizationIfNeeded': requestAuthorizationIfNeeded,
      'syncBehavior': syncBehavior.value,
    };
  }
}

enum FinanceKitSyncBehavior {
  live(0),
  simulated(1);

  const FinanceKitSyncBehavior(this.value);

  final int value;
}

enum FinanceKitErrorType {
  invalidToken(0),
  permissionError(1),
  linkApiError(2),
  permissionAccessError(3),
  unsupportedAndroid(4),
  unsupportedIosVersion(5),
  unknown(6);

  const FinanceKitErrorType(this.value);

  factory FinanceKitErrorType.fromCode(String code) {
    return switch (code) {
      'INVALID_TOKEN' => FinanceKitErrorType.invalidToken,
      'PERMISSION_ERROR' => FinanceKitErrorType.permissionError,
      'LINK_API_ERROR' => FinanceKitErrorType.linkApiError,
      'PERMISSION_ACCESS_ERROR' => FinanceKitErrorType.permissionAccessError,
      'UNSUPPORTED_ANDROID' => FinanceKitErrorType.unsupportedAndroid,
      'UNSUPPORTED_IOS_VERSION' => FinanceKitErrorType.unsupportedIosVersion,
      _ => FinanceKitErrorType.unknown,
    };
  }

  final int value;
}

class FinanceKitException implements Exception {
  const FinanceKitException({
    required this.type,
    required this.code,
    required this.message,
  });

  factory FinanceKitException.fromPlatformException(dynamic error) {
    final code = error.code?.toString() ?? 'UNKNOWN';
    return FinanceKitException(
      type: FinanceKitErrorType.fromCode(code),
      code: code,
      message: error.message?.toString() ?? 'FinanceKit sync failed.',
    );
  }

  final FinanceKitErrorType type;
  final String code;
  final String message;

  @override
  String toString() => 'FinanceKitException($code): $message';
}

/// Typed error codes thrown by Link session create/open/submit calls.
///
/// The raw platform [code] string is always preserved on [PlaidLinkException];
/// [unknown] is used for any code not modeled here so new native codes never
/// crash a consumer that switches on [type].
enum PlaidLinkErrorType {
  invalidToken('INVALID_TOKEN'),
  linkSessionCreateError('LINK_SESSION_CREATE_ERROR'),
  layerSessionCreateError('LAYER_SESSION_CREATE_ERROR'),
  headlessSessionCreateError('HEADLESS_SESSION_CREATE_ERROR'),
  noActivity('PLAID_NO_ACTIVITY'),
  noViewController('PLAID_NO_VC'),
  noLayerSession('PLAID_NO_LAYER_SESSION'),
  noSession('PLAID_NO_SESSION'),
  openError('PLAID_OPEN_ERROR'),
  unknown('UNKNOWN');

  const PlaidLinkErrorType(this.code);

  factory PlaidLinkErrorType.fromCode(String code) {
    for (final type in PlaidLinkErrorType.values) {
      if (type.code == code) {
        return type;
      }
    }
    return PlaidLinkErrorType.unknown;
  }

  final String code;
}

/// Thrown by [createPlaidLinkSession], the session `open`/`start`/`submit`
/// calls, mirroring [FinanceKitException] so Link errors are typed rather than
/// raw `PlatformException`s.
class PlaidLinkException implements Exception {
  const PlaidLinkException({
    required this.type,
    required this.code,
    required this.message,
    this.details,
  });

  factory PlaidLinkException.fromPlatformException(dynamic error) {
    final code = error.code?.toString() ?? 'UNKNOWN';
    return PlaidLinkException(
      type: PlaidLinkErrorType.fromCode(code),
      code: code,
      message: error.message?.toString() ?? 'Plaid Link operation failed.',
      details: error.details,
    );
  }

  final PlaidLinkErrorType type;
  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'PlaidLinkException($code): $message';
}

extension _Let<T extends Object> on T {
  R let<R>(R Function(T value) transform) => transform(this);
}

extension _MapParsing on Map<Object?, Object?> {
  String stringValue(String key) => optionalStringValue(key) ?? '';

  String? optionalStringValue(String key) {
    final value = this[key];
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  bool? boolValue(String key) {
    final value = this[key];
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    return switch (value.toString().toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }

  DateTime? dateTimeValue(String key) {
    final value = optionalStringValue(key);
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Map<Object?, Object?> mapValue(String key) {
    return optionalMapValue(key) ?? <Object?, Object?>{};
  }

  Map<Object?, Object?>? optionalMapValue(String key) {
    final value = this[key];
    if (value == null || value == '') {
      return null;
    }
    return value.asMap();
  }

  List<Object?> listValue(String key) {
    final value = this[key];
    if (value is List<Object?>) {
      return value;
    }
    if (value is List) {
      return value.cast<Object?>();
    }
    return const <Object?>[];
  }
}

extension _ObjectParsing on Object? {
  Map<Object?, Object?> asMap() {
    final value = this;
    if (value is Map<Object?, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.cast<Object?, Object?>();
    }
    return <Object?, Object?>{};
  }
}
