/// WebDAV 同步配置（设置/登录态跨设备同步）。
library;

class WebDavConfig {
  const WebDavConfig({
    this.enabled = false,
    this.url = '',
    this.username = '',
    this.password = '',
    this.lastSyncAt,
  });

  final bool enabled;
  final String url;
  final String username;
  final String password;
  final DateTime? lastSyncAt;

  bool get configured => url.isNotEmpty && username.isNotEmpty;

  WebDavConfig copyWith({
    bool? enabled,
    String? url,
    String? username,
    String? password,
    DateTime? lastSyncAt,
    bool clearLastSync = false,
  }) => WebDavConfig(
        enabled: enabled ?? this.enabled,
        url: url ?? this.url,
        username: username ?? this.username,
        password: password ?? this.password,
        lastSyncAt: clearLastSync ? null : (lastSyncAt ?? this.lastSyncAt),
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'url': url,
        'username': username,
        'password': password,
        'lastSyncAt': lastSyncAt?.toIso8601String(),
      };

  factory WebDavConfig.fromJson(Map<String, dynamic> json) => WebDavConfig(
        enabled: json['enabled'] == true,
        url: json['url']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        password: json['password']?.toString() ?? '',
        lastSyncAt: json['lastSyncAt'] == null
            ? null
            : DateTime.tryParse(json['lastSyncAt'].toString()),
      );
}
