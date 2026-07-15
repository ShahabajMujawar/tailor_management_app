import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_service.dart';
import '../di/injection.dart';

/// Service responsible for exporting local SQLite data into structured
/// Excel spreadsheets, and parsing/restoring from existing spreadsheets.
class BackupService {
  final DatabaseService _dbService;

  BackupService({DatabaseService? dbService})
      : _dbService = dbService ?? locator<DatabaseService>();

  /// Exports all database tables to an Excel spreadsheet file.
  Future<String> exportBackup() async {
    final db = await _dbService.database;
    final excel = Excel.createExcel();

    // Remove default sheet
    excel.rename(excel.sheets.keys.first, 'Customers');

    // 1. Export Customers
    final customers = await db.rawQuery('SELECT * FROM customers');
    final customersSheet = excel['Customers'];
    if (customers.isNotEmpty) {
      customersSheet.appendRow(customers.first.keys.map((k) => TextCellValue(k)).toList());
      for (final row in customers) {
        customersSheet.appendRow(row.values.map((v) => TextCellValue(v?.toString() ?? '')).toList());
      }
    }

    // 2. Export Orders
    final orders = await db.rawQuery('SELECT * FROM orders');
    final ordersSheet = excel['Orders'];
    if (orders.isNotEmpty) {
      ordersSheet.appendRow(orders.first.keys.map((k) => TextCellValue(k)).toList());
      for (final row in orders) {
        ordersSheet.appendRow(row.values.map((v) => TextCellValue(v?.toString() ?? '')).toList());
      }
    }

    // 3. Export Garments
    final garments = await db.rawQuery('SELECT * FROM garments');
    final garmentsSheet = excel['Garments'];
    if (garments.isNotEmpty) {
      garmentsSheet.appendRow(garments.first.keys.map((k) => TextCellValue(k)).toList());
      for (final row in garments) {
        garmentsSheet.appendRow(row.values.map((v) => TextCellValue(v?.toString() ?? '')).toList());
      }
    }

    // 4. Export Measurements
    final measurements = await db.rawQuery('SELECT * FROM measurements');
    final measurementsSheet = excel['Measurements'];
    if (measurements.isNotEmpty) {
      measurementsSheet.appendRow(measurements.first.keys.map((k) => TextCellValue(k)).toList());
      for (final row in measurements) {
        measurementsSheet.appendRow(row.values.map((v) => TextCellValue(v?.toString() ?? '')).toList());
      }
    }

    // 5. Export Preferences
    final preferences = await db.rawQuery('SELECT * FROM preferences');
    final preferencesSheet = excel['Preferences'];
    if (preferences.isNotEmpty) {
      preferencesSheet.appendRow(preferences.first.keys.map((k) => TextCellValue(k)).toList());
      for (final row in preferences) {
        preferencesSheet.appendRow(row.values.map((v) => TextCellValue(v?.toString() ?? '')).toList());
      }
    }

    // 6. Export Settings
    final settings = await db.rawQuery('SELECT * FROM settings');
    final settingsSheet = excel['Settings'];
    if (settings.isNotEmpty) {
      settingsSheet.appendRow(settings.first.keys.map((k) => TextCellValue(k)).toList());
      for (final row in settings) {
        settingsSheet.appendRow(row.values.map((v) => TextCellValue(v?.toString() ?? '')).toList());
      }
    }

    // Save to App Documents Directory
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${backupDir.path}/TailorPro_Backup_$timestamp.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    return file.path;
  }

  /// Restores the database from a backup Excel file.
  Future<void> restoreBackup(String filepath) async {
    final file = File(filepath);
    if (!await file.exists()) {
      throw Exception('Backup file not found.');
    }

    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    // Basic Validation: must contain core sheets
    if (!excel.tables.containsKey('Customers') || !excel.tables.containsKey('Orders')) {
      throw Exception('Invalid backup file. Missing core sheets.');
    }

    final db = await _dbService.database;

    await db.transaction((txn) async {
      // Clear current data securely (foreign keys are enabled, so deletions will cascade appropriately)
      await txn.rawDelete('DELETE FROM preferences');
      await txn.rawDelete('DELETE FROM measurements');
      await txn.rawDelete('DELETE FROM garments');
      await txn.rawDelete('DELETE FROM orders');
      await txn.rawDelete('DELETE FROM customers');
      await txn.rawDelete('DELETE FROM settings');

      // 1. Restore Customers
      final customersSheet = excel.tables['Customers'];
      if (customersSheet != null && customersSheet.maxRows > 1) {
        final headers = customersSheet.rows.first.map((c) => c?.value?.toString() ?? '').toList();
        for (int i = 1; i < customersSheet.maxRows; i++) {
          final rowValues = customersSheet.rows[i].map((c) => c?.value?.toString() ?? '').toList();
          final Map<String, dynamic> rowMap = {};
          for (int j = 0; j < headers.length; j++) {
            if (j < rowValues.length) {
              rowMap[headers[j]] = rowValues[j];
            }
          }
          await txn.rawInsert(
            '''
            INSERT INTO customers (customer_id, full_name, mobile_number, alternate_number, address, notes, created_at, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              int.tryParse(rowMap['customer_id'] ?? ''),
              rowMap['full_name'],
              rowMap['mobile_number'],
              rowMap['alternate_number'],
              rowMap['address'],
              rowMap['notes'],
              rowMap['created_at'],
              rowMap['updated_at'],
            ],
          );
        }
      }

      // 2. Restore Orders
      final ordersSheet = excel.tables['Orders'];
      if (ordersSheet != null && ordersSheet.maxRows > 1) {
        final headers = ordersSheet.rows.first.map((c) => c?.value?.toString() ?? '').toList();
        for (int i = 1; i < ordersSheet.maxRows; i++) {
          final rowValues = ordersSheet.rows[i].map((c) => c?.value?.toString() ?? '').toList();
          final Map<String, dynamic> rowMap = {};
          for (int j = 0; j < headers.length; j++) {
            if (j < rowValues.length) {
              rowMap[headers[j]] = rowValues[j];
            }
          }
          await txn.rawInsert(
            '''
            INSERT INTO orders (order_id, receipt_number, customer_id, order_date, delivery_date, status, remarks, created_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              int.tryParse(rowMap['order_id'] ?? ''),
              rowMap['receipt_number'],
              int.tryParse(rowMap['customer_id'] ?? ''),
              rowMap['order_date'],
              rowMap['delivery_date'],
              rowMap['status'],
              rowMap['remarks'],
              rowMap['created_at'],
            ],
          );
        }
      }

      // 3. Restore Garments
      final garmentsSheet = excel.tables['Garments'];
      if (garmentsSheet != null && garmentsSheet.maxRows > 1) {
        final headers = garmentsSheet.rows.first.map((c) => c?.value?.toString() ?? '').toList();
        for (int i = 1; i < garmentsSheet.maxRows; i++) {
          final rowValues = garmentsSheet.rows[i].map((c) => c?.value?.toString() ?? '').toList();
          final Map<String, dynamic> rowMap = {};
          for (int j = 0; j < headers.length; j++) {
            if (j < rowValues.length) {
              rowMap[headers[j]] = rowValues[j];
            }
          }
          await txn.rawInsert(
            'INSERT INTO garments (garment_id, order_id, garment_type) VALUES (?, ?, ?)',
            [
              int.tryParse(rowMap['garment_id'] ?? ''),
              int.tryParse(rowMap['order_id'] ?? ''),
              rowMap['garment_type'],
            ],
          );
        }
      }

      // 4. Restore Measurements
      final measurementsSheet = excel.tables['Measurements'];
      if (measurementsSheet != null && measurementsSheet.maxRows > 1) {
        final headers = measurementsSheet.rows.first.map((c) => c?.value?.toString() ?? '').toList();
        for (int i = 1; i < measurementsSheet.maxRows; i++) {
          final rowValues = measurementsSheet.rows[i].map((c) => c?.value?.toString() ?? '').toList();
          final Map<String, dynamic> rowMap = {};
          for (int j = 0; j < headers.length; j++) {
            if (j < rowValues.length) {
              rowMap[headers[j]] = rowValues[j];
            }
          }
          await txn.rawInsert(
            'INSERT INTO measurements (measurement_id, garment_id, measurement_json, created_at) VALUES (?, ?, ?, ?)',
            [
              int.tryParse(rowMap['measurement_id'] ?? ''),
              int.tryParse(rowMap['garment_id'] ?? ''),
              rowMap['measurement_json'],
              rowMap['created_at'],
            ],
          );
        }
      }

      // 5. Restore Preferences
      final preferencesSheet = excel.tables['Preferences'];
      if (preferencesSheet != null && preferencesSheet.maxRows > 1) {
        final headers = preferencesSheet.rows.first.map((c) => c?.value?.toString() ?? '').toList();
        for (int i = 1; i < preferencesSheet.maxRows; i++) {
          final rowValues = preferencesSheet.rows[i].map((c) => c?.value?.toString() ?? '').toList();
          final Map<String, dynamic> rowMap = {};
          for (int j = 0; j < headers.length; j++) {
            if (j < rowValues.length) {
              rowMap[headers[j]] = rowValues[j];
            }
          }
          await txn.rawInsert(
            'INSERT INTO preferences (preference_id, garment_id, preference_json) VALUES (?, ?, ?)',
            [
              int.tryParse(rowMap['preference_id'] ?? ''),
              int.tryParse(rowMap['garment_id'] ?? ''),
              rowMap['preference_json'],
            ],
          );
        }
      }

      // 6. Restore Settings
      final settingsSheet = excel.tables['Settings'];
      if (settingsSheet != null && settingsSheet.maxRows > 1) {
        final headers = settingsSheet.rows.first.map((c) => c?.value?.toString() ?? '').toList();
        for (int i = 1; i < settingsSheet.maxRows; i++) {
          final rowValues = settingsSheet.rows[i].map((c) => c?.value?.toString() ?? '').toList();
          final Map<String, dynamic> rowMap = {};
          for (int j = 0; j < headers.length; j++) {
            if (j < rowValues.length) {
              rowMap[headers[j]] = rowValues[j];
            }
          }
          await txn.rawInsert(
            'INSERT OR REPLACE INTO settings (setting_key, setting_value) VALUES (?, ?)',
            [
              rowMap['setting_key'],
              rowMap['setting_value'],
            ],
          );
        }
      }
    });
  }
}
