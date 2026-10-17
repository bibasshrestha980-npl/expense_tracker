import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../services/vault_cipher.dart';
import '../services/repositories/vault_repository.dart';
import '../services/repositories/expense_repository.dart';
import 'dashboard.dart';

/// Compatibility gate for records encrypted by the retired vault feature.
/// New and unencrypted accounts never need a recovery key.
class VaultGate extends StatefulWidget {
  final String uid;
  final FirebaseFirestore? firestore;
  const VaultGate({super.key, required this.uid, this.firestore});
  @override
  State<VaultGate> createState() => _VaultGateState();
}

class _VaultGateState extends State<VaultGate> {
  final keyInput = TextEditingController();
  bool loading = true, busy = false, needsConversion = false;
  String? error;
  FirebaseFirestore get database =>
      widget.firestore ?? FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> get config =>
      database.doc('users/${widget.uid}/vault/config');
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final encrypted = await database
          .collection('users')
          .doc(widget.uid)
          .collection('expenses')
          .where('v', isEqualTo: 1)
          .limit(1)
          .get(const GetOptions(source: Source.server));
      if (encrypted.docs.isEmpty) await config.delete();
      if (mounted) {
        setState(() {
          needsConversion = encrypted.docs.isNotEmpty;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Could not check existing records. Connect to the internet and retry.';
        });
      }
    }
  }

  Future<void> convert() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final cipher = VaultCipher.fromRecoveryKey(keyInput.text);
      await VaultRepository(
        widget.uid,
        cipher,
        firestore: database,
      ).restorePlaintext();
      await config.delete();
      keyInput.clear();
      if (mounted) {
        setState(() {
          needsConversion = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Conversion could not finish. Check the original recovery key and connection, then retry. Encrypted records cannot be restored without their key.';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    keyInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!loading && !needsConversion && error == null) {
      return ChangeNotifierProvider(
        create: (_) => ExpenseProvider(
          widget.uid,
          repository: FirestoreExpenseRepository(firestore: database),
        ),
        child: const Dashboard(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update account storage'),
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
                if (loading) const LinearProgressIndicator(),
                if (needsConversion) ...[
                  const Text(
                    'Remove the old recovery-key lock',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Some existing transactions were encrypted. Enter the original key once to convert them to standard account storage. Afterwards, sign-in is enough. Transactions will remain private to your account, but will no longer use end-to-end encryption.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: keyInput,
                    enabled: !busy,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Original recovery key',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : convert,
                    child: Text(
                      busy
                          ? 'Converting records...'
                          : 'Convert and remove key requirement',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'If the key is lost, these encrypted records cannot be recovered. No records will be deleted automatically.',
                  ),
                ],
                if (error != null) ...[
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: busy ? null : load,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
