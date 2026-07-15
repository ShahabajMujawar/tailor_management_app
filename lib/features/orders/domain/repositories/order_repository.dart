import '../entities/order.dart';

/// Repository interface for managing orders, garments, measurements, and stats.
abstract class OrderRepository {
  /// Inserts a new order along with its garments, measurements, and preferences.
  Future<Order> createOrder(Order order);

  /// Updates an existing order's metadata and garments details.
  Future<void> updateOrder(Order order);

  /// Updates the status (Pending, Cutting, Stitching, Ready, Delivered) of an order.
  Future<void> updateOrderStatus(int orderId, String status);

  /// Deletes an order by ID (cascades to garments, measurements, and preferences).
  Future<void> deleteOrder(int orderId);

  /// Retrieves an order profile by ID (loads all associated garments and specs).
  Future<Order?> getOrderById(int orderId);

  /// Retrieves all orders, with optional filters for status or customer.
  Future<List<Order>> getOrders({String? status, int? customerId});

  /// Generates a unique sequential receipt number using the configured prefix.
  Future<String> generateReceiptNumber();

  /// Retrieves aggregate dashboard statistics (Total Active, Pending, Ready counts).
  Future<Map<String, int>> getDashboardStats();
}
