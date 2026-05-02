import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/tab_manager.dart';
import 'core/browser_data_manager.dart';
import 'core/extension_manager.dart';
import 'app/screens/splash_screen.dart';
import 'app/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabManager()..addNewTab()),
        ChangeNotifierProvider(create: (_) => BrowserDataManager()),
        ChangeNotifierProvider(create: (_) => ExtensionManager()),
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
      theme: AppTheme.darkTheme(),
      home: const SplashScreen(),
    );
  }
}
