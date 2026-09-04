import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../navigation.dart';

/// Drop-in replacement for `Text('${snap.error}')` in FutureBuilder
/// error branches. If the error is a 401 (token invalid/expired) —
/// which, in the normal case, ApiClient has already auto-logged the
/// user out for — this is the fallback safety net: a proper message
/// and a button back to login, instead of the bare exception text.
class AppErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  const AppErrorView({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isAuthError = error is ApiException && (error as ApiException).isAuthError;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isAuthError ? Icons.lock_clock_outlined : Icons.error_outline, color: Colors.grey.shade400, size: 40),
          const SizedBox(height: 12),
          Text(
            isAuthError ? 'Invalid or expired session' : '$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (isAuthError)
            ElevatedButton(
              onPressed: () => navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (r) => false, arguments: 'session_expired'),
              child: const Text('Please Login Again'),
            )
          else if (onRetry != null)
            OutlinedButton(onPressed: onRetry, style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary), child: const Text('Retry')),
        ],
      ),
    );
  }
}
