import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'delivery_service.dart';

/// Pushes this device's location to the backend every 15s so the
/// customer's live order-tracking map has something to show. Foreground
/// only — there's no background-service/platform-channel setup in this
/// v1, so tracking pauses if the app is backgrounded or killed. Good
/// enough to ship with; a background isolate is a follow-up.
class LocationTracker {
  LocationTracker._();
  static final instance = LocationTracker._();

  Timer? _timer;

  bool get isTracking => _timer != null;

  Future<void> start() async {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
    _tick();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await DeliveryService.updateLocation(pos.latitude, pos.longitude);
    } catch (_) {
      // Best-effort — a missed location ping isn't worth surfacing an error for.
    }
  }
}
