import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_service.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

/// SQLite implementation of the [OrderRepository] interface.
class OrderRepositoryImpl implements OrderRepository {
  final DatabaseService _dbService;

  OrderRepositoryImpl(this._dbService);

  @override
  Future<Order> createOrder(Order order) async {
    final db = await _dbService.database;

    // Use transaction to ensure complete database integrity across multi-table inserts
    final savedOrder = await db.transaction<Order>((txn) async {
      // 1. Insert Order Metadata
      final orderId = await txn.rawInsert(
        '''
        INSERT INTO orders 
        (receipt_number, customer_id, order_date, delivery_date, status, remarks, created_at) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          order.receiptNumber,
          order.customerId,
          order.orderDate.toIso8601String(),
          order.deliveryDate.toIso8601String(),
          order.status,
          order.remarks?.trim(),
          order.createdAt.toIso8601String(),
        ],
      );

      final List<Garment> savedGarments = [];

      // 2. Insert Garments, Measurements, and Preferences
      for (final garment in order.garments) {
        final garmentId = await txn.rawInsert(
          'INSERT INTO garments (order_id, garment_type) VALUES (?, ?)',
          [orderId, garment.garmentType],
        );

        // Save measurements JSON
        await txn.rawInsert(
          'INSERT INTO measurements (garment_id, measurement_json, created_at) VALUES (?, ?, ?)',
          [garmentId, jsonEncode(garment.measurements), DateTime.now().toIso8601String()],
        );

        // Save preferences JSON
        await txn.rawInsert(
          'INSERT INTO preferences (garment_id, preference_json) VALUES (?, ?)',
          [garmentId, jsonEncode(garment.preferences)],
        );

        savedGarments.add(garment.copyWith(
          garmentId: garmentId,
          orderId: orderId,
        ));
      }

      return order.copyWith(
        orderId: orderId,
        garments: savedGarments,
      );
    });

    return savedOrder;
  }

  @override
  Future<void> updateOrder(Order order) async {
    if (order.orderId == null) throw Exception('Order ID is required for update.');
    final db = await _dbService.database;

    await db.transaction((txn) async {
      // 1. Update Order Metadata
      await txn.rawUpdate(
        '''
        UPDATE orders 
        SET delivery_date = ?, status = ?, remarks = ? 
        WHERE order_id = ?
        ''',
        [
          order.deliveryDate.toIso8601String(),
          order.status,
          order.remarks?.trim(),
          order.orderId,
        ],
      );

      // 2. Remove old garments, measurements, and preferences for simplicity in updates
      // The ON DELETE CASCADE constraint automatically cleans up measurements/preferences
      await txn.rawDelete('DELETE FROM garments WHERE order_id = ?', [order.orderId]);

      // 3. Re-insert new garments specs
      for (final garment in order.garments) {
        final garmentId = await txn.rawInsert(
          'INSERT INTO garments (order_id, garment_type) VALUES (?, ?)',
          [order.orderId, garment.garmentType],
        );

        await txn.rawInsert(
          'INSERT INTO measurements (garment_id, measurement_json, created_at) VALUES (?, ?, ?)',
          [garmentId, jsonEncode(garment.measurements), DateTime.now().toIso8601String()],
        );

        await txn.rawInsert(
          'INSERT INTO preferences (garment_id, preference_json) VALUES (?, ?)',
          [garmentId, jsonEncode(garment.preferences)],
        );
      }
    });
  }

  @override
  Future<void> updateOrderStatus(int orderId, String status) async {
    final db = await _dbService.database;
    await db.rawUpdate('UPDATE orders SET status = ? WHERE order_id = ?', [status, orderId]);
  }

  @override
  Future<void> deleteOrder(int orderId) async {
    final db = await _dbService.database;
    await db.rawDelete('DELETE FROM orders WHERE order_id = ?', [orderId]);
  }

  @override
  Future<Order?> getOrderById(int orderId) async {
    final db = await _dbService.database;

    final orderResult = await db.rawQuery(
      '''
      SELECT o.*, c.full_name as customer_name 
      FROM orders o 
      JOIN customers c ON o.customer_id = c.customer_id 
      WHERE o.order_id = ? LIMIT 1
      ''',
      [orderId],
    );

    if (orderResult.isEmpty) return null;

    final orderRow = orderResult.first;

    // Fetch associated garments
    final garmentsResult = await db.rawQuery(
      '''
      SELECT g.garment_id, g.garment_type, m.measurement_json, p.preference_json 
      FROM garments g 
      LEFT JOIN measurements m ON g.garment_id = m.garment_id 
      LEFT JOIN preferences p ON g.garment_id = p.garment_id 
      WHERE g.order_id = ?
      ''',
      [orderId],
    );

    final garments = garmentsResult.map((row) {
      return Garment(
        garmentId: row['garment_id'] as int,
        orderId: orderId,
        garmentType: row['garment_type'] as String,
        measurements: jsonDecode(row['measurement_json'] as String? ?? '{}') as Map<String, dynamic>,
        preferences: jsonDecode(row['preference_json'] as String? ?? '{}') as Map<String, dynamic>,
      );
    }).toList();

    return Order(
      orderId: orderRow['order_id'] as int,
      receiptNumber: orderRow['receipt_number'] as String,
      customerId: orderRow['customer_id'] as int,
      customerName: orderRow['customer_name'] as String?,
      orderDate: DateTime.parse(orderRow['order_date'] as String),
      deliveryDate: DateTime.parse(orderRow['delivery_date'] as String),
      status: orderRow['status'] as String,
      remarks: orderRow['remarks'] as String?,
      createdAt: DateTime.parse(orderRow['created_at'] as String),
      garments: garments,
    );
  }

  @override
  Future<List<Order>> getOrders({String? status, int? customerId}) async {
    final db = await _dbService.database;
    List<Map<String, dynamic>> results;

    String query = '''
      SELECT o.*, c.full_name as customer_name 
      FROM orders o 
      JOIN customers c ON o.customer_id = c.customer_id 
    ''';
    List<dynamic> args = [];

    if (status != null && customerId != null) {
      query += ' WHERE o.status = ? AND o.customer_id = ?';
      args = [status, customerId];
    } else if (status != null) {
      query += ' WHERE o.status = ?';
      args = [status];
    } else if (customerId != null) {
      query += ' WHERE o.customer_id = ?';
      args = [customerId];
    }

    query += ' ORDER BY o.delivery_date ASC';

    results = await db.rawQuery(query, args);

    final List<Order> orders = [];
    for (final row in results) {
      final oId = row['order_id'] as int;

      // Fetch garments for each order
      final gResult = await db.rawQuery(
        '''
        SELECT g.garment_id, g.garment_type, m.measurement_json, p.preference_json 
        FROM garments g 
        LEFT JOIN measurements m ON g.garment_id = m.garment_id 
        LEFT JOIN preferences p ON g.garment_id = p.garment_id 
        WHERE g.order_id = ?
        ''',
        [oId],
      );

      final garments = gResult.map((gRow) {
        return Garment(
          garmentId: gRow['garment_id'] as int,
          orderId: oId,
          garmentType: gRow['garment_type'] as String,
          measurements: jsonDecode(gRow['measurement_json'] as String? ?? '{}') as Map<String, dynamic>,
          preferences: jsonDecode(gRow['preference_json'] as String? ?? '{}') as Map<String, dynamic>,
        );
      }).toList();

      orders.add(Order(
        orderId: oId,
        receiptNumber: row['receipt_number'] as String,
        customerId: row['customer_id'] as int,
        customerName: row['customer_name'] as String?,
        orderDate: DateTime.parse(row['order_date'] as String),
        deliveryDate: DateTime.parse(row['delivery_date'] as String),
        status: row['status'] as String,
        remarks: row['remarks'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
        garments: garments,
      ));
    }

    return orders;
  }

  @override
  Future<String> generateReceiptNumber() async {
    final db = await _dbService.database;

    // Load prefix from settings table
    final prefixResult = await db.rawQuery(
      "SELECT setting_value FROM settings WHERE setting_key = 'receipt_prefix' LIMIT 1",
    );
    final prefix = prefixResult.isNotEmpty
        ? prefixResult.first['setting_value'] as String
        : 'SRM-2026';

    // Count existing orders to generate next sequential number
    final countResult = await db.rawQuery('SELECT COUNT(*) as total FROM orders');
    final nextNumber = (countResult.first['total'] as int) + 1;

    // Zero-padded running number: SRM-2026-000042
    final paddedNumber = nextNumber.toString().padLeft(6, '0');
    return '$prefix-$paddedNumber';
  }

  @override
  Future<Map<String, int>> getDashboardStats() async {
    final db = await _dbService.database;

    final results = await db.rawQuery(
      'SELECT status, COUNT(*) as count FROM orders GROUP BY status',
    );

    int pending = 0;
    int cutting = 0;
    int stitching = 0;
    int ready = 0;
    int delivered = 0;

    for (final row in results) {
      final status = row['status'] as String;
      final count = row['count'] as int;

      switch (status) {
        case 'Pending':
          pending = count;
          break;
        case 'Cutting':
          cutting = count;
          break;
        case 'Stitching':
          stitching = count;
          break;
        case 'Ready':
          ready = count;
          break;
        case 'Delivered':
          delivered = count;
          break;
      }
    }

    final totalActive = pending + cutting + stitching + ready;

    return {
      'totalActive': totalActive,
      'pending': pending,
      'cutting': cutting,
      'stitching': stitching,
      'ready': ready,
      'delivered': delivered,
    };
  }
}
