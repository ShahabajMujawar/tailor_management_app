import '../../../../core/database/database_service.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';

/// SQLite implementation of the [CustomerRepository] interface.
class CustomerRepositoryImpl implements CustomerRepository {
  final DatabaseService _dbService;

  CustomerRepositoryImpl(this._dbService);

  @override
  Future<Customer> createCustomer(Customer customer) async {
    final db = await _dbService.database;

    final customerId = await db.rawInsert(
      '''
      INSERT INTO customers 
      (full_name, mobile_number, alternate_number, address, notes, created_at, updated_at) 
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        customer.fullName.trim(),
        customer.mobileNumber.trim(),
        customer.alternateNumber?.trim(),
        customer.address?.trim(),
        customer.notes?.trim(),
        customer.createdAt.toIso8601String(),
        customer.updatedAt.toIso8601String(),
      ],
    );

    return customer.copyWith(customerId: customerId);
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    if (customer.customerId == null) throw Exception('Customer ID is required for update.');
    final db = await _dbService.database;

    await db.rawUpdate(
      '''
      UPDATE customers 
      SET full_name = ?, mobile_number = ?, alternate_number = ?, address = ?, notes = ?, updated_at = ? 
      WHERE customer_id = ?
      ''',
      [
        customer.fullName.trim(),
        customer.mobileNumber.trim(),
        customer.alternateNumber?.trim(),
        customer.address?.trim(),
        customer.notes?.trim(),
        DateTime.now().toIso8601String(),
        customer.customerId,
      ],
    );
  }

  @override
  Future<void> deleteCustomer(int customerId) async {
    final db = await _dbService.database;
    await db.rawDelete('DELETE FROM customers WHERE customer_id = ?', [customerId]);
  }

  @override
  Future<Customer?> getCustomerById(int customerId) async {
    final db = await _dbService.database;
    final results = await db.rawQuery(
      'SELECT * FROM customers WHERE customer_id = ? LIMIT 1',
      [customerId],
    );

    if (results.isEmpty) return null;
    return _mapRowToCustomer(results.first);
  }

  @override
  Future<List<Customer>> getCustomers({String? filter}) async {
    final db = await _dbService.database;
    List<Map<String, dynamic>> results;

    if (filter != null && filter.isNotEmpty) {
      if (filter.toUpperCase() == 'VIP') {
        // Mock VIP filter: customers with note containing VIP, or order spend
        // Here we filter by note containing 'VIP'
        results = await db.rawQuery(
          "SELECT * FROM customers WHERE notes LIKE '%VIP%' ORDER BY full_name ASC",
        );
      } else if (filter.toUpperCase() == 'NEW') {
        // Filter created within the last 7 days
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
        results = await db.rawQuery(
          "SELECT * FROM customers WHERE created_at >= ? ORDER BY created_at DESC",
          [sevenDaysAgo],
        );
      } else {
        results = await db.rawQuery('SELECT * FROM customers ORDER BY full_name ASC');
      }
    } else {
      results = await db.rawQuery('SELECT * FROM customers ORDER BY full_name ASC');
    }

    return results.map(_mapRowToCustomer).toList();
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await _dbService.database;
    final cleanQuery = '%${query.trim()}%';

    final results = await db.rawQuery(
      '''
      SELECT * FROM customers 
      WHERE full_name LIKE ? OR mobile_number LIKE ? 
      ORDER BY full_name ASC
      ''',
      [cleanQuery, cleanQuery],
    );

    return results.map(_mapRowToCustomer).toList();
  }

  Customer _mapRowToCustomer(Map<String, dynamic> row) {
    return Customer(
      customerId: row['customer_id'] as int,
      fullName: row['full_name'] as String,
      mobileNumber: row['mobile_number'] as String,
      alternateNumber: row['alternate_number'] as String?,
      address: row['address'] as String?,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
