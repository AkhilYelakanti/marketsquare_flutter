/// Mirrors Kotlin `DeviceSetupResponse`. Field names use the Kotlin
/// @SerialName values where they differ from the property name.
class DeviceSetupResponse {
  final String status;
  final String? errorMessage;

  /// @SerialName("urlsMap")
  final Map<String, String>? serviceUrlMap;

  /// @SerialName("brandLogoLink")
  final String? brandLogoUrl;

  /// @SerialName("brandBackgroundTheme")
  final String? brandBackgroundColor;

  final String? brandSplashBackgroundColor;
  final String? brandViewBarBackgroundColor;
  final String? storeId;
  final String? serviceId;
  final String? buId;
  final String? brandNewItemBackgroundcolor;

  const DeviceSetupResponse({
    this.status = '',
    this.errorMessage,
    this.serviceUrlMap,
    this.brandLogoUrl,
    this.brandBackgroundColor,
    this.brandSplashBackgroundColor,
    this.brandViewBarBackgroundColor,
    this.storeId,
    this.serviceId,
    this.buId,
    this.brandNewItemBackgroundcolor,
  });

  factory DeviceSetupResponse.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['urlsMap'];
    Map<String, String>? urls;
    if (rawUrls is Map) {
      urls = rawUrls.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    return DeviceSetupResponse(
      status: (json['status'] ?? '').toString(),
      errorMessage: json['errorMessage'] as String?,
      serviceUrlMap: urls,
      brandLogoUrl: json['brandLogoLink'] as String?,
      brandBackgroundColor: json['brandBackgroundTheme'] as String?,
      brandSplashBackgroundColor: json['brandSplashBackgroundColor'] as String?,
      brandViewBarBackgroundColor: json['brandViewBarBackgroundColor'] as String?,
      storeId: json['storeId'] as String?,
      serviceId: json['serviceId'] as String?,
      buId: json['buId'] as String?,
      brandNewItemBackgroundcolor: json['brandNewItemBackgroundcolor'] as String?,
    );
  }
}
