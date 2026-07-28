/// Base for the string-backed "open enum" wrappers below. Known values are
/// exposed as constants; any value Plaid adds later is preserved verbatim in
/// [value], so it never crashes a consumer that switches on it.
abstract class _WireValue {
  const _WireValue(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is _WireValue &&
      other.runtimeType == runtimeType &&
      other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => '$runtimeType($value)';
}

/// Link `onEvent` event name. Known values are provided as constants; unrecognized values are preserved in [value].
final class LinkEventName extends _WireValue {
  const LinkEventName(super.value);

  static const autoSelectSavedInstitution = LinkEventName(
    'AUTO_SELECT_SAVED_INSTITUTION',
  );
  static const autoSubmitPhone = LinkEventName('AUTO_SUBMIT_PHONE');
  static const bankIncomeInsightsCompleted = LinkEventName(
    'BANK_INCOME_INSIGHTS_COMPLETED',
  );
  static const closeOauth = LinkEventName('CLOSE_OAUTH');
  static const connectNewInstitution = LinkEventName('CONNECT_NEW_INSTITUTION');
  static const error = LinkEventName('ERROR');
  static const exit = LinkEventName('EXIT');
  static const failOauth = LinkEventName('FAIL_OAUTH');
  static const handoff = LinkEventName('HANDOFF');
  static const identityMatchPassed = LinkEventName('IDENTITY_MATCH_PASSED');
  static const identityMatchFailed = LinkEventName('IDENTITY_MATCH_FAILED');
  static const identityVerificationCloseUi = LinkEventName(
    'IDENTITY_VERIFICATION_CLOSE_UI',
  );
  static const identityVerificationCreateSession = LinkEventName(
    'IDENTITY_VERIFICATION_CREATE_SESSION',
  );
  static const identityVerificationFailSession = LinkEventName(
    'IDENTITY_VERIFICATION_FAIL_SESSION',
  );
  static const identityVerificationFailStep = LinkEventName(
    'IDENTITY_VERIFICATION_FAIL_STEP',
  );
  static const identityVerificationOpenUi = LinkEventName(
    'IDENTITY_VERIFICATION_OPEN_UI',
  );
  static const identityVerificationPassSession = LinkEventName(
    'IDENTITY_VERIFICATION_PASS_SESSION',
  );
  static const identityVerificationPassStep = LinkEventName(
    'IDENTITY_VERIFICATION_PASS_STEP',
  );
  static const identityVerificationPendingReviewSession = LinkEventName(
    'IDENTITY_VERIFICATION_PENDING_REVIEW_SESSION',
  );
  static const identityVerificationPendingReviewStep = LinkEventName(
    'IDENTITY_VERIFICATION_PENDING_REVIEW_STEP',
  );
  static const identityVerificationResumeSession = LinkEventName(
    'IDENTITY_VERIFICATION_RESUME_SESSION',
  );
  static const identityVerificationResumeUi = LinkEventName(
    'IDENTITY_VERIFICATION_RESUME_UI',
  );
  static const identityVerificationStartStep = LinkEventName(
    'IDENTITY_VERIFICATION_START_STEP',
  );
  static const issueFollowed = LinkEventName('ISSUE_FOLLOWED');
  static const layerAutofillNotAvailable = LinkEventName(
    'LAYER_AUTOFILL_NOT_AVAILABLE',
  );
  static const layerNotAvailable = LinkEventName('LAYER_NOT_AVAILABLE');
  static const layerReady = LinkEventName('LAYER_READY');
  static const matchedSelectInstitution = LinkEventName(
    'MATCHED_SELECT_INSTITUTION',
  );
  static const matchedSelectVerifyMethod = LinkEventName(
    'MATCHED_SELECT_VERIFY_METHOD',
  );
  static const open = LinkEventName('OPEN');
  static const openMyPlaid = LinkEventName('OPEN_MY_PLAID');
  static const openOauth = LinkEventName('OPEN_OAUTH');
  static const plaidCheckPane = LinkEventName('PLAID_CHECK_PANE');
  static const profileEligibilityCheckError = LinkEventName(
    'PROFILE_ELIGIBILITY_CHECK_ERROR',
  );
  static const profileEligibilityCheckReady = LinkEventName(
    'PROFILE_ELIGIBILITY_CHECK_READY',
  );
  static const rememberMeDisabled = LinkEventName('REMEMBER_ME_DISABLED');
  static const rememberMeEnabled = LinkEventName('REMEMBER_ME_ENABLED');
  static const rememberMeHoldout = LinkEventName('REMEMBER_ME_HOLDOUT');
  static const searchInstitution = LinkEventName('SEARCH_INSTITUTION');
  static const selectAccount = LinkEventName('SELECT_ACCOUNT');
  static const selectAuthType = LinkEventName('SELECT_AUTH_TYPE');
  static const selectBrand = LinkEventName('SELECT_BRAND');
  static const selectDegradedInstitution = LinkEventName(
    'SELECT_DEGRADED_INSTITUTION',
  );
  static const selectDenylistedInstitution = LinkEventName(
    'SELECT_DENYLISTED_INSTITUTION',
  );
  static const selectDownInstitution = LinkEventName('SELECT_DOWN_INSTITUTION');
  static const selectFallbackRoutingInstitution = LinkEventName(
    'SELECT_FALLBACK_ROUTING_INSTITUTION',
  );
  static const selectFilteredInstitution = LinkEventName(
    'SELECT_FILTERED_INSTITUTION',
  );
  static const selectInstitution = LinkEventName('SELECT_INSTITUTION');
  static const selectRememberMeDuplicateInstitution = LinkEventName(
    'SELECT_REMEMBER_ME_DUPLICATE_INSTITUTION',
  );
  static const selectSavedAccount = LinkEventName('SELECT_SAVED_ACCOUNT');
  static const selectSavedInstitution = LinkEventName(
    'SELECT_SAVED_INSTITUTION',
  );
  static const skipSubmitEmail = LinkEventName('SKIP_SUBMIT_EMAIL');
  static const skipSubmitPhone = LinkEventName('SKIP_SUBMIT_PHONE');
  static const submitAccountNumber = LinkEventName('SUBMIT_ACCOUNT_NUMBER');
  static const submitCredentials = LinkEventName('SUBMIT_CREDENTIALS');
  static const submitDocuments = LinkEventName('SUBMIT_DOCUMENTS');
  static const submitDocumentsError = LinkEventName('SUBMIT_DOCUMENTS_ERROR');
  static const submitDocumentsSuccess = LinkEventName(
    'SUBMIT_DOCUMENTS_SUCCESS',
  );
  static const submitEmail = LinkEventName('SUBMIT_EMAIL');
  static const submitMfa = LinkEventName('SUBMIT_MFA');
  static const submitOtp = LinkEventName('SUBMIT_OTP');
  static const submitPhone = LinkEventName('SUBMIT_PHONE');
  static const submitRoutingNumber = LinkEventName('SUBMIT_ROUTING_NUMBER');
  static const transitionView = LinkEventName('TRANSITION_VIEW');
  static const verifyPhone = LinkEventName('VERIFY_PHONE');
  static const viewDataTypes = LinkEventName('VIEW_DATA_TYPES');
}

/// Link view name reported on `TRANSITION_VIEW` events.
final class LinkViewName extends _WireValue {
  const LinkViewName(super.value);

  static const acceptTos = LinkViewName('ACCEPT_TOS');
  static const bankIncomeInsightsCompleted = LinkViewName(
    'BANK_INCOME_INSIGHTS_COMPLETED',
  );
  static const connected = LinkViewName('CONNECTED');
  static const consent = LinkViewName('CONSENT');
  static const credential = LinkViewName('CREDENTIAL');
  static const craConsent = LinkViewName('CRA_CONSENT');
  static const dataTransparency = LinkViewName('DATA_TRANSPARENCY');
  static const dataTransparencyConsent = LinkViewName(
    'DATA_TRANSPARENCY_CONSENT',
  );
  static const dataTransparencyMessagingModal = LinkViewName(
    'DATA_TRANSPARENCY_MESSAGING_MODAL',
  );
  static const documentaryVerification = LinkViewName(
    'DOCUMENTARY_VERIFICATION',
  );
  static const error = LinkViewName('ERROR');
  static const exit = LinkViewName('EXIT');
  static const identityMatchBlock = LinkViewName('IDENTITY_MATCH_BLOCK');
  static const instantMicrodepositAuthorized = LinkViewName(
    'INSTANT_MICRODEPOSIT_AUTHORIZED',
  );
  static const instantMicrodepositVerification = LinkViewName(
    'INSTANT_MICRODEPOSIT_VERIFICATION',
  );
  static const kycCheck = LinkViewName('KYC_CHECK');
  static const loading = LinkViewName('LOADING');
  static const matchedConsent = LinkViewName('MATCHED_CONSENT');
  static const matchedCredential = LinkViewName('MATCHED_CREDENTIAL');
  static const matchedMfa = LinkViewName('MATCHED_MFA');
  static const mfa = LinkViewName('MFA');
  static const numbers = LinkViewName('NUMBERS');
  static const numbersSelectInstitution = LinkViewName(
    'NUMBERS_SELECT_INSTITUTION',
  );
  static const oauth = LinkViewName('OAUTH');
  static const profileDataReview = LinkViewName('PROFILE_DATA_REVIEW');
  static const recaptcha = LinkViewName('RECAPTCHA');
  static const riskCheck = LinkViewName('RISK_CHECK');
  static const sameDayMicrodepositAuthorized = LinkViewName(
    'SAME_DAY_MICRODEPOSIT_AUTHORIZED',
  );
  static const sameDayMicrodepositVerification = LinkViewName(
    'SAME_DAY_MICRODEPOSIT_VERIFICATION',
  );
  static const screening = LinkViewName('SCREENING');
  static const selectAccount = LinkViewName('SELECT_ACCOUNT');
  static const selectAuthType = LinkViewName('SELECT_AUTH_TYPE');
  static const selectBrand = LinkViewName('SELECT_BRAND');
  static const selectInstitution = LinkViewName('SELECT_INSTITUTION');
  static const selectSavedAccount = LinkViewName('SELECT_SAVED_ACCOUNT');
  static const selectSavedInstitution = LinkViewName(
    'SELECT_SAVED_INSTITUTION',
  );
  static const selfieCheck = LinkViewName('SELFIE_CHECK');
  static const submitDocuments = LinkViewName('SUBMIT_DOCUMENTS');
  static const submitDocumentsError = LinkViewName('SUBMIT_DOCUMENTS_ERROR');
  static const submitDocumentsSuccess = LinkViewName(
    'SUBMIT_DOCUMENTS_SUCCESS',
  );
  static const submitEmail = LinkViewName('SUBMIT_EMAIL');
  static const submitPhone = LinkViewName('SUBMIT_PHONE');
  static const transferStatusCheck = LinkViewName('TRANSFER_STATUS_CHECK');
  static const uploadDocuments = LinkViewName('UPLOAD_DOCUMENTS');
  static const verifyEmail = LinkViewName('VERIFY_EMAIL');
  static const verifyPhone = LinkViewName('VERIFY_PHONE');
  static const verifySms = LinkViewName('VERIFY_SMS');
}

/// Status describing where the user was when Link exited.
final class LinkExitStatus extends _WireValue {
  const LinkExitStatus(super.value);

  static const connected = LinkExitStatus('connected');
  static const chooseDevice = LinkExitStatus('choose_device');
  static const requiresAccountSelection = LinkExitStatus(
    'requires_account_selection',
  );
  static const requiresCode = LinkExitStatus('requires_code');
  static const requiresCredentials = LinkExitStatus('requires_credentials');
  static const requiresExternalAction = LinkExitStatus(
    'requires_external_action',
  );
  static const requiresOauth = LinkExitStatus('requires_oauth');
  static const requiresQuestions = LinkExitStatus('requires_questions');
  static const requiresRecaptcha = LinkExitStatus('requires_recaptcha');
  static const requiresSelections = LinkExitStatus('requires_selections');
  static const requiresDepositSwitchAllocationConfiguration = LinkExitStatus(
    'requires_deposit_switch_allocation_configuration',
  );
  static const requiresDepositSwitchAllocationSelection = LinkExitStatus(
    'requires_deposit_switch_allocation_selection',
  );
}

/// Micro-deposit verification status for an account.
final class LinkVerificationStatus extends _WireValue {
  const LinkVerificationStatus(super.value);

  static const pendingAutomaticVerification = LinkVerificationStatus(
    'pending_automatic_verification',
  );
  static const pendingManualVerification = LinkVerificationStatus(
    'pending_manual_verification',
  );
  static const manuallyVerified = LinkVerificationStatus('manually_verified');
}

/// Broad category of a Link error.
final class LinkErrorType extends _WireValue {
  const LinkErrorType(super.value);

  static const bankTransferError = LinkErrorType('BANK_TRANSFER_ERROR');
  static const invalidRequest = LinkErrorType('INVALID_REQUEST');
  static const invalidResult = LinkErrorType('INVALID_RESULT');
  static const invalidInput = LinkErrorType('INVALID_INPUT');
  static const institutionError = LinkErrorType('INSTITUTION_ERROR');
  static const rateLimitExceeded = LinkErrorType('RATE_LIMIT_EXCEEDED');
  static const apiError = LinkErrorType('API_ERROR');
  static const itemError = LinkErrorType('ITEM_ERROR');
  static const authError = LinkErrorType('AUTH_ERROR');
  static const assetReportError = LinkErrorType('ASSET_REPORT_ERROR');
  static const sandboxError = LinkErrorType('SANDBOX_ERROR');
  static const recaptchaError = LinkErrorType('RECAPTCHA_ERROR');
  static const oauthError = LinkErrorType('OAUTH_ERROR');
}

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
      status: map.optionalStringValue('status')?.let(LinkExitStatus.new),
      institution: map
          .optionalMapValue('institution')
          ?.let(LinkInstitution.fromMap),
      linkSessionId: map.stringValue('linkSessionId'),
      requestId: map.stringValue('requestId'),
      metadataJson: map.optionalStringValue('metadataJson'),
    );
  }

  final LinkExitStatus? status;
  final LinkInstitution? institution;
  final String linkSessionId;
  final String requestId;
  final String? metadataJson;
}

class LinkEvent {
  const LinkEvent({required this.eventName, required this.metadata});

  factory LinkEvent.fromMap(Map<Object?, Object?> map) {
    return LinkEvent(
      eventName: LinkEventName(map.stringValue('eventName')),
      metadata: LinkEventMetadata.fromMap(map.mapValue('metadata')),
    );
  }

  final LinkEventName eventName;
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
      viewName: LinkViewName(map.stringValue('viewName')),
      errorCode: map.optionalStringValue('errorCode'),
      errorMessage: map.optionalStringValue('errorMessage'),
      errorType: map.optionalStringValue('errorType')?.let(LinkErrorType.new),
      exitStatus: map
          .optionalStringValue('exitStatus')
          ?.let(LinkExitStatus.new),
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
  final LinkViewName viewName;
  final String? errorCode;
  final String? errorMessage;
  final LinkErrorType? errorType;
  final LinkExitStatus? exitStatus;
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
      errorType: LinkErrorType(map.stringValue('errorType')),
      errorMessage: map.stringValue('errorMessage'),
      displayMessage: map.optionalStringValue('displayMessage'),
      errorJson: map.optionalStringValue('errorJson'),
    );
  }

  final String errorCode;
  final LinkErrorType errorType;
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
      verificationStatus: map
          .optionalStringValue('verificationStatus')
          ?.let(LinkVerificationStatus.new),
    );
  }

  final String id;
  final String? name;
  final String? mask;
  final String type;
  final String subtype;
  final LinkVerificationStatus? verificationStatus;
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
  submitError('PLAID_SUBMIT_ERROR'),
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
