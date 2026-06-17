import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/tab_manager.dart';
import 'core/browser_data_manager.dart';
import 'core/extension_manager.dart';
import 'core/globals.dart';
import 'app/screens/splash_screen.dart';
import 'app/theme/app_theme.dart';
import 'features/video_downloader/controllers/download_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
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
    return MaterialApp(
      title: 'Zyro Browser',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: globalScaffoldKey,
      theme: AppTheme.darkTheme(),
      home: const SplashScreen(),
    );
  }
}

