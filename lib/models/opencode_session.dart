/// opencode 登录态：WebView2 登录后提取的 cookie 会话 + workspace ID。
library;

class OpenCodeSession {
  const OpenCodeSession({
    required this.cookie,
    required this.workspaceId,
    this.email,
    this.savedAt,
  });

  /// Cookie header 字符串（分号分隔的 name=value）。
  final String cookie;

  /// workspace ID（wrk_...）。
  final String workspaceId;

  /// 登录账号邮箱（可选，用于展示）。
  final String? email;

  final DateTime? savedAt;

  bool get isValid =>
      cookie.isNotEmpty && workspaceId.isNotEmpty && cookie.length > 20;

  OpenCodeSession copyWith({String? cookie, String? workspaceId, String? email}) =>
      OpenCodeSession(
        cookie: cookie ?? this.cookie,
        workspaceId: workspaceId ?? this.workspaceId,
        email: email ?? this.email,
        savedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'cookie': cookie,
        'workspaceId': workspaceId,
        'email': email,
        'savedAt': savedAt?.toIso8601String(),
      };

  factory OpenCodeSession.fromJson(Map<String, dynamic> json) {
    final savedAtRaw = json['savedAt']?.toString();
    return OpenCodeSession(
      cookie: json['cookie']?.toString() ?? '',
      workspaceId: json['workspaceId']?.toString() ?? '',
      email: json['email']?.toString(),
      savedAt: savedAtRaw == null ? null : DateTime.tryParse(savedAtRaw),
    );
  }
}
