import 'dart:convert';
import 'dart:typed_data';

/// seroval 编解码（与 opencode.ai SolidStart 部署的 1.6.x 格式一致）。
///
/// 请求体包装：`{"t": <crossJSON>, "f": <features>, "m": []}`
/// 响应流：多个 `;0x<8位hex长度>;` + 内容 拼接。
///   - JSON 模式（SEROVAL_MODE!=js）：内容是 JSON node，引用通过 `i` 字段共享
///   - JS 模式（opencode 部署，Content-Type: text/javascript）：
///     内容是 crossSerialize 的 JS 表达式（对象/数组/字符串字面量 + `$R[N]` 引用）
class Seroval {
  Seroval._();

  /// seroval features：Map|Set|Promise|Error|AggregateError（实测浏览器值）。
  static const int _features = 31;

  /// 把参数列表序列化为请求体（与浏览器端 `JSON.stringify(Mo(args))` 一致）。
  ///
  /// 实测（2026-08-10，从浏览器 Copy as cURL 逆向）：
  /// - 数组 node 必须含 `l`（length）字段，否则服务端解析出 undefined 参数
  /// - features 为 31（非 127）
  static String encodeArgs(List<Object?> args) {
    return jsonEncode({
      't': _wrapArray(args),
      'f': _features,
      'm': <Object?>[],
    });
  }

  static Map<String, dynamic> _wrapArray(List<Object?> items) => {
        't': 9,
        'i': 0,
        'l': items.length,
        'a': [for (final it in items) _encodeValue(it)],
        'o': 0,
      };

  static Map<String, dynamic> _encodeValue(Object? v) {
    if (v is String) return {'t': 1, 's': v};
    if (v is num) return {'t': 0, 's': v};
    if (v == null) return {'t': 2, 's': 0};
    if (v is bool) return {'t': 2, 's': v ? 2 : 3};
    throw ArgumentError('seroval: unsupported argument type ${v.runtimeType}');
  }

  /// 解析响应体（兼容三种形态：JS 流、seroval JSON 流、application/json）。
  static dynamic decodeBody(Uint8List body, String contentType) {
    if (contentType.contains('application/json')) {
      return jsonDecode(utf8.decode(body));
    }
    if (contentType.contains('text/javascript') ||
        contentType.contains('application/javascript') ||
        contentType.contains('text/plain')) {
      final text = utf8.decode(body, allowMalformed: true);
      if (text.trimLeft().startsWith(';0x')) {
        // seroval 流（JS 模式或 JSON 模式）
        return _decodeChunks(text);
      }
      // 非流：尝试 JSON，失败返回原文
      try {
        return jsonDecode(text);
      } catch (_) {
        return text;
      }
    }
    final text = utf8.decode(body, allowMalformed: true);
    if (!text.contains(';0x')) {
      try {
        return jsonDecode(text);
      } catch (_) {
        return text;
      }
    }
    return _decodeChunks(text);
  }

  /// 解析 seroval 流：先尝试 JSON node，失败则按 JS 表达式流解析。
  static dynamic _decodeChunks(String text) {
    final chunks = _splitChunks(text);
    // 尝试全部按 JSON node 解析（JSON 模式）
    try {
      final refs = <int, dynamic>{};
      dynamic result;
      for (final chunk in chunks) {
        final node = jsonDecode(chunk) as Map<String, dynamic>;
        result = _parseNode(node, refs);
      }
      return result;
    } catch (_) {
      // 落入 JS 模式
    }
    try {
      return _JsStreamDecoder().decode(chunks);
    } catch (e) {
      if (e is SerovalError) rethrow;
      throw SerovalError('响应解析失败: $e');
    }
  }

  /// 把 `;0x<8hex>;` 流切分为内容块。
  static List<String> _splitChunks(String text) {
    final parts = <String>[];
    var pos = 0;
    while (pos < text.length) {
      if (!text.startsWith(';0x', pos)) {
        throw FormatException('seroval chunk header missing at $pos');
      }
      final lenHex = text.substring(pos + 3, pos + 11);
      final len = int.tryParse(lenHex, radix: 16);
      if (len == null || len <= 0 || pos + 12 + len > text.length) {
        throw FormatException('seroval chunk length invalid: "$lenHex"');
      }
      parts.add(text.substring(pos + 12, pos + 12 + len));
      pos += 12 + len;
    }
    return parts;
  }

  static dynamic _parseNode(Map<String, dynamic> node, Map<int, dynamic> refs) {
    final t = node['t'];
    switch (t) {
      case 0: // number
        return (node['s'] as num).toDouble();
      case 1: // string
        return node['s'] as String;
      case 2: // null / undefined / true / false
        return switch (node['s']) {
          0 => null,
          1 => null, // undefined
          2 => true,
          3 => false,
          _ => null,
        };
      case 3: // bigint（本应用不需要，转字符串兜底）
        return node['s'];
      case 4: // 引用已解析的 node
        return refs[node['i']];
      case 9: // array
        final items = node['a'] as List? ?? const [];
        final arr = <dynamic>[];
        if (node['i'] is int) refs[node['i']] = arr;
        for (final item in items) {
          arr.add(item == null
              ? null
              : _parseNode(item as Map<String, dynamic>, refs));
        }
        return arr;
      case 10: // plain object
      case 11: // null-prototype object
        final obj = <String, dynamic>{};
        if (node['i'] is int) refs[node['i']] = obj;
        final p = node['p'] as Map? ?? const {};
        final keys = p['k'] as List? ?? const [];
        final values = p['v'] as List? ?? const [];
        // seroval cross-JSON：p.k 是原始字符串数组，p.v 才是 node 数组。
        for (var i = 0; i < keys.length && i < values.length; i++) {
          final k = keys[i].toString();
          final v = values[i] == null
              ? null
              : _parseNode(values[i] as Map<String, dynamic>, refs);
          obj[k] = v;
        }
        return obj;
      case 5: // date
        final s = node['s'] as String;
        return DateTime.tryParse(s) ?? s;
      case 18: // special reference
        return null;
      default:
        throw UnsupportedError('seroval node type $t unsupported');
    }
  }
}

/// JS 模式（crossSerialize）响应解码器。
///
/// 输入：`((self.$R=self.$R||{})["server-fn:0"]=[],($R=>$R[0]=<expr>))($R["server-fn:0"]))`
/// 或后续 chunk（`<expr>` 直接续接引用定义）。
/// 输出：<expr> 解析后的值（对象/数组/字符串/数字/布尔/null）。
class _JsStreamDecoder {
  final Map<int, dynamic> _refs = {};

  /// crossSerialize 流按拓扑序输出：引用定义在前，根表达式在后，
  /// 因此最后一个 chunk 的值即根值。
  dynamic decode(List<String> chunks) {
    dynamic last;
    for (final chunkJs in chunks) {
      last = _parseChunk(chunkJs);
    }
    return last;
  }

  dynamic _parseChunk(String js) {
    final core = _extractCore(js);
    if (core.isEmpty) return null;
    // 错误表达式：Object.assign(new Error("msg"), {...}) / new Error("msg")
    final errM = RegExp(r'new Error\("((?:[^"\\]|\\.)*)"').firstMatch(core);
    if (errM != null) {
      throw SerovalError(_unescapeJs(errM.group(1)!));
    }
    final parser = _JsParser(core, _refs);
    return parser.parseAssignment();
  }

  static String _unescapeJs(String s) =>
      s.replaceAll(r'\"', '"').replaceAll(r'\\', r'\');

  /// 提取核心表达式：去掉 `((self.$R=...)["id"]=[],` 前缀和 `)($R["id"]))` 后缀。
  String _extractCore(String js) {
    var s = js.trim();
    // 前缀：((self.$R=self.$R||{})["server-fn:0"]=[],
    final pre = RegExp(
      r'^\(\(self\.\$R=self\.\$R\|\|\{\}\)\["[^"]*"\]=\[\]\,',
    );
    s = s.replaceFirst(pre, '');
    // 核心可能包在 ($R=>$R[0]=<core>)($R["id"]) 里
    final m = RegExp(
      r'^\(\$R=>\$R\[0\]=(.+)\)\(\$R\["[^"]*"\]\)\)?$',
      dotAll: true,
    ).firstMatch(s);
    if (m != null) return m.group(1)!;
    // 后续 chunk：可能是裸表达式（续接引用）或完整赋值
    // 去掉尾部 )($R["id"])) 类后缀
    s = s.replaceFirst(RegExp(r'\)\(\$R\["[^"]*"\]\)\)?$'), '');
    // 去掉多余的整体括号包裹：(expr) → expr
    if (s.startsWith('(') && s.endsWith(')')) {
      s = s.substring(1, s.length - 1);
    }
    return s;
  }
}

/// seroval 解析错误（含服务端返回的业务错误消息）。
class SerovalError implements Exception {
  SerovalError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 最小 JS 表达式解析器（seroval crossSerialize 纯数据子集）。
class _JsParser {
  _JsParser(this.src, this._refs);

  final String src;
  final Map<int, dynamic> _refs;
  int _pos = 0;

  Object? parseAssignment() {
    skipWs();
    if (peek(r'$')) {
      // $R[N]=value 或 $R[N]
      final id = _parseRefId();
      skipWs();
      if (peek('=')) {
        _pos++;
        final v = parseValue();
        _refs[id] = v;
        return v;
      }
      return _refs[id];
    }
    return parseValue();
  }

  Object? parseValue() {
    skipWs();
    if (eof) return null;
    final c = src[_pos];
    switch (c) {
      case '{':
        return _parseObject();
      case '[':
        return _parseArray();
      case '"':
        return _parseString();
      case r'$':
        {
          final id = _parseRefId();
          skipWs();
          if (peek('=')) {
            _pos++;
            final v = parseValue();
            _refs[id] = v;
            return v;
          }
          return _refs[id];
        }
      case '!':
        // !0 = true, !1 = false
        _pos++;
        final n = _parseNumber();
        return n == 0;
      default:
        // number / null / true / false / undefined / NaN / Infinity / new Date()
        final code = c.codeUnitAt(0);
        if (c == '-' || (code >= 0x30 && code <= 0x39)) {
          return _parseNumber();
        }
        if (src.startsWith('new ', _pos)) {
          return _parseNewExpr();
        }
        if (src.startsWith('null', _pos)) {
          _pos += 4;
          return null;
        }
        if (src.startsWith('true', _pos)) {
          _pos += 4;
          return true;
        }
        if (src.startsWith('false', _pos)) {
          _pos += 5;
          return false;
        }
        if (src.startsWith('undefined', _pos)) {
          _pos += 9;
          return null;
        }
        throw FormatException('js parse: unexpected char "$c" at $_pos in "$src"');
    }
  }

  Map<String, dynamic> _parseObject() {
    _pos++; // {
    final obj = <String, dynamic>{};
    skipWs();
    if (peek('}')) {
      _pos++;
      return obj;
    }
    while (true) {
      skipWs();
      // key：裸标识符或字符串
      String key;
      if (peek('"')) {
        key = _parseString();
      } else {
        final start = _pos;
        while (!eof && !' ,:}'.contains(src[_pos])) {
          _pos++;
        }
        key = src.substring(start, _pos);
      }
      skipWs();
      if (peek(':')) _pos++;
      final v = parseValue();
      obj[key] = v;
      skipWs();
      if (peek(',')) {
        _pos++;
        continue;
      }
      if (peek('}')) {
        _pos++;
        break;
      }
      throw FormatException('js object: expected , or } at $_pos');
    }
    return obj;
  }

  List<dynamic> _parseArray() {
    _pos++; // [
    final arr = <dynamic>[];
    skipWs();
    if (peek(']')) {
      _pos++;
      return arr;
    }
    while (true) {
      arr.add(parseValue());
      skipWs();
      if (peek(',')) {
        _pos++;
        continue;
      }
      if (peek(']')) {
        _pos++;
        break;
      }
      throw FormatException('js array: expected , or ] at $_pos');
    }
    return arr;
  }

  String _parseString() {
    _pos++; // "
    final buf = StringBuffer();
    while (!eof) {
      final c = src[_pos++];
      if (c == '"') break;
      if (c == r'\') {
        if (eof) break;
        final esc = src[_pos++];
        switch (esc) {
          case 'n':
            buf.write('\n');
          case 't':
            buf.write('\t');
          case 'r':
            buf.write('\r');
          case 'b':
            buf.write('\b');
          case 'f':
            buf.write('\f');
          case '"':
            buf.write('"');
          case r'\':
            buf.write(r'\');
          case '/':
            buf.write('/');
          case 'u':
            final hex = src.substring(_pos, _pos + 4);
            _pos += 4;
            buf.writeCharCode(int.parse(hex, radix: 16));
          default:
            buf.write(esc);
        }
      } else {
        buf.write(c);
      }
    }
    return buf.toString();
  }

  num _parseNumber() {
    final start = _pos;
    while (!eof && '0123456789.eE+-'.contains(src[_pos])) {
      _pos++;
    }
    final s = src.substring(start, _pos);
    return double.parse(s);
  }

  /// `new Date("...")` 表达式（seroval 对 Date 的 JS 模式序列化）。
  Object? _parseNewExpr() {
    _pos += 4; // "new "
    skipWs();
    if (src.startsWith('Date', _pos)) {
      _pos += 4;
      skipWs();
      if (peek('(')) {
        _pos++;
        skipWs();
        final s = _parseString();
        skipWs();
        if (peek(')')) _pos++;
        return DateTime.tryParse(s) ?? s;
      }
    }
    throw FormatException('js parse: unsupported new expression at $_pos');
  }

  int _parseRefId() {
    // $R[N]
    _pos += 2; // $R
    if (eof || src[_pos] != '[') {
      throw FormatException('js ref: expected [ at $_pos');
    }
    _pos++;
    final start = _pos;
    while (!eof && src[_pos] != ']') {
      _pos++;
    }
    final id = int.parse(src.substring(start, _pos));
    _pos++; // ]
    return id;
  }

  void skipWs() {
    while (!eof && ' \t\r\n'.contains(src[_pos])) {
      _pos++;
    }
  }

  bool peek(String s) => src.startsWith(s, _pos);

  bool get eof => _pos >= src.length;
}
