import 'package:flutter/material.dart';
import '../../theme.dart';

/// Full-width dominant CTA. Wraps the app's ElevatedButton theme so call
/// sites don't repeat sizing, and adds a soft brand-colored "floating"
/// shadow underneath so the CTA reads as premium/lifted rather than a
/// flat filled rectangle.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color? color;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppTheme.primary;
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: onPressed == null ? null : AppTheme.shadowColored(buttonColor),
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
        child: loading
            ? const SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Lower-emphasis companion to [PrimaryButton] (e.g. "Cancel", "Not now").
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const SecondaryButton({super.key, required this.label, required this.onPressed, this.color = AppTheme.primary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Icon-over-label tile used in quick-action / shortcut rows.
class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.16), color.withOpacity(0.08)],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
          ],
        ),
      ),
    );
  }
}
