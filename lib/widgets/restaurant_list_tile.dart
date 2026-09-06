import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/customer_service.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';

/// Big grid-style restaurant card — dark photo on top (with a like/heart
/// toggle), name + rating/time + cuisine in a white body below, both
/// halves forming one rounded card.
class RestaurantListTile extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const RestaurantListTile({super.key, required this.restaurant, required this.onTap});

  @override
  State<RestaurantListTile> createState() => _RestaurantListTileState();
}

class _RestaurantListTileState extends State<RestaurantListTile> {
  late bool _liked = widget.restaurant.likedByMe;
  bool _togglingLike = false;

  Future<void> _toggleLike() async {
    if (_togglingLike) return;
    setState(() {
      _togglingLike = true;
      _liked = !_liked; // optimistic
    });
    try {
      final (liked, _) = await CustomerService.toggleLike(widget.restaurant.id);
      if (mounted) setState(() => _liked = liked);
    } catch (_) {
      if (mounted) setState(() => _liked = !_liked); // revert on failure
    } finally {
      if (mounted) setState(() => _togglingLike = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    const fallbackImage = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=300&fit=crop';

    return Opacity(
      opacity: restaurant.isOpen ? 1 : 0.6,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppTheme.surface(context),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.network(
                    restaurant.image?.isNotEmpty == true ? restaurant.image! : fallbackImage,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.network(fallbackImage, height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _toggleLike,
                      child: Icon(
                        _liked ? Icons.favorite : Icons.favorite_border,
                        color: _liked ? AppTheme.primary : Colors.white,
                        size: 26,
                        shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                      ),
                    ),
                  ),
                  if (!restaurant.isOpen)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                        child: Text(AppLocalizations.of(context)!.closedLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (restaurant.discountLabel != null)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                        child: Text(restaurant.discountLabel!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: AppTheme.textPrimary(context)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppTheme.gold, size: 18),
                        const SizedBox(width: 4),
                        Text(restaurant.rating.toStringAsFixed(1), style: TextStyle(fontSize: 15, color: AppTheme.textPrimary(context))),
                        Text('  |  ', style: TextStyle(color: AppTheme.textSecondary(context))),
                        Text(
                          AppLocalizations.of(context)!.prepTimeRange(restaurant.prepTimeMin.toString(), restaurant.prepTimeMax.toString()),
                          style: TextStyle(fontSize: 15, color: AppTheme.textPrimary(context)),
                        ),
                      ],
                    ),
                    if ((restaurant.cuisine ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        restaurant.cuisine!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
