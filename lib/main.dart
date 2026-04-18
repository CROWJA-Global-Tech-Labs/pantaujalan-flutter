/// PantauJalan Flutter entry point. Mirrors PantauApp.onCreate + MainActivity
/// launch on the Android side.
library;

import 'package:flutter/material.dart';

import 'data/remote_feeds_loader.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Fire-and-forget background refresh of the encrypted remote config.
  // The UI shows bundled/cached feeds immediately; updates become visible
  // on next app launch (or pull-to-refresh).
  RemoteFeedsLoader.refreshAsync();

  runApp(const PantauJalanApp());
}

class PantauJalanApp extends StatelessWidget {
  const PantauJalanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PantauJalan',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainScreen(),
    );
  }
}
