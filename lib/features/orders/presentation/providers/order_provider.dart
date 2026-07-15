import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

/// Notifier class that manages loading, creating, status modifications, and deletion of orders.
class OrderNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final OrderRepository _repository;

  OrderNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  /// Loads all orders from SQLite database, applying status or customer filter.
  Future<void> loadOrders({String? status, int? customerId}) async {
    state = const AsyncValue.loading();
    try {
      final orders = await _repository.getOrders(status: status, customerId: customerId);
      state = AsyncValue.data(orders);
    } catch (e, stackTrace) {
      state = AsyncValue.error(
        'Unable to load orders. Please try again.',
        stackTrace,
      );
    }
  }

  /// Inserts a new order.
  Future<Order?> addOrder(Order order) async {
    try {
      final savedOrder = await _repository.createOrder(order);
      state.whenData((currentList) {
        state = AsyncValue.data([...currentList, savedOrder]);
      });
      return savedOrder;
    } catch (e) {
      return null;
    }
  }

  /// Updates an order status.
  Future<bool> editOrderStatus(int orderId, String status) async {
    try {
      await _repository.updateOrderStatus(orderId, status);
      state.whenData((currentList) {
        final updatedList = currentList.map((item) {
          return item.orderId == orderId ? item.copyWith(status: status) : item;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deletes an order by ID.
  Future<bool> removeOrder(int orderId) async {
    try {
      await _repository.deleteOrder(orderId);
      state.whenData((currentList) {
        final updatedList = currentList.where((item) => item.orderId != orderId).toList();
        state = AsyncValue.data(updatedList);
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider of the [OrderNotifier] state.
final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<List<Order>>>((ref) {
  return OrderNotifier(locator<OrderRepository>());
});

/// Provider for a specific order.
final orderDetailProvider = FutureProvider.family<Order?, int>((ref, orderId) async {
  return await locator<OrderRepository>().getOrderById(orderId);
});

/// Provider for the next sequential receipt number.
final receiptNumberProvider = FutureProvider.autoDispose<String>((ref) async {
  return await locator<OrderRepository>().generateReceiptNumber();
});

/// Provider that calculates dashboard statistics.
final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  // Re-fetch stats when orders state updates
  ref.watch(orderProvider);
  return await locator<OrderRepository>().getDashboardStats();
});
