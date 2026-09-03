import 'package:flutter/material.dart';
import '../models/partner.dart';
import '../services/delivery_service.dart';

class AppState extends ChangeNotifier {
  Partner? partner;

  Future<void> loadPartner() async {
    partner = await DeliveryService.me();
    notifyListeners();
  }

  Future<void> toggleAvailability() async {
    final current = partner;
    if (current == null) return;
    // Optimistic flip, corrected below if the request actually fails.
    partner = current.copyWith(isAvailable: !current.isAvailable);
    notifyListeners();
    try {
      final isAvailable = await DeliveryService.toggleAvailability();
      partner = partner!.copyWith(isAvailable: isAvailable);
    } catch (e) {
      partner = current;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  void clear() {
    partner = null;
    notifyListeners();
  }
}
