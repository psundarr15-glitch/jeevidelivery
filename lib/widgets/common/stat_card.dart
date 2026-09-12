import 'package:flutter/material.dart';
import '../../theme.dart';

/// Small metric tile — icon, big number, label. Drop into any dashboard
/// or summary grid so stat tiles look identical across screens.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppTheme.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: AppTheme.shadowSoft(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.18), color.withOpacity(0.08)],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppTheme.textPrimary(context), letterSpacing: -0.4),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
