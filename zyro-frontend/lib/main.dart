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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => TabManager()..addNewTab()),
        ChangeNotifierProvider(create: (_) => BrowserDataManager()),
        ChangeNotifierProvider(create: (_) => ExtensionManager()),
        ChangeNotifierProvider(create: (_) => DownloadController()),
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
      title: 'Zyro Browser',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: globalScaffoldKey,
      theme: isIncognito ? AppTheme.incognitoTheme : AppTheme.lightTheme,
      darkTheme: isIncognito ? AppTheme.incognitoTheme : AppTheme.darkTheme,
      themeMode: isIncognito ? ThemeMode.dark : themeController.themeMode,
      home: const SplashScreen(),
    );
  }
}
