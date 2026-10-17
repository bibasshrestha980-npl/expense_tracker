import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../services/vault_cipher.dart';
import '../services/repositories/vault_repository.dart';
import 'dashboard.dart';

class VaultGate extends StatefulWidget {
  final String uid;
  final FirebaseFirestore? firestore;
  const VaultGate({super.key, required this.uid, this.firestore});
  @override
  State<VaultGate> createState() => _VaultGateState();
}

class _VaultGateState extends State<VaultGate> with WidgetsBindingObserver {
  final keyInput = TextEditingController();
  bool loading = true, busy = false, exists = false;
  String? generatedKey, error;
  VaultRepository? repository;
  int lockEpoch = 0;
  FirebaseFirestore get database =>
      widget.firestore ?? FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> get config =>
      database.doc('users/${widget.uid}/vault/config');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  Future<void> load() async {
    try {
      final d = await config.get(const GetOptions(source: Source.server));
      final generated = d.exists ? null : await VaultCipher.generateKey();
      if (mounted) {
        setState(() {
          exists = d.exists;
          generatedKey = generated;
          loading = false;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error =
              'Could not check your vault. Connect to the internet and retry.';
        });
      }
    }
  }

  void lock() {
    lockEpoch++;
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() {
        repository = null;
        keyInput.clear();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (repository != null || busy) lock();
    }
  }

  Future<void> unlock() async {
    final epoch = lockEpoch;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final entered = keyInput.text.trim();
      if (!exists && (generatedKey == null || entered != generatedKey)) {
        throw const FormatException('Confirm the saved recovery key');
      }
      final cipher = VaultCipher.fromRecoveryKey(entered);
      final contextId = '${widget.uid}/vault/config';
      if (!exists) {
        final encrypted = await cipher.seal({
          'check': 'pocket-vault',
        }, contextId);
        await database.runTransaction((tx) async {
          if ((await tx.get(config)).exists) {
            throw StateError('Vault already created. Reload and unlock it.');
          }
          tx.set(config, encrypted);
        });
        if (mounted) {
          setState(() {
            exists = true;
            generatedKey = null;
          });
        }
      }
      final d = await config.get(const GetOptions(source: Source.server));
      final check = await cipher.open(d.data()!, contextId);
      if (check['check'] != 'pocket-vault') throw StateError('Invalid vault');
      final repo = VaultRepository(widget.uid, cipher, firestore: database);
      await repo.migrateLegacy();
      if (mounted && epoch == lockEpoch) {
        setState(() {
          repository = repo;
          keyInput.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Could not unlock or finish encryption. Check your recovery key and connection, then retry. Your key cannot be reset.';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    keyInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (repository != null) {
      return ChangeNotifierProvider(
        create: (_) => ExpenseProvider(widget.uid, repository: repository),
        child: Column(
          children: [
            Material(
              child: SafeArea(
                bottom: false,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Encrypted vault unlocked'),
                  trailing: TextButton.icon(
                    onPressed: lock,
                    icon: const Icon(Icons.lock),
                    label: const Text('Lock'),
                  ),
                ),
              ),
            ),
            const Expanded(child: Dashboard()),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Private transaction vault'),
        actions: [
          TextButton(
            onPressed: busy
                ? null
                : () => context.read<AuthProvider>().signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.enhanced_encryption_outlined, size: 56),
                const SizedBox(height: 20),
                Text(
                  exists ? 'Unlock your vault' : 'Save your recovery key',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Only this key can decrypt your transactions. Keep it in a password manager or another safe place. Losing it means losing access, even after a password reset. It is never uploaded or saved by Pocket.',
                ),
                const SizedBox(height: 16),
                if (loading) const LinearProgressIndicator(),
                if (generatedKey != null) ...[
                  SelectableText(
                    generatedKey!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Save the key, then enter it below to confirm. Existing transactions will be encrypted before the dashboard opens. Keep the app open until this finishes.',
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: keyInput,
                  enabled: !busy && !loading,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: exists
                        ? 'Recovery key'
                        : 'Re-enter saved recovery key',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (error != null) ...[
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: busy ? null : load,
                    child: const Text('Reload vault status'),
                  ),
                ],
                FilledButton(
                  onPressed:
                      busy || loading || (!exists && generatedKey == null)
                      ? null
                      : unlock,
                  child: Text(
                    busy
                        ? 'Encrypting / unlocking…'
                        : exists
                        ? 'Unlock vault'
                        : 'Create vault and encrypt records',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The vault locks when the app goes into the background. Reports copied to the clipboard are readable outside the vault.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
