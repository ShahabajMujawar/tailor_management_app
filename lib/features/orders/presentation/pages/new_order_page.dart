import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../providers/order_provider.dart';
import '../../domain/entities/order.dart';
import '../../../customers/domain/entities/customer.dart';

/// NewOrderPage manages order creation, pre-filling customer details,
/// and recording individual garment measurements.
class NewOrderPage extends ConsumerStatefulWidget {
  final int? preselectedCustomerId;

  const NewOrderPage({
    super.key,
    this.preselectedCustomerId,
  });

  @override
  ConsumerState<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends ConsumerState<NewOrderPage> {
  final _formKey = GlobalKey<FormState>();

  Customer? _selectedCustomer;
  final List<String> _selectedGarments = ['Shirt'];
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));
  final _remarksController = TextEditingController();

  // Measurements map: { GarmentType: { Metric: Controller } }
  final Map<String, Map<String, TextEditingController>> _measurementControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeGarmentControllers('Shirt');
  }

  @override
  void dispose() {
    _remarksController.dispose();
    for (final entry in _measurementControllers.values) {
      for (final ctrl in entry.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  void _initializeGarmentControllers(String type) {
    if (_measurementControllers.containsKey(type)) return;

    final Map<String, TextEditingController> metrics = {};
    final listMetrics = type == 'Shirt' || type == 'Kurta'
        ? ['neck', 'chest', 'waist', 'sleeve']
        : ['waist', 'length', 'hip', 'inseam'];

    for (final metric in listMetrics) {
      metrics[metric] = TextEditingController();
    }

    _measurementControllers[type] = metrics;
  }

  void _loadMasterMeasurements() {
    if (_selectedCustomer == null) return;

    try {
      final notesJson = jsonDecode(_selectedCustomer!.notes ?? '{}') as Map<String, dynamic>;
      final masterMeasurements = notesJson['master_measurements'] as Map<String, dynamic>? ?? {};

      for (final garmentType in _selectedGarments) {
        final garmentMaster = masterMeasurements[garmentType] as Map<String, dynamic>?;
        if (garmentMaster != null) {
          final controllers = _measurementControllers[garmentType];
          if (controllers != null) {
            controllers.forEach((key, ctrl) {
              final val = garmentMaster[key];
              if (val != null) {
                ctrl.text = val.toString();
              }
            });
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loaded master measurements for selected garments.')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No master measurements available for this customer.')),
      );
    }
  }

  Future<void> _selectDeliveryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _deliveryDate) {
      setState(() {
        _deliveryDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer.')),
      );
      return;
    }

    if (_selectedGarments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one garment.')),
      );
      return;
    }

    // Auto-generate receipt number
    final receiptNum = await ref.read(receiptNumberProvider.future);

    final List<Garment> garmentsList = [];
    for (final gType in _selectedGarments) {
      final controllers = _measurementControllers[gType] ?? {};
      final Map<String, double> measurements = {};

      controllers.forEach((metric, ctrl) {
        measurements[metric] = double.tryParse(ctrl.text) ?? 0.0;
      });

      garmentsList.add(Garment(
        garmentType: gType,
        measurements: measurements,
        preferences: const {},
      ));
    }

    final order = Order(
      receiptNumber: receiptNum,
      customerId: _selectedCustomer!.customerId!,
      orderDate: DateTime.now(),
      deliveryDate: _deliveryDate,
      status: 'Pending',
      remarks: _remarksController.text.trim(),
      createdAt: DateTime.now(),
      garments: garmentsList,
    );

    final saved = await ref.read(orderProvider.notifier).addOrder(order);

    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${saved.receiptNumber} Created successfully.')),
      );
      context.go('/orders');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save order. please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersAsync = ref.watch(customerProvider);
    final receiptNumAsync = ref.watch(receiptNumberProvider);

    // Preselect customer logic if query param passed
    if (widget.preselectedCustomerId != null && _selectedCustomer == null) {
      customersAsync.whenData((list) {
        final found = list.firstWhere(
          (c) => c.customerId == widget.preselectedCustomerId,
          orElse: () => list.first,
        );
        setState(() {
          _selectedCustomer = found;
          _loadMasterMeasurements();
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('New Order'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Client Selection Section
              Text('Client Selection', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              customersAsync.when(
                data: (list) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Customer>(
                      value: _selectedCustomer,
                      hint: const Text('Choose Client'),
                      isExpanded: true,
                      onChanged: (customer) {
                        setState(() {
                          _selectedCustomer = customer;
                          _loadMasterMeasurements();
                        });
                      },
                      items: list.map((c) {
                        return DropdownMenuItem<Customer>(
                          value: c,
                          child: Text('${c.fullName} (${c.mobileNumber})'),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading customers: $err'),
              ),
              const SizedBox(height: 24),

              // Garment Type selection
              Text('Select Garments', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Shirt', 'Pant', 'Kurta', 'Pajama'].map((type) {
                  final isSelected = _selectedGarments.contains(type);
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGarments.add(type);
                          _initializeGarmentControllers(type);
                        } else {
                          _selectedGarments.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Garment Measurements Section
              if (_selectedGarments.isNotEmpty) ...[
                Text('Recorded Measurements (cm)', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._selectedGarments.map((type) => _buildGarmentMeasurementsInput(theme, type)),
                const SizedBox(height: 24),
              ],

              // Delivery Date Selector
              Text('Delivery Schedule', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                  title: const Text('Delivery Date'),
                  subtitle: Text(DateFormat('MMMM dd, yyyy').format(_deliveryDate)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () => _selectDeliveryDate(context),
                ),
              ),
              const SizedBox(height: 24),

              // Remarks
              Text('Remarks & Customization Requests', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Double cuff, slim-fit silhouette, specific collar style...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 36),

              // Receipt number representation
              receiptNumAsync.when(
                data: (num) => Text(
                  'Auto-Generating: $num',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 12),

              // Submit Button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(54),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Create Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGarmentMeasurementsInput(ThemeData theme, String type) {
    final controllers = _measurementControllers[type] ?? {};

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$type Specs',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controllers.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final key = controllers.keys.elementAt(index);
              final ctrl = controllers[key]!;

              return Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      key.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline, fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: '0.0',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const Text('cm', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
