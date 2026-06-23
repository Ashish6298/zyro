import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'floating_videos_controller.dart';
import 'floating_video_models.dart';
import '../../../core/extension_manager.dart';

class FloatingVideosService {
  static void setupJavaScriptHandler(
    InAppWebViewController controller,
    String tabId,
    ExtensionManager extensionManager,
    FloatingVideosController floatingCtrl,
  ) {
    controller.removeJavaScriptHandler(handlerName: 'floatingVideoState');
    controller.addJavaScriptHandler(
      handlerName: 'floatingVideoState',
      callback: (args) {
        try {
          if (!extensionManager.isExtensionEnabled('floating_videos')) {
            return;
          }

          final data = Map<String, dynamic>.from(args[0]);
          final videoModel = FloatingVideoModel.fromMap(data, tabId);
          
          floatingCtrl.updateActiveVideo(videoModel, controller);
        } catch (e) {
          // Safely ignore Provider errors from deactivated widget ancestors
          // This happens when WebView callbacks fire after widget disposal
          print("[FLOATING VIDEO DEBUG] Ignoring JS handler error (widget likely disposed): $e");
        }
      },
    );
  }
}
