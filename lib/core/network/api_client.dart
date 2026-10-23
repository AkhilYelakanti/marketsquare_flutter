import 'package:dio/dio.dart';

/// Thin Dio wrapper replacing the Ktor HttpClient.
///
/// - JSON content negotiation + lenient decoding (ignore unknown keys is the
///   default with manual `fromJson`).
/// - Follows redirects; like Ktor's HttpRedirect, a 301/302 on a POST is
///   downgraded to GET by most servers — Dio follows automatically.
class ApiClient {
  final Dio dio;

  ApiClient({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              followRedirects: true,
              maxRedirects: 5,
              // Never throw on non-2xx; callers inspect statusCode like Ktor.
              validateStatus: (_) => true,
            ));

  /// POST a JSON body, optionally with extra headers (e.g. auth tokens).
  Future<Response<dynamic>> postJson(
    String url,
    Map<String, dynamic> body, {
    Map<String, String> headers = const {},
  }) {
    return dio.post(
      url,
      data: body,
      options: Options(
        contentType: Headers.jsonContentType,
        responseType: ResponseType.plain,
        headers: headers,
      ),
    );
  }

  /// POST a url-encoded form with extra headers (OAuth token request).
  Future<Response<dynamic>> postForm(
    String url,
    Map<String, String> form, {
    Map<String, String> headers = const {},
  }) {
    return dio.post(
      url,
      data: form,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        headers: headers,
      ),
    );
  }
}
