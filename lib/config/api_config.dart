/// Backend API base URL — same CodeIgniter backend the customer app and
/// admin/vendor panels talk to, just the `delivery/*` surface of it.
class ApiConfig {
  static const String baseUrl = 'https://food.tvkomalur.xyz/api';

  static const String register = '$baseUrl/delivery/register';
  static const String login = '$baseUrl/delivery/login';
  static const String logout = '$baseUrl/delivery/logout';

  static const String me = '$baseUrl/delivery/me';
  static const String deviceToken = '$baseUrl/delivery/device-token';
  static const String toggleAvailability = '$baseUrl/delivery/toggle-availability';
  static const String dashboard = '$baseUrl/delivery/dashboard';
  static String orderDetails(int orderId) => '$baseUrl/delivery/orders/$orderId';
  static String acceptOrder(int orderId) => '$baseUrl/delivery/orders/$orderId/accept';
  static String rejectOrder(int orderId) => '$baseUrl/delivery/orders/$orderId/reject';
  static String updateStatus(int orderId) => '$baseUrl/delivery/orders/$orderId/update-status';
  static const String updateLocation = '$baseUrl/delivery/update-location';
}
