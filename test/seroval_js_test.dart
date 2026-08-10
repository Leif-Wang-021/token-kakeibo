import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:token_kakeibo/services/seroval.dart';

/// 与 solid-start createChunk 一致：`;0x<8位hex长度>;JSON`。
String chunk(String payload) {
  final len = utf8.encode(payload).length;
  final hex = len.toRadixString(16).padLeft(8, '0');
  return ';0x$hex;$payload';
}

void main() {
  group('Seroval.decodeBody - JS 模式（opencode 部署）', () {
    test('错误响应：提取 new Error 消息', () {
      // 真实响应（curl 抓取）：服务端 SEROVAL_MODE=js 的错误序列化。
      final stream = chunk(
        r'((self.$R=self.$R||{})["server-fn:0"]=[],'
        r'($R=>$R[0]=Object.assign(new Error("Expected actor type user, got public"),'
        r'{stack:"Error: Expected actor type user, got public"}))'
        r'($R["server-fn:0"]))',
      );
      expect(
        () => Seroval.decodeBody(
          Uint8List.fromList(utf8.encode(stream)),
          'text/javascript',
        ),
        throwsA(
          isA<SerovalError>().having(
            (e) => e.message,
            'message',
            contains('Expected actor type user'),
          ),
        ),
      );
    });

    test('成功响应：crossSerialize 对象（引用内联）', () {
      // seroval 1.6.0 crossSerialize 输出（js 模式）+ chunk 包装
      final stream = chunk(
        r'((self.$R=self.$R||{})["server-fn:0"]=[],'
        r'($R=>$R[0]={usage:$R[1]=[$R[2]={date:"2026-08-09",'
        r'model:"deepseek-v4-flash",totalCost:123456789,keyId:"key_1",plan:"lite"}],'
        r'keys:$R[3]=[$R[4]={id:"key_1",displayName:"a@b.com - default",deleted:!1}]}))'
        r'($R["server-fn:0"]))',
      );
      final result = Seroval.decodeBody(
        Uint8List.fromList(utf8.encode(stream)),
        'text/javascript',
      ) as Map<String, dynamic>;
      final usage = result['usage'] as List;
      expect(usage.length, 1);
      expect(usage[0]['model'], 'deepseek-v4-flash');
      expect(usage[0]['totalCost'], 123456789);
      final keys = result['keys'] as List;
      expect(keys[0]['deleted'], false); // !1
      expect(keys[0]['displayName'], 'a@b.com - default');
    });

    test('成功响应：数组根（getUsageInfo）', () {
      final stream = chunk(
        r'((self.$R=self.$R||{})["server-fn:0"]=[],'
        r'($R=>$R[0]=[$R[1]={model:"deepseek-v4-flash",provider:"opencode",'
        r'inputTokens:100,outputTokens:50,cost:200000,'
        r'enrichment:{plan:"lite"},timeCreated:"2026-08-09T06:00:00.000Z"}]))'
        r'($R["server-fn:0"]))',
      );
      final result = Seroval.decodeBody(
        Uint8List.fromList(utf8.encode(stream)),
        'text/javascript',
      ) as List;
      expect(result.length, 1);
      expect(result[0]['model'], 'deepseek-v4-flash');
      expect(result[0]['enrichment']['plan'], 'lite');
    });

    test('多 chunk：引用跨 chunk 定义', () {
      // chunk1 定义 $R[1]（数组），chunk2 根对象引用它
      final stream = chunk(
            r'($R[1]=[{date:"2026-08-09",model:"glm-5.2",totalCost:5000000}])',
          ) +
          chunk(
            r'((self.$R=self.$R||{})["server-fn:0"]=[],'
            r'($R=>$R[0]={usage:$R[1]}))($R["server-fn:0"]))',
          );
      final result = Seroval.decodeBody(
        Uint8List.fromList(utf8.encode(stream)),
        'text/javascript',
      ) as Map<String, dynamic>;
      expect((result['usage'] as List)[0]['model'], 'glm-5.2');
    });

    test('new Date("...") 表达式（getUsageInfo 的 timeCreated）', () {
      // 真实响应（2026-08-10 curl 抓取）：timeCreated 序列化为 new Date(...)
      final stream = chunk(
        r'((self.$R=self.$R||{})["server-fn:0"]=[],'
        r'($R=>$R[0]=[$R[1]={id:"usg_01",model:"deepseek-v4-flash",'
        r'timeCreated:$R[2]=new Date("2026-08-10T02:16:20.000Z"),'
        r'cacheWrite5mTokens:null,sessionID:"",enrichment:$R[3]={plan:"lite"}}]))'
        r'($R["server-fn:0"]))',
      );
      final result = Seroval.decodeBody(
        Uint8List.fromList(utf8.encode(stream)),
        'text/javascript',
      ) as List;
      final rec = result[0] as Map<String, dynamic>;
      expect(rec['model'], 'deepseek-v4-flash');
      expect(rec['cacheWrite5mTokens'], isNull);
      expect(rec['sessionID'], '');
      expect(rec['timeCreated'], isA<DateTime>());
      expect((rec['timeCreated'] as DateTime).toUtc().year, 2026);
      expect((rec['enrichment'] as Map)['plan'], 'lite');
    });
  });
}
