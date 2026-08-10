import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:token_kakeibo/services/seroval.dart';

/// 与 solid-start createChunk 一致：`;0x<8位hex长度>;JSON`。
String chunk(String json) {
  final len = utf8.encode(json).length;
  final hex = len.toRadixString(16).padLeft(8, '0');
  return ';0x$hex;$json';
}

void main() {
  group('Seroval.encodeArgs', () {
    test('字符串/数字参数 → 与浏览器端 Mo(args) 输出一致（含 l 字段）', () {
      final body = Seroval.encodeArgs([
        'wrk_01KZK4MHR3231NK6MCBBQKR47J',
        2026,
        8,
        '+08:00',
      ]);
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      expect(decoded['f'], 31);
      expect(decoded['m'], isEmpty);
      final t = decoded['t'] as Map<String, dynamic>;
      expect(t['t'], 9); // array
      expect(t['i'], 0);
      expect(t['l'], 4); // length 字段（缺失会导致服务端解析失败）
      expect(t['o'], 0);
      final a = t['a'] as List;
      expect(a, [
        {'t': 1, 's': 'wrk_01KZK4MHR3231NK6MCBBQKR47J'},
        {'t': 0, 's': 2026},
        {'t': 0, 's': 8},
        {'t': 1, 's': '+08:00'},
      ]);
    });

    test('bool/null 参数编码', () {
      final body = Seroval.encodeArgs(['x', true, null]);
      final t = (jsonDecode(body) as Map)['t'] as Map;
      final a = t['a'] as List;
      expect(a[1], {'t': 2, 's': 2}); // true
      expect(a[2], {'t': 2, 's': 0}); // null
    });
  });

  group('Seroval.decodeBody', () {
    test('解析 seroval 流（getCosts 响应，含嵌套对象/数组/引用）', () {
      // 由 seroval 1.6.0 toCrossJSONStream 实测生成的黄金数据。
      final golden = chunk(
        '{"t":10,"i":0,"p":{"k":["usage","keys"],"v":['
        '{"t":9,"i":1,"a":['
        '{"t":10,"i":2,"p":{"k":["date","model","totalCost","keyId","plan"],'
        '"v":[{"t":1,"s":"2026-08-09"},{"t":1,"s":"deepseek-v4-flash"},'
        '{"t":0,"s":123456789},{"t":1,"s":"key_1"},{"t":1,"s":"lite"}]},"o":0},'
        '{"t":10,"i":3,"p":{"k":["date","model","totalCost","keyId","plan"],'
        '"v":[{"t":1,"s":"2026-08-09"},{"t":1,"s":"glm-5.2"},'
        '{"t":0,"s":5000000},{"t":1,"s":"key_1"},{"t":1,"s":"lite"}]},"o":0}'
        '],"o":0},'
        '{"t":9,"i":4,"a":[{"t":10,"i":5,"p":{"k":["id","displayName","deleted"],'
        '"v":[{"t":1,"s":"key_1"},{"t":1,"s":"a@b.com - default"},{"t":2,"s":3}]},"o":0}],"o":0}'
        '],"o":0}}',
      );
      final result = Seroval.decodeBody(
        Uint8List.fromList(utf8.encode(golden)),
        'application/octet-stream',
      ) as Map<String, dynamic>;
      expect(result['usage'], isA<List>());
      final usage = result['usage'] as List;
      expect(usage.length, 2);
      expect(usage[0]['date'], '2026-08-09');
      expect(usage[0]['model'], 'deepseek-v4-flash');
      expect(usage[0]['totalCost'], 123456789);
      expect(usage[0]['plan'], 'lite');
      final keys = result['keys'] as List;
      expect(keys.length, 1);
      expect(keys[0]['displayName'], 'a@b.com - default');
      expect(keys[0]['deleted'], false); // t:2 s:3 → false
    });

    test('解析 application/json 响应', () {
      final result = Seroval.decodeBody(
        Uint8List.fromList(utf8.encode('{"ok":true,"n":42}')),
        'application/json',
      ) as Map<String, dynamic>;
      expect(result['ok'], true);
      expect(result['n'], 42);
    });

    test('多 chunk 流 + 跨 chunk 引用', () {
      // seroval 流式：被引用的数组 node 先发，根对象后发并通过 t:4 引用。
      final stream = chunk(
            '{"t":9,"i":1,"a":[{"t":1,"s":"a"},{"t":1,"s":"b"}],"o":0}',
          ) +
          chunk(
            '{"t":10,"i":0,"p":{"k":["list"],"v":[{"t":4,"i":1}]},"o":0}',
          );
      final result = Seroval.decodeBody(
        Uint8List.fromList(utf8.encode(stream)),
        'application/octet-stream',
      ) as Map<String, dynamic>;
      expect(result['list'], ['a', 'b']);
    });

    test('非 chunk 文本宽容返回原文', () {
      final result = Seroval.decodeBody(
        Uint8List.fromList(utf8.encode('garbage-no-chunk')),
        'application/octet-stream',
      );
      expect(result, 'garbage-no-chunk');
    });
  });
}
