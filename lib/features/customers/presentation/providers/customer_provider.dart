import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';

/// Notifier class that manages customer loading, creating, updating, and deletion state.
class CustomerNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final CustomerRepository _repository;

  CustomerNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  /// Loads all customer profiles from SQLite database.
  Future<void> loadCustomers({String? filter}) async {
    state = const AsyncValue.loading();
    try {
      final customers = await _repository.getCustomers(filter: filter);
      state = AsyncValue.data(customers);
    } catch (e, stackTrace) {
      state = AsyncValue.error(
        'Unable to load customer profiles. Please try again.',
        stackTrace,
      );
    }
  }

  /// Inserts a new customer profile.
  Future<Customer?> addCustomer(Customer customer) async {
    try {
      final savedCustomer = await _repository.createCustomer(customer);
      state.whenData((currentList) {
        state = AsyncValue.data([...currentList, savedCustomer]);
      });
      return savedCustomer;
    } catch (e) {
      return null;
    }
  }

  /// Updates an existing customer profile.
  Future<bool> editCustomer(Customer customer) async {
    try {
      await _repository.updateCustomer(customer);
      state.whenData((currentList) {
        final updatedList = currentList.map((item) {
          return item.customerId == customer.customerId ? customer : item;
        }).toList();
        state = AsyncValue.data(updatedList);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Removes a customer profile.
  Future<bool> removeCustomer(int customerId) async {
    try {
      await _repository.deleteCustomer(customerId);
      state.whenData((currentList) {
        final updatedList = currentList.where((item) => item.customerId != customerId).toList();
        state = AsyncValue.data(updatedList);
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider of the [CustomerNotifier] state.
final customerProvider =
    StateNotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>((ref) {
  return CustomerNotifier(locator<CustomerRepository>());
});

/// Provider for a specific customer profile.
final customerDetailProvider = FutureProvider.family<Customer?, int>((ref, customerId) async {
  return await locator<CustomerRepository>().getCustomerById(customerId);
});

/// Provider that searches customer database.
final customerSearchProvider = FutureProvider.family<List<Customer>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  return await locator<CustomerRepository>().searchCustomers(query);
});
