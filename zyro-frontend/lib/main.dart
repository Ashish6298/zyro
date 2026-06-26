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
import 'features/permissions/controllers/website_permissions_controller.dart';
import 'features/permissions/services/website_permission_manager.dart';
import 'features/screenshot_pro/controllers/screenshot_pro_controller.dart';
import 'features/web_apps/controllers/web_app_installer_controller.dart';
import 'features/web_apps/services/web_app_shortcut_channel.dart';

import 'features/extensions/background_player/background_player_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundPlayerService.initializeChannelHandler();
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
        ChangeNotifierProvider(create: (_) => ScreenshotProController()),
        ChangeNotifierProvider(create: (_) => WebAppInstallerController()),
        ChangeNotifierProvider<WebsitePermissionsController>(
          create: (_) {
            final manager = WebsitePermissionManager.instance;
            manager.initialize();
            return manager.controller;
          },
        ),
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
      builder: (context, child) =>
          WebAppShortcutLaunchBridge(child: child ?? const SizedBox.shrink()),
    );
  }
}

class WebAppShortcutLaunchBridge extends StatefulWidget {
  final Widget child;

  const WebAppShortcutLaunchBridge({super.key, required this.child});

  @override
  State<WebAppShortcutLaunchBridge> createState() =>
      _WebAppShortcutLaunchBridgeState();
}

class _WebAppShortcutLaunchBridgeState extends State<WebAppShortcutLaunchBridge>
    with WidgetsBindingObserver {
  bool _initialized = false;
  TabManager? _tabManager;
  String? _pendingShortcutUrl;
  String? _lastOpenedShortcutUrl;
  DateTime? _lastOpenedShortcutAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _tabManager = context.read<TabManager>()
      ..addListener(_flushPendingShortcutUrl);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<WebAppInstallerController>()
            .syncInstalledAppsWithPinnedShortcuts();
      }
    });

    WebAppShortcutChannel.listenForShortcutLaunches(_queueShortcutUrl);
    WebAppShortcutChannel.getInitialShortcutUrl().then((url) {
      if (url != null && url.isNotEmpty) _queueShortcutUrl(url);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabManager?.removeListener(_flushPendingShortcutUrl);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    context
        .read<WebAppInstallerController>()
        .syncInstalledAppsWithPinnedShortcuts();
  }

  void _queueShortcutUrl(String url) {
    if (!mounted) return;
    final normalizedUrl = url.trim();
    if (!_isValidShortcutUrl(normalizedUrl)) {
      debugPrint(
        '[WEB APPS] Invalid shortcut URL fallback to normal launch: $url',
      );
      return;
    }
    final lastOpenedAt = _lastOpenedShortcutAt;
    final recentlyOpenedSameUrl =
        _lastOpenedShortcutUrl == normalizedUrl &&
        lastOpenedAt != null &&
        DateTime.now().difference(lastOpenedAt) < const Duration(seconds: 2);
    if (_pendingShortcutUrl == normalizedUrl || recentlyOpenedSameUrl) {
      return;
    }

    debugPrint(
      '[WEB APPS] Flutter received web app shortcut URL: $normalizedUrl',
    );
    _pendingShortcutUrl = normalizedUrl;
    _flushPendingShortcutUrl();
  }

  void _flushPendingShortcutUrl() {
    if (!mounted) return;
    final url = _pendingShortcutUrl;
    final tabManager = _tabManager;
    if (url == null || tabManager == null) return;
    if (!tabManager.sessionReady) return;

    debugPrint('[WEB APPS] TabManager ready');
    _pendingShortcutUrl = null;
    _lastOpenedShortcutUrl = url;
    _lastOpenedShortcutAt = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugPrint('[WEB APPS] Opening web app URL in browser tab: $url');
      context.read<TabManager>().addNewTab(url: url);
      context.read<WebAppInstallerController>().markOpened(url);
      debugPrint('[WEB APPS] Web app opened from shortcut');
    });
  }

  bool _isValidShortcutUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
