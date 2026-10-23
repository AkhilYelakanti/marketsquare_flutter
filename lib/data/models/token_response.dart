/// Mirrors Kotlin `TokenResponse` (OAuth client_credentials response).
class TokenResponse {
  final String accessToken;
  final int expiresIn;
  final String tokenType;

  const TokenResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: (json['access_token'] ?? '').toString(),
        expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
        tokenType: (json['token_type'] ?? '').toString(),
      );
}
