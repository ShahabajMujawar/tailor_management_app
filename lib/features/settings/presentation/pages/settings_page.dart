import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/di/injection.dart';

/// SettingsPage lets users update shop profile details, perform offline Excel
/// database backups, restore from spreadsheet backups, and manage sessions.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopNameController;
  late TextEditingController _shopAddressController;
  late TextEditingController _prefixController;

  bool _isSaving = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController();
    _shopAddressController = TextEditingController();
    _prefixController = TextEditingController();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _saveShopDetails() async {
    setState(() => _isSaving = true);
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.saveSetting('shop_name', _shopNameController.text.trim());
    await notifier.saveSetting('shop_address', _shopAddressController.text.trim());
    await notifier.saveSetting('receipt_prefix', _prefixController.text.trim());
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop settings updated successfully.')),
      );
    }
  }

  Future<void> _exportBackupFile() async {
    setState(() => _isBackingUp = true);
    try {
      final path = await locator<BackupService>().exportBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved successfully: $path'), duration: const Duration(seconds: 5)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export backup: $e')),
        );
      }
    } finally {
      setState(() => _isBackingUp = false);
    }
  }

  Future<void> _importBackupFile() async {
    // In production, we'd use a file picker. Here we check for existing backup files in the app folder
    // Or prompt for a mock restore action for demo validation.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Database?'),
        content: const Text('WARNING: Restoring will overwrite all current clients, measurements, and orders. Are you sure you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('RESTORE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isRestoring = true);
      try {
        // Find latest backup file or prompt
        // For testing/mocking in this environment, we can simulate checking a path or run a restore.
        // We will notify them.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Locating backup files...')),
        );
        
        // Simulating completion since file picker requires OS integration
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restore requires choosing a valid .xlsx spreadsheet path.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to import backup: $e')),
          );
        }
      } finally {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    // Sync controllers
    if (settings.isNotEmpty && _shopNameController.text.isEmpty) {
      _shopNameController.text = settings['shop_name'] ?? '';
      _shopAddressController.text = settings['shop_address'] ?? '';
      _prefixController.text = settings['receipt_prefix'] ?? '';
    }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shop Details Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storefront, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Shop Profile', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _shopNameController,
                        decoration: const InputDecoration(
                          labelText: 'Shop Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _shopAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Shop Address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _prefixController,
                        decoration: const InputDecoration(
                          labelText: 'Receipt Prefix',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveShopDetails,
                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Shop Profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Backup & Restore Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.backup_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Backup & Restore', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Export current client metrics to an Excel workbook or restore from an existing spreadsheet.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isBackingUp ? null : _exportBackupFile,
                      icon: const Icon(Icons.download),
                      label: const Text('Backup Database (Excel)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isRestoring ? null : _importBackupFile,
                      icon: const Icon(Icons.upload),
                      label: const Text('Restore Database (Excel)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Session Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.logout, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Text('Session Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).signOut();
                        if (mounted) {
                          context.go('/login');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
