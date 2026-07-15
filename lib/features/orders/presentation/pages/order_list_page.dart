import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../../domain/entities/order.dart';

/// OrderListPage displays orders categorized by current construction progress.
class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage> {
  String _selectedFilter = 'All';

  void _updateStatus(int orderId, String currentStatus) async {
    final theme = Theme.of(context);
    final nextStatus = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Change Order Status'),
        children: ['Pending', 'Cutting', 'Stitching', 'Ready', 'Delivered'].map((status) {
          final isCurrent = status == currentStatus;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, status),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(status, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                if (isCurrent) Icon(Icons.check, color: theme.colorScheme.primary, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (nextStatus != null && nextStatus != currentStatus) {
      final success = await ref.read(orderProvider.notifier).editOrderStatus(orderId, nextStatus);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $nextStatus.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(orderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {},
            ),
            Text(
              'TailorPro',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'Pending', 'Cutting', 'Stitching', 'Ready', 'Delivered'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        ref.read(orderProvider.notifier).loadOrders(
                              status: filter == 'All' ? null : filter,
                            );
                      },
                      selectedColor: theme.colorScheme.secondaryContainer,
                      checkmarkColor: theme.colorScheme.onSecondaryContainer,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(orderProvider.notifier).loadOrders(
                      status: _selectedFilter == 'All' ? null : _selectedFilter,
                    );
              },
              child: ordersAsync.when(
                data: (orders) => _buildOrdersList(context, theme, orders),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading orders: $err')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orders/new'),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('New Order'),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, ThemeData theme, List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No orders matching filter',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'All current garments specifications will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final garmentTypes = order.garments.map((g) => g.garmentType).join(', ');
        final dueDays = order.deliveryDate.difference(DateTime.now()).inDays;
        String countdownText = '';
        if (dueDays == 0) {
          countdownText = 'Deliver today';
        } else if (dueDays == 1) {
          countdownText = 'Deliver tomorrow';
        } else if (dueDays > 1) {
          countdownText = 'Deliver in $dueDays days';
        } else {
          countdownText = 'Overdue by ${dueDays.abs()} days';
        }

        final isOverdue = dueDays < 0 && order.status != 'Delivered';

        return Card(
          child: InkWell(
            onTap: () => _updateStatus(order.orderId!, order.status),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.receiptNumber,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.customerName ?? 'Unknown Client',
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(theme, order.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusTextColor(theme, order.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.checkroom_rounded, size: 16, color: theme.colorScheme.outline),
                          const SizedBox(width: 6),
                          Text(
                            garmentTypes.isNotEmpty ? garmentTypes : 'Specs definition',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        countdownText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isOverdue ? theme.colorScheme.error : theme.colorScheme.outline,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(ThemeData theme, String status) {
    switch (status) {
      case 'Pending':
        return theme.colorScheme.errorContainer;
      case 'Ready':
        return theme.colorScheme.tertiaryContainer;
      case 'Delivered':
        return theme.colorScheme.surfaceContainerHighest;
      default: // Cutting, Stitching
        return theme.colorScheme.secondaryContainer;
    }
  }

  Color _getStatusTextColor(ThemeData theme, String status) {
    switch (status) {
      case 'Pending':
        return theme.colorScheme.onErrorContainer;
      case 'Ready':
        return theme.colorScheme.onTertiaryContainer;
      case 'Delivered':
        return theme.colorScheme.onSurfaceVariant;
      default: // Cutting, Stitching
        return theme.colorScheme.onSecondaryContainer;
    }
  }
}
