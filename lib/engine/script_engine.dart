import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'hooks.dart';

class ScriptEngine implements BrowserHooks {
  // Phase 2: This will hold the list of loaded extensions
  
  @override
  Future<void> onPageStart(InAppWebViewController controller, WebUri? url) async {
    // Placeholder for Phase 2 extension triggers
    print("Hook: onPageStart - $url");
  }

  @override
  Future<void> onPageFinished(InAppWebViewController controller, WebUri? url) async {
    print("Hook: onPageFinished - $url");
    // Example of Phase 1 capability: Simple JS injection test
    // executeManualScript(controller, "document.body.style.border = '5px solid #007AFF';");
  }

  @override
  Future<void> onUrlChanged(InAppWebViewController controller, WebUri? url) async {
    print("Hook: onUrlChanged - $url");
  }

  @override
  Future<void> onProgressChanged(InAppWebViewController controller, int progress) async {
    // Progress tracking
  }

  Future<void> executeManualScript(InAppWebViewController controller, String source) async {
    await controller.evaluateJavascript(source: source);
  }
}
