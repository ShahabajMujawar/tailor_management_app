import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

/// DashboardPage showing shop statistics, quick actions, today's schedule,
/// and recent orders.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final ordersAsync = ref.watch(orderProvider);
    final authState = ref.watch(authProvider);

    final currentUser = authState.user;
    final initials = currentUser != null && currentUser.username.isNotEmpty
        ? currentUser.username.substring(0, 2).toUpperCase()
        : 'TA';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.architecture_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'TailorPro',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications are currently clear.')),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(orderProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bento Stats Section
              statsAsync.when(
                data: (stats) => _buildBentoGrid(context, theme, stats),
                loading: () => _buildBentoGridLoading(theme),
                error: (err, _) => Center(child: Text('Error loading stats: $err')),
              ),
              const SizedBox(height: 28),

              // Quick Actions Section
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context, theme),
              const SizedBox(height: 28),

              // Today's Deliveries
              ordersAsync.when(
                data: (orders) => _buildTodayDeliveries(context, theme, orders),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 28),

              // Recent Orders
              Text(
                'Recent Orders',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ordersAsync.when(
                data: (orders) => _buildRecentOrdersList(context, theme, orders),
                loading: () => _buildRecentOrdersLoading(theme),
                error: (err, _) => Center(child: Text('Error loading orders: $err')),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/orders/new'),
        tooltip: 'New Order',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, ThemeData theme, Map<String, int> stats) {
    final activeOrders = stats['totalActive'] ?? 0;
    final pending = stats['pending'] ?? 0;
    final ready = stats['ready'] ?? 0;

    return Column(
      children: [
        // Total Active Orders (Large Card)
        Card(
          color: theme.colorScheme.primary,
          child: InkWell(
            onTap: () => context.go('/orders'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL ACTIVE ORDERS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$activeOrders',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 32,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Row of secondary stats
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pending_actions_rounded, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Pending',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$pending',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Requires Cut',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Ready',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$ready',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Trial Ready',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBentoGridLoading(ThemeData theme) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    final actions = [
      _ActionItem(Icons.add_business_outlined, 'New Order', () => context.push('/orders/new')),
      _ActionItem(Icons.straighten_outlined, 'Measure', () => context.go('/customers')),
      _ActionItem(Icons.payments_outlined, 'Payment', () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment tracking is planned for next version.')),
        );
      }),
      _ActionItem(Icons.content_cut_outlined, 'Pattern', () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pattern engine is simulated offline.')),
        );
      }),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = actions[index];
          return Container(
            width: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.5),
            ),
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(item.icon, color: theme.colorScheme.onSecondaryContainer),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayDeliveries(BuildContext context, ThemeData theme, List<Order> orders) {
    final today = DateTime.now();
    final todayOrders = orders.where((o) =>
        o.deliveryDate.year == today.year &&
        o.deliveryDate.month == today.month &&
        o.deliveryDate.day == today.day &&
        o.status != 'Delivered');

    if (todayOrders.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: theme.colorScheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Deliveries",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onTertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${todayOrders.length} Pending',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todayOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final order = todayOrders.elementAt(index);
              final garmentNames = order.garments.map((g) => g.garmentType).join(', ');

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onTertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName ?? 'Unknown Customer',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                          Text(
                            garmentNames.isNotEmpty ? garmentNames : 'Garment specs',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onTertiaryContainer.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/customers/${order.customerId}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.onTertiary,
                        foregroundColor: theme.colorScheme.tertiary,
                        minimumSize: const Size(64, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        DateFormat('HH:mm').format(order.deliveryDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildRecentOrdersList(BuildContext context, ThemeData theme, List<Order> orders) {
    if (orders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.checkroom_outlined, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              const Text('No orders created yet.', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Click the + button to create your first order.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final recentList = orders.take(3).toList();

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = recentList[index];
            final garmentNames = order.garments.map((g) => g.garmentType).join(', ');
            final isTuxOrSuit = garmentNames.toLowerCase().contains('suit');

            return Card(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isTuxOrSuit ? Icons.checkroom_rounded : Icons.checkroom_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  order.customerName ?? 'Unknown Customer',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  garmentNames.isNotEmpty ? garmentNames : 'Garment description',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(theme, order.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getStatusTextColor(theme, order.status),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                onTap: () => context.push('/customers/${order.customerId}'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentOrdersLoading(ThemeData theme) {
    return const Center(child: CircularProgressIndicator());
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${difference}d ago';
    }
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _ActionItem(this.icon, this.label, this.onTap);
}
