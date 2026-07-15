import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/customer_provider.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../domain/entities/customer.dart';
import '../../../orders/domain/entities/order.dart';

/// CustomerDetailPage displays a comprehensive view of a customer profile.
class CustomerDetailPage extends ConsumerWidget {
  final int customerId;

  const CustomerDetailPage({
    super.key,
    required this.customerId,
  });

  Future<void> _deleteCustomer(BuildContext context, WidgetRef ref, Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile?'),
        content: Text('Are you sure you want to permanently delete ${customer.fullName}? This will also delete all their orders and measurements.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('YES'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(customerProvider.notifier).removeCustomer(customer.customerId!);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer profile deleted.')),
        );
        context.go('/customers');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final ordersAsync = ref.watch(orderProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/customers'),
        ),
        title: const Text('Customer Profile'),
        actions: [
          customerAsync.when(
            data: (customer) => customer != null
                ? IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    onPressed: () => _deleteCustomer(context, ref, customer),
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) {
          if (customer == null) {
            return const Center(child: Text('Customer profile not found.'));
          }

          // Parse notes field containing serialized JSON
          Map<String, dynamic> notesJson = {};
          try {
            notesJson = jsonDecode(customer.notes ?? '{}') as Map<String, dynamic>;
          } catch (_) {
            notesJson = {'notes': customer.notes ?? ''};
          }

          final email = notesJson['email'] as String? ?? 'N/A';
          final additionalNotes = notesJson['notes'] as String? ?? 'No additional notes.';
          final masterMeasurements = notesJson['master_measurements'] as Map<String, dynamic>? ?? {};
          final isVIP = (customer.notes ?? '').toUpperCase().contains('VIP');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Identity Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                customer.fullName.substring(0, 2).toUpperCase(),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isVIP)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'VIP Member',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          customer.fullName,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(customer.mobileNumber, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.mail_outline_rounded, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(email, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        if (customer.address != null && customer.address!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  customer.address!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Master Measurements (Shirt)
                _buildMeasurementsCard(theme, masterMeasurements),
                const SizedBox(height: 16),

                // Order History Timeline Section
                Text(
                  'Order History',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ordersAsync.when(
                  data: (orders) {
                    final customerOrders = orders.where((o) => o.customerId == customerId).toList();
                    return _buildHistoryTimeline(context, theme, customerOrders);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error loading history: $err')),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orders/new?customerId=$customerId'),
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('Create Order'),
      ),
    );
  }

  Widget _buildMeasurementsCard(ThemeData theme, Map<String, dynamic> measurements) {
    final shirtSpecs = measurements['Shirt'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.straighten, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Master Measurements',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'Shirt',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (shirtSpecs.isEmpty)
              const Text('No master measurements registered.')
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                children: [
                  _buildMetricRow('Neck', shirtSpecs['neck']),
                  _buildMetricRow('Chest', shirtSpecs['chest']),
                  _buildMetricRow('Waist', shirtSpecs['waist']),
                  _buildMetricRow('Sleeve', shirtSpecs['sleeve']),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, dynamic value) {
    final displayVal = value != null ? '${value}cm' : '--';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(displayVal, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHistoryTimeline(BuildContext context, ThemeData theme, List<Order> orders) {
    if (orders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              const Text('No order history', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('All future orders placed for this customer will appear here.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final garmentList = order.garments.map((g) => g.garmentType).join(', ');

        return Card(
          child: ListTile(
            leading: Icon(Icons.checkroom, color: theme.colorScheme.primary),
            title: Text(
              order.receiptNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$garmentList | Due: ${DateFormat('MMM dd, yyyy').format(order.deliveryDate)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            onTap: () {
              // Show quick detail card in popup
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildOrderSummarySheet(theme, order),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderSummarySheet(ThemeData theme, Order order) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.receiptNumber,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Date:'),
              Text(DateFormat('MMM dd, yyyy').format(order.orderDate), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Date:'),
              Text(DateFormat('MMM dd, yyyy').format(order.deliveryDate), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'GARMENT LIST',
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          ...order.garments.map((garment) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(garment.garmentType, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      garment.measurements.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )),
          if (order.remarks != null && order.remarks!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Remarks: ${order.remarks!}', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
