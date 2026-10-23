/// Mirrors Kotlin `DeviceSetupRequest` (kotlinx.serialization @Serializable).
class DeviceSetupRequest {
  final String deviceId;
  final String accessId;
  final String accessPin;
  final String versionId;
  final String appOS;
  final String appOSVersion;
  final String fcmToken;
  final String manufacturer;
  final String model;
  final String brand;

  const DeviceSetupRequest({
    required this.deviceId,
    required this.accessId,
    required this.accessPin,
    required this.versionId,
    required this.appOS,
    required this.appOSVersion,
    required this.fcmToken,
    required this.manufacturer,
    required this.model,
    required this.brand,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'accessId': accessId,
        'accessPin': accessPin,
        'versionId': versionId,
        'appOS': appOS,
        'appOSVersion': appOSVersion,
        'fcmToken': fcmToken,
        'manufacturer': manufacturer,
        'model': model,
        'brand': brand,
      };
}
