import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'constants.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiClient {
  String? token;
  void Function()? onUnauthorized;
  final _base = AppConfig.apiUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, String>? q]) => Uri.parse('$_base$path').replace(queryParameters: q);

  Future<dynamic> get(String path, {Map<String, String>? query}) => _send(() => http.get(_uri(path, query), headers: _headers));
  Future<dynamic> post(String path, [Object? body]) =>
      _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));
  Future<dynamic> put(String path, Object body) => _send(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body)));
  Future<dynamic> patch(String path, Object body) =>
      _send(() => http.patch(_uri(path), headers: _headers, body: jsonEncode(body)));
  Future<dynamic> delete(String path) => _send(() => http.delete(_uri(path), headers: _headers));

  Future<dynamic> upload(String path, List<int> bytes, String filename, {Map<String, String>? fields}) async {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : 'jpeg';
    final req = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'})
      ..fields.addAll(fields ?? {})
      ..files.add(http.MultipartFile.fromBytes('image', bytes,
          filename: filename, contentType: MediaType('image', ext == 'jpg' ? 'jpeg' : ext)));
    return _send(() async => http.Response.fromStream(await req.send()));
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    http.Response r;
    try {
      r = await call().timeout(const Duration(seconds: 30));
    } catch (_) {
      throw ApiException('Sem ligação ao servidor. Verifique a internet e tente de novo.');
    }
    if (r.statusCode == 401 && token != null) onUnauthorized?.call();
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    }
    var msg = 'Erro inesperado (${r.statusCode})';
    try {
      msg = (jsonDecode(utf8.decode(r.bodyBytes)) as Map)['error']?.toString() ?? msg;
    } catch (_) {}
    throw ApiException(msg, r.statusCode);
  }
}
