import 'dart:convert';

import 'package:http/http.dart' as http;

import 'book.dart';

/// Lỗi hiển thị được cho người dùng khi API hoặc mạng gặp sự cố.
class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Gom tất cả lời gọi HTTP vào một chỗ để màn hình chỉ cần gọi hàm tương ứng.
class BookstoreApi {
  BookstoreApi({http.Client? client}) : _client = client ?? http.Client();

  /// Android emulator dùng 10.0.2.2; điện thoại USB dùng 127.0.0.1 kèm adb reverse.
  /// --dart-define=API_BASE_URL=... cho phép đổi địa chỉ khi chạy app.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Gửi yêu cầu, chờ tối đa 10 giây, đọc JSON và đổi lỗi thành thông báo dễ hiểu.
  Future<dynamic> _request(Future<http.Response> Function() send) async {
    late http.Response response;
    try {
      response = await send().timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const ApiException(
        'Không kết nối được API. Hãy kiểm tra server và địa chỉ API.',
      );
    }

    // bodyBytes + UTF-8 giúp tên sách và thông báo tiếng Việt không bị lỗi dấu.
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const ApiException('API trả về dữ liệu không hợp lệ.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (body is Map<String, dynamic> && body['message'] is String) {
        throw ApiException(body['message'] as String);
      }
      throw ApiException('Yêu cầu thất bại (HTTP ${response.statusCode}).');
    }
    return body;
  }

  /// POST /api/users: backend tạo tài khoản mới.
  Future<void> register(String username, String password) async {
    await _request(
      () => _client.post(
        _uri('/api/users'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username, 'password': password}),
      ),
    );
  }

  /// POST /api/auth/login: chỉ nhận username khi đăng nhập thành công.
  Future<String> login(String username, String password) async {
    final body = await _request(
      () => _client.post(
        _uri('/api/auth/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username, 'password': password}),
      ),
    );
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw ApiException(
        body is Map<String, dynamic>
            ? (body['message']?.toString() ?? 'Đăng nhập thất bại.')
            : 'Đăng nhập thất bại.',
      );
    }
    return body['username']?.toString() ?? username;
  }

  /// GET /api/books: tải toàn bộ sách rồi chuyển từng JSON thành Book.
  Future<List<Book>> getBooks() async {
    final body = await _request(() => _client.get(_uri('/api/books')));
    if (body is! List) {
      throw const ApiException('Danh sách sách không hợp lệ.');
    }
    return body
        .map((item) => Book.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/books/{id}: tải lại thông tin của một cuốn sách.
  Future<Book> getBook(int id) async {
    final body = await _request(() => _client.get(_uri('/api/books/$id')));
    if (body is! Map<String, dynamic>) {
      throw const ApiException('Thông tin sách không hợp lệ.');
    }
    return Book.fromJson(body);
  }

  void dispose() => _client.close();
}
