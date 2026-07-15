import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import '../database/database_service.dart';
import '../logger/app_logger.dart';
import '../security/security_service.dart';

import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/customers/data/repositories/customer_repository_impl.dart';
import '../../features/customers/domain/repositories/customer_repository.dart';
import '../../features/orders/data/repositories/order_repository_impl.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../services/backup_service.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';

final GetIt locator = GetIt.instance;

/// Configures dependency injection. Registers singletons for core infrastructure.
Future<void> setupLocator() async {
  // 1. Register Logger
  final appLogger = AppLogger();
  locator.registerSingleton<AppLogger>(appLogger);
  locator.registerSingleton<Logger>(appLogger.logger);

  // 2. Register Security Service
  locator.registerSingleton<SecurityService>(SecurityService());

  // 3. Register Database Service
  final dbService = DatabaseService(logger: appLogger.logger);
  locator.registerSingleton<DatabaseService>(dbService);

  // 4. Register Authentication Repository
  locator.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(locator<DatabaseService>(), locator<SecurityService>()),
  );

  // 5. Register Customer Repository
  locator.registerSingleton<CustomerRepository>(
    CustomerRepositoryImpl(locator<DatabaseService>()),
  );

  // 6. Register Order Repository
  locator.registerSingleton<OrderRepository>(
    OrderRepositoryImpl(locator<DatabaseService>()),
  );

  // 7. Register Backup Service
  locator.registerSingleton<BackupService>(
    BackupService(dbService: locator<DatabaseService>()),
  );

  // 8. Register Settings Repository
  locator.registerSingleton<SettingsRepository>(
    SettingsRepositoryImpl(locator<DatabaseService>()),
  );
}
