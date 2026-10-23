/// App-wide constants mirrored from the native MarketSquare app.
class AppConstants {
  AppConstants._();

  /// Device-setup (login) endpoint. `{hostId}` is the user-entered host.
  /// Mirrors LoginRepository: https://$hostId.cswg.com/devicesetup/1.0
  static String deviceSetupUrl(String hostId) =>
      'https://$hostId.cswg.com/devicesetup/1.0';

  /// OAuth token request form params (client_credentials grant).
  static const String grantType = 'client_credentials';
  static const String tokenScope = 'read write';

  /// Service URL map key that holds the OAuth token endpoint.
  static const String serviceKeyAccessToken = 'ACCESS_TOKEN';

  /// FCM data-payload key naming the target screen for a notification tap.
  static const String pushKeyScreen = 'screen';

  /// Default brand primary color (MsRed) when the server sends none.
  static const int msRedArgb = 0xFFDB2031;

  /// App brand title shown in screen top bars (matches the live CSWG app).
  /// Flip to 'MS ORDERING' for the MarketSquare rebrand.
  static const String appTitle = 'CSWG ORDERING';
}
