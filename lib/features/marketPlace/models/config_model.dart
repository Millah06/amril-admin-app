
/// The AppConfig.payments block (multi-provider payments). Mirrors the API's
/// PaymentsConfig shape (src/config/paymentsConfig.ts). Every field is always
/// present client-side: fromJson merges whatever the API sends over the same
/// safe defaults the backend uses, so a null/partial block still renders.
class PaymentsConfigModel {
  // Collection (which methods the app's payment sheet may show)
  final bool walletEnabled;
  final bool opayEnabled; // the Opay flip — ON the day Opay approves
  final bool paystackEnabled;
  final bool monnifyEnabled;

  /// Which provider the app's smart "Card / Bank" row routes to.
  final String onlinePrimary; // opay | paystack | monnify

  // Withdrawal (payout registry)
  final String withdrawalPrimary; // paystack | flutterwave | monnify | opay
  final bool failoverEnabled;

  // Virtual accounts
  final bool vaPaystack;
  final bool vaMonnify; // KYC-gated — owner decided to keep OFF

  final String kycProvider; // monnify | dojah

  const PaymentsConfigModel({
    this.walletEnabled = true,
    this.opayEnabled = false,
    this.paystackEnabled = true,
    this.monnifyEnabled = false,
    this.onlinePrimary = 'paystack',
    this.withdrawalPrimary = 'paystack',
    this.failoverEnabled = false,
    this.vaPaystack = true,
    this.vaMonnify = false,
    this.kycProvider = 'monnify',
  });

  factory PaymentsConfigModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PaymentsConfigModel();
    final col = (json['collection'] ?? const {}) as Map<String, dynamic>;
    final wd = (json['withdrawal'] ?? const {}) as Map<String, dynamic>;
    final va = (json['virtualAccount'] ?? const {}) as Map<String, dynamic>;
    bool b(dynamic v, bool fallback) => v is bool ? v : fallback;
    return PaymentsConfigModel(
      walletEnabled: b((col['wallet'] as Map?)?['enabled'], true),
      opayEnabled: b((col['opay'] as Map?)?['enabled'], false),
      paystackEnabled: b((col['paystack'] as Map?)?['enabled'], true),
      monnifyEnabled: b((col['monnify'] as Map?)?['enabled'], false),
      onlinePrimary: (json['onlinePrimary'] ?? 'paystack').toString(),
      withdrawalPrimary: (wd['primary'] ?? 'paystack').toString(),
      failoverEnabled: b(wd['failoverEnabled'], false),
      vaPaystack: b(va['paystack'], true),
      vaMonnify: b(va['monnify'], false),
      kycProvider: (json['kycProvider'] ?? 'monnify').toString(),
    );
  }

  /// Wire shape the API's resolvePaymentsConfig expects (PATCH /admin/config
  /// `payments` key). onlinePrimary also drives paystack.primaryOnline so the
  /// stored block stays self-consistent.
  Map<String, dynamic> toJson() => {
    'collection': {
      'wallet': {'enabled': walletEnabled},
      'opay': {'enabled': opayEnabled},
      'paystack': {
        'enabled': paystackEnabled,
        'primaryOnline': onlinePrimary == 'paystack',
      },
      'monnify': {'enabled': monnifyEnabled},
    },
    'onlinePrimary': onlinePrimary,
    'withdrawal': {
      'primary': withdrawalPrimary,
      'failoverEnabled': failoverEnabled,
    },
    'virtualAccount': {'paystack': vaPaystack, 'monnify': vaMonnify},
    'kycProvider': kycProvider,
  };

  PaymentsConfigModel copyWith({
    bool? walletEnabled,
    bool? opayEnabled,
    bool? paystackEnabled,
    bool? monnifyEnabled,
    String? onlinePrimary,
    String? withdrawalPrimary,
    bool? failoverEnabled,
    bool? vaPaystack,
    bool? vaMonnify,
    String? kycProvider,
  }) {
    return PaymentsConfigModel(
      walletEnabled: walletEnabled ?? this.walletEnabled,
      opayEnabled: opayEnabled ?? this.opayEnabled,
      paystackEnabled: paystackEnabled ?? this.paystackEnabled,
      monnifyEnabled: monnifyEnabled ?? this.monnifyEnabled,
      onlinePrimary: onlinePrimary ?? this.onlinePrimary,
      withdrawalPrimary: withdrawalPrimary ?? this.withdrawalPrimary,
      failoverEnabled: failoverEnabled ?? this.failoverEnabled,
      vaPaystack: vaPaystack ?? this.vaPaystack,
      vaMonnify: vaMonnify ?? this.vaMonnify,
      kycProvider: kycProvider ?? this.kycProvider,
    );
  }
}

/// The AppConfig.hardwareUpdate block (hardware OTA self-update, kiosk roadmap
/// Phase 2). Devices poll GET /config/hardware-update and self-install the APK
/// at [apkUrl] after verifying [sha256]. Empty latestVersion = nothing
/// published (the API stores null).
class HardwareUpdateModel {
  final String latestVersion;
  final String apkUrl;
  final String sha256;
  final bool mandatory;
  final String minSupportedVersion;
  final String notes;

  const HardwareUpdateModel({
    this.latestVersion = '',
    this.apkUrl = '',
    this.sha256 = '',
    this.mandatory = false,
    this.minSupportedVersion = '',
    this.notes = '',
  });

  bool get isPublished => latestVersion.isNotEmpty;

  factory HardwareUpdateModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HardwareUpdateModel();
    return HardwareUpdateModel(
      latestVersion: (json['latestVersion'] ?? '').toString(),
      apkUrl: (json['apkUrl'] ?? '').toString(),
      sha256: (json['sha256'] ?? '').toString(),
      mandatory: json['mandatory'] == true,
      minSupportedVersion: (json['minSupportedVersion'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
    );
  }

  /// Wire shape for PATCH /admin/config `hardwareUpdate`. Null clears the
  /// published update (the API treats an empty latestVersion the same way).
  Map<String, dynamic>? toJson() => isPublished
      ? {
          'latestVersion': latestVersion,
          'apkUrl': apkUrl,
          'sha256': sha256,
          'mandatory': mandatory,
          'minSupportedVersion': minSupportedVersion,
          'notes': notes,
        }
      : null;
}

/// The AppConfig.appUpdate block — consumer (Play / App Store) update prompt.
/// The app compares [latestBuild] against its running build number; empty /
/// latestBuild<=0 = nothing published (API stores null).
class AppUpdateModel {
  final int latestBuild;
  final String versionName;
  final List<String> whatsNew;
  final bool mandatory;
  final String androidUrl;
  final String iosUrl;

  const AppUpdateModel({
    this.latestBuild = 0,
    this.versionName = '',
    this.whatsNew = const [],
    this.mandatory = false,
    this.androidUrl = '',
    this.iosUrl = '',
  });

  bool get isPublished => latestBuild > 0;

  factory AppUpdateModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppUpdateModel();
    return AppUpdateModel(
      latestBuild: (json['latestBuild'] as num?)?.toInt() ?? 0,
      versionName: (json['versionName'] ?? '').toString(),
      whatsNew: json['whatsNew'] is List
          ? (json['whatsNew'] as List).map((e) => e.toString()).toList()
          : const [],
      mandatory: json['mandatory'] == true,
      androidUrl: (json['androidUrl'] ?? '').toString(),
      iosUrl: (json['iosUrl'] ?? '').toString(),
    );
  }

  /// Wire shape for PATCH /admin/config `appUpdate`; null clears.
  Map<String, dynamic>? toJson() => isPublished
      ? {
          'latestBuild': latestBuild,
          'versionName': versionName,
          'whatsNew': whatsNew,
          'mandatory': mandatory,
          'androidUrl': androidUrl,
          'iosUrl': iosUrl,
        }
      : null;
}

/// The AppConfig.delivery block (per-km delivery roadmap Phase 9): global
/// knobs for the pure-math fee engine. Empty min/max text = no bound (vendors
/// price freely on that side). Ranges clamp vendor rates at READ time in the
/// fee engine — editing them here never requires a data migration.
class DeliveryConfigModel {
  final double? baseFeeMin;
  final double? baseFeeMax;
  final double? perKmMin;
  final double? perKmMax;
  final double? maxRadiusKm; // null = api default (30)
  final double? roadFactor; // null = api default (1.3)

  const DeliveryConfigModel({
    this.baseFeeMin,
    this.baseFeeMax,
    this.perKmMin,
    this.perKmMax,
    this.maxRadiusKm,
    this.roadFactor,
  });

  factory DeliveryConfigModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DeliveryConfigModel();
    double? n(dynamic v) => v is num ? v.toDouble() : null;
    return DeliveryConfigModel(
      baseFeeMin: n(json['baseFeeMin']),
      baseFeeMax: n(json['baseFeeMax']),
      perKmMin: n(json['perKmMin']),
      perKmMax: n(json['perKmMax']),
      maxRadiusKm: n(json['maxRadiusKm']),
      roadFactor: n(json['roadFactor']),
    );
  }

  /// Wire shape for PATCH /admin/config `delivery`. Absent keys are simply
  /// not stored (the fee engine falls back to its hardcoded defaults).
  Map<String, dynamic> toJson() => {
        if (baseFeeMin != null) 'baseFeeMin': baseFeeMin,
        if (baseFeeMax != null) 'baseFeeMax': baseFeeMax,
        if (perKmMin != null) 'perKmMin': perKmMin,
        if (perKmMax != null) 'perKmMax': perKmMax,
        if (maxRadiusKm != null) 'maxRadiusKm': maxRadiusKm,
        if (roadFactor != null) 'roadFactor': roadFactor,
      };
}

class ConfigModel {

  final String id;
  final double transactionFeePercent;  // 0 at launch — update here to change globally
  final int autoReleaseHours;
  final int appealWindowHours;
  final double chatCloseHours;
  final double commissionPercent;
  final double fundingFees;
  final double bonusAirtime;
  final double bonusData;
  final double bonusCable;
  final double bonusElectric;

  // Fee model (Workstream E)
  final double withdrawalFeePercent;
  final double withdrawalFlatFeeNaira;
  final bool netGatewayFromVendor;
  // Hardware program (Workstream A)
  final bool hardwareReservationMode;
  final bool brandingAvailable;
  // Multi-provider payments (Phase 5 admin UI)
  final PaymentsConfigModel payments;
  // Hardware OTA self-update (kiosk roadmap Phase 2)
  final HardwareUpdateModel hardwareUpdate;
  // Consumer app update (Play / App Store prompt)
  final AppUpdateModel appUpdate;
  // Per-km delivery knobs (delivery roadmap Phase 9)
  final DeliveryConfigModel delivery;

  ConfigModel(
    {
      required this.id,
      required this.transactionFeePercent,
      required this.autoReleaseHours,
      required this.appealWindowHours,
      required this.chatCloseHours,
      required this.commissionPercent,
      required this.fundingFees,
      required this.bonusAirtime,
      required this.bonusData,
      required this.bonusCable,
      required this.bonusElectric,
      this.withdrawalFeePercent = 0,
      this.withdrawalFlatFeeNaira = 0,
      this.netGatewayFromVendor = true,
      this.hardwareReservationMode = true,
      this.brandingAvailable = false,
      this.payments = const PaymentsConfigModel(),
      this.hardwareUpdate = const HardwareUpdateModel(),
      this.appUpdate = const AppUpdateModel(),
      this.delivery = const DeliveryConfigModel(),
    }
  );

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
        id: json['id'],
        transactionFeePercent: (json['transactionFeePercent'] ?? 0).toDouble(),
        autoReleaseHours: (json['autoReleaseHours'] ?? 0).toInt(),
        appealWindowHours: (json['appealWindowHours'] ?? 0).toInt(),
        chatCloseHours: (json['chatCloseHours'] ?? 0).toDouble(),
        commissionPercent: (json['commissionPercent'] ?? 0).toDouble(),
        fundingFees: (json['fundingFees'] ?? 0).toDouble(),
        bonusAirtime: (json['bonusAirtime'] ?? 0).toDouble(),
        bonusData: (json['bonusData'] ?? 0).toDouble(),
        bonusCable: (json['bonusCable'] ?? 0).toDouble(),
        bonusElectric: (json['bonusElectric'] ?? 0).toDouble(),
        withdrawalFeePercent: (json['withdrawalFeePercent'] ?? 0).toDouble(),
        withdrawalFlatFeeNaira: (json['withdrawalFlatFeeNaira'] ?? 0).toDouble(),
        netGatewayFromVendor: json['netGatewayFromVendor'] ?? true,
        hardwareReservationMode: json['hardwareReservationMode'] ?? true,
        brandingAvailable: json['brandingAvailable'] ?? false,
        payments: PaymentsConfigModel.fromJson(
            json['payments'] is Map<String, dynamic>
                ? json['payments'] as Map<String, dynamic>
                : null),
        hardwareUpdate: HardwareUpdateModel.fromJson(
            json['hardwareUpdate'] is Map<String, dynamic>
                ? json['hardwareUpdate'] as Map<String, dynamic>
                : null),
        appUpdate: AppUpdateModel.fromJson(
            json['appUpdate'] is Map<String, dynamic>
                ? json['appUpdate'] as Map<String, dynamic>
                : null),
        delivery: DeliveryConfigModel.fromJson(
            json['delivery'] is Map<String, dynamic>
                ? json['delivery'] as Map<String, dynamic>
                : null)
    );
  }

  Map<String, dynamic> toJson() => {
    'transactionFeePercent': transactionFeePercent,
    'autoReleaseHours': autoReleaseHours,
    'appealWindowHours': appealWindowHours,
    'chatCloseHours': chatCloseHours,
    'commissionPercent': commissionPercent,
    'fundingFees': fundingFees,
    'bonusAirtime': bonusAirtime,
    'bonusData': bonusData,
    'bonusCable': bonusCable,
    'bonusElectric': bonusElectric,
  };


}