import 'dart:convert';

import 'package:bookstore_mobile/bookstore_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('register and login use the provided API contract', () async {
    final requests = <http.Request>[];
    final api = BookstoreApi(
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/users') {
          return http.Response('{"username":"lan","status":true}', 200);
        }
        return http.Response(
          '{"success":true,"username":"lan","message":"OK"}',
          200,
        );
      }),
    );

    await api.register('lan', 'password123');
    expect(await api.login('lan', 'password123'), 'lan');
    expect(requests.map((request) => request.url.path), [
      '/api/users',
      '/api/auth/login',
    ]);
    expect(jsonDecode(requests.first.body)['password'], 'password123');
    api.dispose();
  });

  test('book list and detail map fields from the backend', () async {
    const bookJson =
        '{"bookid":7,"bookname":"Sách A","price":120000,'
        '"author":"Tác giả","publisher":"NXB","summary":"Mô tả"}';
    final api = BookstoreApi(
      client: MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            request.url.path == '/api/books' ? '[$bookJson]' : bookJson,
          ),
          200,
        );
      }),
    );

    final books = await api.getBooks();
    final detail = await api.getBook(7);
    expect(books.single.id, 7);
    expect(detail.name, 'Sách A');
    expect(detail.price, 120000);
    api.dispose();
  });
}
