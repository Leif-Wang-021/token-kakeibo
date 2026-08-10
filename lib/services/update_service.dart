import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_info.dart';

/// GitHub Release 信息。
class ReleaseInfo {
  const ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.htmlUrl,
    required this.publishedAt,
    required this.body,
  });

  final String tagName;
  final String name;
  final String htmlUrl;
  final DateTime? publishedAt;
  final String? body;
}

/// 从 GitHub Releases API 检查最新版本。
class UpdateService {
  Future<ReleaseInfo> fetchLatest() async {
    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse(kReleasesApi),
            headers: const {
              'User-Agent': 'TokenKakeibo/$kAppVersion',
              'Accept': 'application/vnd.github+json',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw UpdateException('GitHub API ${response.statusCode}');
      }
      final json = jsonDecode(response.body);
      if (json is! Map) {
        throw const UpdateException('Invalid release payload');
      }
      return ReleaseInfo(
        tagName: json['tag_name']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        htmlUrl: json['html_url']?.toString() ?? kProjectHomeUrl,
        publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? ''),
        body: json['body']?.toString(),
      );
    } finally {
      client.close();
    }
  }

  /// 将 Release tag（`v1.2.0` / `1.2.0`）与当前版本比较。
  static bool isNewer(String releaseTag, String currentVersion) {
    final a = _parse(releaseTag);
    final b = _parse(currentVersion);
    if (a.isEmpty || b.isEmpty) return false;
    for (var i = 0; i < 3; i++) {
      final x = a.length > i ? a[i] : 0;
      final y = b.length > i ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  static List<int> _parse(String raw) {
    final cleaned = raw
        .trim()
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split('.')
        .take(3)
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'\D'), '')) ?? 0)
        .toList();
    return cleaned;
  }
}

class UpdateException implements Exception {
  const UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
