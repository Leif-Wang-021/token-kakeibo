import 'package:flutter_test/flutter_test.dart';
import 'package:token_kakeibo/models/opencode_data.dart';

void main() {
  group('OcCostData', () {
    test('解析 getCosts 响应', () {
      final data = OcCostData.fromJson({
        'usage': [
          {
            'date': '2026-08-09',
            'model': 'deepseek-v4-flash',
            'totalCost': 123456789,
            'keyId': 'key_1',
            'plan': 'lite',
          },
          {
            'date': '2026-08-09',
            'model': 'glm-5.2',
            'totalCost': 5000000,
            'keyId': 'key_1',
            'plan': 'sub',
          },
          {
            'date': '2026-08-10',
            'model': 'kimi-k2.7-code',
            'totalCost': 100000000,
            'keyId': null,
            'plan': null,
          },
        ],
        'keys': [
          {'id': 'key_1', 'displayName': 'a@b.com - default', 'deleted': false},
          {'id': 'key_2', 'displayName': 'a@b.com - old', 'deleted': true},
        ],
      });

      expect(data.usage.length, 3);
      // 微美分 → 美元换算
      expect(data.usage[0].costUsd, closeTo(1.23456789, 1e-9));
      expect(data.usage[0].plan, OcPlan.lite);
      expect(data.usage[1].plan, OcPlan.sub);
      expect(data.usage[2].plan, OcPlan.regular);
      expect(data.usage[2].keyId, isNull);
      expect(data.keys.length, 2);
      expect(data.keys[1].deleted, true);
    });

    test('空数据', () {
      final data = OcCostData.fromJson({'usage': [], 'keys': []});
      expect(data.usage, isEmpty);
      expect(data.keys, isEmpty);
    });
  });

  group('OcUsageRecord', () {
    test('解析 UsageTable 记录 + 网页口径 token 合计', () {
      final rec = OcUsageRecord.fromJson({
        'model': 'deepseek-v4-flash',
        'provider': 'opencode',
        'inputTokens': 100,
        'outputTokens': 50,
        'reasoningTokens': 20,
        'cacheReadTokens': 30,
        'cacheWrite5mTokens': 10,
        'cacheWrite1hTokens': 5,
        'cost': 200000,
        'keyID': 'key_1',
        'sessionID': 'sess_abc12345',
        'enrichment': {'plan': 'lite'},
        'timeCreated': '2026-08-09T06:00:00.000Z',
      });

      // 输入 = input + cacheRead + cacheWrite5m + cacheWrite1h
      expect(rec.totalInputTokens, 100 + 30 + 10 + 5);
      expect(rec.totalOutputTokens, 50);
      expect(rec.reasoningTokens, 20);
      expect(rec.costUsd, closeTo(0.002, 1e-9));
      expect(rec.plan, OcPlan.lite);
      expect(rec.sessionId, 'sess_abc12345');
      expect(rec.timeCreated.toUtc().year, 2026);
      expect(rec.isClaude, false);
    });

    test('enrichment 缺失 → regular；cache 字段缺失 → 0', () {
      final rec = OcUsageRecord.fromJson({
        'model': 'claude-sonnet-4-5',
        'provider': 'opencode',
        'inputTokens': 10,
        'outputTokens': 5,
        'cost': 100,
      });
      expect(rec.plan, OcPlan.regular);
      expect(rec.cacheReadTokens, isNull);
      expect(rec.totalInputTokens, 10); // null 按 0 计
      expect(rec.isClaude, true);
    });
  });

  group('OcPlan', () {
    test('fromString 映射', () {
      expect(OcPlan.fromString('sub'), OcPlan.sub);
      expect(OcPlan.fromString('lite'), OcPlan.lite);
      expect(OcPlan.fromString('byok'), OcPlan.regular);
      expect(OcPlan.fromString(null), OcPlan.regular);
      expect(OcPlan.fromString('unknown'), OcPlan.regular);
    });
  });
}
