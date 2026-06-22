import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/tab_manager.dart';
import 'core/browser_data_manager.dart';
import 'core/extension_manager.dart';
import 'core/globals.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/video_downloader/controllers/download_controller.dart';
import 'features/extensions/dev_tools/dev_tools_controller.dart';
import 'features/extensions/ad_blocker/services/ad_block_stats_service.dart';
import 'features/extensions/floating_videos/floating_videos_controller.dart';
import 'features/extensions/floating_videos/widgets/floating_video_overlay.dart';
import 'features/extensions/floating_videos/platform/floating_video_channel.dart';

import 'features/extensions/background_player/background_player_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundPlayerService.initializeChannelHandler();
  FloatingVideoChannel.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => TabManager()),
        ChangeNotifierProvider(create: (_) => BrowserDataManager()),
        ChangeNotifierProvider(create: (_) => ExtensionManager()),
        ChangeNotifierProvider(create: (_) => DownloadController()),
        ChangeNotifierProvider(create: (_) => DevToolsController()),
        ChangeNotifierProvider(create: (_) => AdBlockStatsService()),
        ChangeNotifierProvider(create: (_) => FloatingVideosController()),
      ],
      child: const ZyroApp(),
    ),
  );
}

class ZyroApp extends StatelessWidget {
  const ZyroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final tabManager = Provider.of<TabManager>(context);
    final isIncognito = tabManager.isGlobalIncognito;
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Zyro Browser',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: globalScaffoldKey,
      theme: isIncognito ? AppTheme.incognitoTheme : AppTheme.lightTheme,
      darkTheme: isIncognito ? AppTheme.incognitoTheme : AppTheme.darkTheme,
      themeMode: isIncognito ? ThemeMode.dark : themeController.themeMode,
      home: const SplashScreen(),
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const FloatingVideoOverlay(),
          ],
        );
      },
    );
  }
}
