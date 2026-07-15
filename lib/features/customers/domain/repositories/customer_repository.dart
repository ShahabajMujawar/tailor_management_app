import '../entities/customer.dart';

/// Repository interface for managing customer records.
abstract class CustomerRepository {
  /// Inserts a new customer into the storage. Returns the saved [Customer] with ID.
  Future<Customer> createCustomer(Customer customer);

  /// Updates an existing customer's details.
  Future<void> updateCustomer(Customer customer);

  /// Deletes a customer by ID.
  Future<void> deleteCustomer(int customerId);

  /// Retrieves a customer profile by ID.
  Future<Customer?> getCustomerById(int customerId);

  /// Retrieves all customers, with an optional filter category (VIP, NEW, INACTIVE).
  Future<List<Customer>> getCustomers({String? filter});

  /// Searches customers by name or phone number.
  Future<List<Customer>> searchCustomers(String query);
}
