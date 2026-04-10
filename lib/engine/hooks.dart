import 'package:flutter_inappwebview/flutter_inappwebview.dart';

abstract class BrowserHooks {
  Future<void> onPageStart(InAppWebViewController controller, WebUri? url);
  Future<void> onPageFinished(InAppWebViewController controller, WebUri? url);
  Future<void> onUrlChanged(InAppWebViewController controller, WebUri? url);
  Future<void> onProgressChanged(InAppWebViewController controller, int progress);
}
