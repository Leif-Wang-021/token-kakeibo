/// opencode 用量数据模型（与 console 的 getCosts / getUsageInfo 返回结构一致）。
library;

/// 计费 plan 类型。
enum OcPlan {
  regular, // 按量 / BYOK
  sub, // Black 订阅
  lite // Go 订阅
  ;

  static OcPlan fromString(Object? s) => switch (s) {
    'sub' => OcPlan.sub,
    'lite' => OcPlan.lite,
    'byok' => OcPlan.regular,
    _ => OcPlan.regular,
  };
}

/// 柱状图数据行：某天某模型的总成本（微美分）。
class OcCostRow {
  const OcCostRow({
    required this.date,
    required this.model,
    required this.totalCostMicroCents,
    required this.keyId,
    required this.plan,
  });

  /// 'YYYY-MM-DD'
  final String date;
  final String model;

  /// 成本单位：微美分（micro-cent），÷1e8 = 美元。
  final int totalCostMicroCents;
  final String? keyId;
  final OcPlan plan;

  double get costUsd => totalCostMicroCents / 100000000;

  Map<String, dynamic> toJson() => {
    'date': date,
    'model': model,
    'totalCost': totalCostMicroCents,
    'keyId': keyId,
    'plan': plan.name,
  };

  factory OcCostRow.fromJson(Map<String, dynamic> json) => OcCostRow(
    date: json['date']?.toString() ?? '',
    model: json['model']?.toString() ?? '',
    totalCostMicroCents: json['totalCost'] is num
        ? (json['totalCost'] as num).toInt()
        : 0,
    keyId: json['keyId']?.toString(),
    plan: OcPlan.fromString(json['plan']),
  );
}

/// 密钥信息（图表密钥筛选下拉）。
class OcKey {
  const OcKey({
    required this.id,
    required this.displayName,
    required this.deleted,
  });

  final String id;
  final String displayName;
  final bool deleted;

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'deleted': deleted,
  };

  factory OcKey.fromJson(Map<String, dynamic> json) => OcKey(
    id: json['id']?.toString() ?? '',
    displayName: json['displayName']?.toString() ?? '',
    deleted: json['deleted'] == true,
  );
}

/// getCosts 响应：按月聚合用量 + 密钥列表。
class OcCostData {
  const OcCostData({required this.usage, required this.keys});

  final List<OcCostRow> usage;
  final List<OcKey> keys;

  Map<String, dynamic> toJson() => {
    'usage': usage.map((e) => e.toJson()).toList(),
    'keys': keys.map((e) => e.toJson()).toList(),
  };

  factory OcCostData.fromJson(Map<String, dynamic> json) => OcCostData(
    usage: ((json['usage'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => OcCostRow.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    keys: ((json['keys'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => OcKey.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

/// Usage History 表格的一行（UsageTable 记录）。
class OcUsageRecord {
  const OcUsageRecord({
    required this.model,
    required this.provider,
    required this.inputTokens,
    required this.outputTokens,
    this.reasoningTokens,
    this.cacheReadTokens,
    this.cacheWrite5mTokens,
    this.cacheWrite1hTokens,
    required this.costMicroCents,
    this.keyId,
    this.sessionId,
    required this.plan,
    required this.timeCreated,
  });

  final String model;
  final String provider;
  final int inputTokens;
  final int outputTokens;
  final int? reasoningTokens;
  final int? cacheReadTokens;
  final int? cacheWrite5mTokens;
  final int? cacheWrite1hTokens;

  /// 微美分。
  final int costMicroCents;
  final String? keyId;
  final String? sessionId;
  final OcPlan plan;
  final DateTime timeCreated;

  double get costUsd => costMicroCents / 100000000;

  /// 网页口径：输入 = input + cacheRead + cacheWrite5m + cacheWrite1h。
  int get totalInputTokens =>
      inputTokens +
      (cacheReadTokens ?? 0) +
      (cacheWrite5mTokens ?? 0) +
      (cacheWrite1hTokens ?? 0);

  int get totalOutputTokens => outputTokens;

  bool get isClaude => model.toLowerCase().contains('claude');

  Map<String, dynamic> toJson() => {
    'model': model,
    'provider': provider,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'reasoningTokens': reasoningTokens,
    'cacheReadTokens': cacheReadTokens,
    'cacheWrite5mTokens': cacheWrite5mTokens,
    'cacheWrite1hTokens': cacheWrite1hTokens,
    'cost': costMicroCents,
    'keyId': keyId,
    'sessionID': sessionId,
    'enrichment': {'plan': plan.name},
    'timeCreated': timeCreated.toIso8601String(),
  };

  factory OcUsageRecord.fromJson(Map<String, dynamic> json) => OcUsageRecord(
    model: json['model']?.toString() ?? '',
    provider: json['provider']?.toString() ?? '',
    inputTokens: (json['inputTokens'] as num?)?.toInt() ?? 0,
    outputTokens: (json['outputTokens'] as num?)?.toInt() ?? 0,
    reasoningTokens: (json['reasoningTokens'] as num?)?.toInt(),
    cacheReadTokens: (json['cacheReadTokens'] as num?)?.toInt(),
    cacheWrite5mTokens: (json['cacheWrite5mTokens'] as num?)?.toInt(),
    cacheWrite1hTokens: (json['cacheWrite1hTokens'] as num?)?.toInt(),
    costMicroCents: (json['cost'] as num?)?.toInt() ?? 0,
    keyId: json['keyId']?.toString(),
    sessionId: json['sessionID']?.toString(),
    plan: OcPlan.fromString((json['enrichment'] as Map?)?['plan']),
    timeCreated: _parseTime(json['timeCreated']),
  );

  static DateTime _parseTime(Object? v) {
    if (v is DateTime) return v;
    if (v is String) {
      final t = DateTime.tryParse(v);
      if (t != null) return t;
    }
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

/// 计费信息（Billing.get 的部分字段，用于顶部用量状态）。
class OcBilling {
  const OcBilling({
    this.balanceMicroCents,
    this.monthlyLimit,
    this.monthlyUsage,
    this.lite,
  });

  final int? balanceMicroCents;
  final int? monthlyLimit;
  final int? monthlyUsage;
  final Map<String, dynamic>? lite;

  double? get balanceUsd =>
      balanceMicroCents == null ? null : balanceMicroCents! / 100000000;

  double? get monthlyUsageUsd =>
      monthlyUsage == null ? null : monthlyUsage! / 100000000;

  factory OcBilling.fromJson(Map<String, dynamic> json) => OcBilling(
    balanceMicroCents: (json['balance'] as num?)?.toInt(),
    monthlyLimit: (json['monthlyLimit'] as num?)?.toInt(),
    monthlyUsage: (json['monthlyUsage'] as num?)?.toInt(),
    lite: json['lite'] as Map<String, dynamic>?,
  );
}

/// 单条用量限制（服务端 analyze 后：usagePercent / resetInSec / status）。
class OcLiteUsage {
  const OcLiteUsage({
    required this.usagePercent,
    required this.resetInSec,
    required this.status,
  });

  /// 0-100（服务端已 floor + min 100）。
  final int usagePercent;

  /// 距重置的秒数。
  final int resetInSec;

  /// "ok" / "rate-limited"。
  final String status;

  bool get rateLimited => status == 'rate-limited';

  Map<String, dynamic> toJson() => {
    'usagePercent': usagePercent,
    'resetInSec': resetInSec,
    'status': status,
  };

  factory OcLiteUsage.fromJson(Map<String, dynamic> json) => OcLiteUsage(
    usagePercent: (json['usagePercent'] as num?)?.toInt() ?? 0,
    resetInSec: (json['resetInSec'] as num?)?.toInt() ?? 0,
    status: json['status']?.toString() ?? 'ok',
  );
}

/// queryLiteSubscription 响应：Go 套餐 5h/周/月 用量。
class OcLiteSubscription {
  const OcLiteSubscription({
    required this.mine,
    required this.useBalance,
    required this.rollingUsage,
    required this.weeklyUsage,
    required this.monthlyUsage,
  });

  final bool mine;
  final bool useBalance;
  final OcLiteUsage? rollingUsage;
  final OcLiteUsage? weeklyUsage;
  final OcLiteUsage? monthlyUsage;

  Map<String, dynamic> toJson() => {
    'mine': mine,
    'useBalance': useBalance,
    'rollingUsage': rollingUsage?.toJson(),
    'weeklyUsage': weeklyUsage?.toJson(),
    'monthlyUsage': monthlyUsage?.toJson(),
  };

  factory OcLiteSubscription.fromJson(Map<String, dynamic> json) =>
      OcLiteSubscription(
        mine: json['mine'] == true,
        useBalance: json['useBalance'] == true,
        rollingUsage: _parseUsage(json['rollingUsage']),
        weeklyUsage: _parseUsage(json['weeklyUsage']),
        monthlyUsage: _parseUsage(json['monthlyUsage']),
      );

  static OcLiteUsage? _parseUsage(Object? v) =>
      v is Map ? OcLiteUsage.fromJson(Map<String, dynamic>.from(v)) : null;
}
