import 'package:flutter/material.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/theme.dart';

/// The root application widget setting up the routing structure,
/// theme configs, and styling metrics.
class TailorProApp extends StatelessWidget {
  const TailorProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TailorPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
