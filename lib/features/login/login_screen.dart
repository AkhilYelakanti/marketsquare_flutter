import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/dev_seed.dart';
import '../../router/app_routes.dart';
import '../../widgets/brand_logo.dart';
import 'login_controller.dart';

/// Port of native `LoginScreen`. `isUserSetup` reuses the same screen for the
/// "User Setup" re-login flow (prefilled + confirmation dialog + BACK button).
class LoginScreen extends ConsumerStatefulWidget {
  final bool isUserSetup;
  const LoginScreen({super.key, this.isUserSetup = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userId = TextEditingController();
  final _password = TextEditingController();
  final _hostId = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isUserSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(loginControllerProvider.notifier).onUserSetup();
      });
    }
  }

  @override
  void dispose() {
    _userId.dispose();
    _password.dispose();
    _hostId.dispose();
    super.dispose();
  }

  void _sync(TextEditingController c, String v) {
    if (c.text != v) {
      c.value = TextEditingValue(
        text: v,
        selection: TextSelection.collapsed(offset: v.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final state = ref.watch(loginControllerProvider);
    final ctrl = ref.read(loginControllerProvider.notifier);

    // Keep controllers in sync for prefilled (user-setup) values.
    _sync(_userId, state.userId);
    _sync(_password, state.password);
    _sync(_hostId, state.hostId);

    ref.listen(loginControllerProvider.select((s) => s.loginSuccess), (_, ok) {
      if (ok == true) context.go(Routes.tos);
    });
    ref.listen(loginControllerProvider.select((s) => s.error), (_, err) {
      if (err != null) _showError(err, ctrl);
    });
    ref.listen(loginControllerProvider.select((s) => s.showConfirmationDialog),
        (_, show) {
      if (show == true) _showConfirm(ctrl);
    });

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leading: const Padding(padding: EdgeInsets.all(8), child: BrandLogo(size: 40)),
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppConstants.appTitle,
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500)),
            Text('SETUP DEVICE',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: const [Padding(padding: EdgeInsets.all(8), child: BrandLogo(size: 40))],
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _userId,
                  onChanged: ctrl.setUserId,
                  decoration: const InputDecoration(
                      labelText: 'User ID', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _password,
                  onChanged: ctrl.setPassword,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Setup Key / Password',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _hostId,
                  onChanged: ctrl.setHostId,
                  decoration: const InputDecoration(
                      labelText: 'Host ID', border: OutlineInputBorder()),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await seedDemo(ref);
                      if (context.mounted) context.go(Routes.dashboard);
                    },
                    icon: const Icon(Icons.science),
                    label: const Text('DEV DEMO (no backend)'),
                  ),
                ],
              ],
            ),
          ),
          if (state.isLoading)
            Center(child: CircularProgressIndicator(color: primary)),
        ],
      ),
      bottomNavigationBar: Container(
        color: primary,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: widget.isUserSetup
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.end,
          children: [
            if (widget.isUserSetup)
              _barButton('BACK', primary,
                  () => context.canPop() ? context.pop() : null),
            _barButton(
              'NEXT',
              primary,
              state.isLoading
                  ? null
                  : () => ctrl.onLoginClick(isUserSetup: widget.isUserSetup),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message, LoginController ctrl) {
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dctx).pop();
              ctrl.clearError();
            },
            child: const Text('OKAY'),
          ),
        ],
      ),
    );
  }

  void _showConfirm(LoginController ctrl) {
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Warning'),
        content: const Text(
            'Continuing with new credentials will permanently delete all data associated with the current account.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dctx).pop();
              ctrl.dismissConfirmation();
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dctx).pop();
              ctrl.confirmAndLogin();
            },
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
  }

  Widget _barButton(String text, Color primary, VoidCallback? onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, foregroundColor: primary),
      child: Text(text),
    );
  }
}
