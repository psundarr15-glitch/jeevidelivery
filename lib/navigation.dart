import 'package:flutter/material.dart';

/// Lets non-widget code (ApiClient) trigger navigation — e.g. bouncing
/// to the login screen the moment the backend says the session token
/// is invalid/expired, without every screen having to check for that
/// itself.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
