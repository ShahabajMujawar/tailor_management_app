import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/injection.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter engine bindings are fully initialized before DI setup
  WidgetsFlutterBinding.ensureInitialized();

  // Run Service Locator dependency registrations
  await setupLocator();

  // Launch application within the Riverpod scope
  runApp(
    const ProviderScope(
      child: TailorProApp(),
    ),
  );
}
