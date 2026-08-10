import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'l10n.dart';

export 'l10n.dart';

extension L10nX on BuildContext {
  // 事件处理器（如按钮点击）里也会调用 l10n，
  // 必须 listen:false，否则 Provider 会抛异常导致“点击没反应”。
  L10n get l10n => L10n(Provider.of<AppState>(this, listen: false).locale);
}
