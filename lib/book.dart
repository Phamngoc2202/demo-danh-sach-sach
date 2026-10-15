/// Một cuốn sách sau khi chuyển dữ liệu JSON từ API thành đối tượng Dart.
class Book {
  const Book({
    required this.id,
    required this.name,
    required this.price,
    required this.author,
    required this.publisher,
    required this.summary,
  });

  final int id;
  final String name;
  final num price;
  final String author;
  final String publisher;
  final String summary;

  /// Tên khóa như bookid, bookname phải khớp với dữ liệu backend trả về.
  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: (json['bookid'] as num).toInt(),
    name: json['bookname']?.toString() ?? '',
    price: (json['price'] as num?) ?? 0,
    author: json['author']?.toString() ?? '',
    publisher: json['publisher']?.toString() ?? '',
    summary: json['summary']?.toString() ?? '',
  );
}
