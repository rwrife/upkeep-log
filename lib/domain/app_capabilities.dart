/// Product capabilities that are intentionally fixed for the MVP.
final class AppCapabilities {
  const AppCapabilities._();

  /// The MVP keeps all user data on the device unless the user exports it.
  static const bool storesDataLocally = true;

  /// Core use never requires an account.
  static const bool requiresAccount = false;

  /// Core use never requires a network connection.
  static const bool requiresNetwork = false;

  /// The app does not include analytics or advertising SDKs.
  static const bool includesTracking = false;
}
