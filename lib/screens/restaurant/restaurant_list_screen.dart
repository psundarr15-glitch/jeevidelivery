import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../../models/restaurant.dart';
import '../../widgets/restaurant_list_tile.dart';
import 'restaurant_menu_screen.dart';
import '../../l10n/app_localizations.dart';

class RestaurantListScreen extends StatefulWidget {
  final String? initialQuery;
  const RestaurantListScreen({super.key, this.initialQuery});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  List<Restaurant> _restaurants = [];
  bool _loading = true;
  String? _error;
  Timer? _debounce;
  late final _searchController = TextEditingController(text: widget.initialQuery ?? '');

  @override
  void initState() {
    super.initState();
    _load(widget.initialQuery);
  }

  Future<void> _load([String? query]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await CustomerService.restaurants(query: query);
      setState(() {
        _restaurants = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(value));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.restaurantsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: t.searchRestaurants,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(t.errorLabel(_error!)))
                    : _restaurants.isEmpty
                        ? Center(child: Text(t.noRestaurantsFound))
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.66,
                            ),
                            itemCount: _restaurants.length,
                            itemBuilder: (context, i) {
                              final r = _restaurants[i];
                              return RestaurantListTile(
                                restaurant: r,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => RestaurantMenuScreen(restaurantId: r.id)),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
