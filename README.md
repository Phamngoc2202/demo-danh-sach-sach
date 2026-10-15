# Demo: Danh sách sách

App Flutter Android bản đầu gồm đăng ký, đăng nhập, danh sách sách và chi tiết sách. API Java do lớp cung cấp được chạy riêng ở thư mục `demo` của dự án gốc; repository này chỉ chứa app mobile.

## Đọc code từ đâu?

1. `lib/main.dart`: bắt đầu tại `main()` rồi xem `BookstoreApp`. Khi chưa đăng nhập, app hiện `AuthPage`; đăng nhập thành công sẽ hiện `BooksPage`.
2. `lib/bookstore_api.dart`: xem các hàm `register()`, `login()`, `getBooks()` và `getBook()`. Đây là nơi app gửi HTTP đến backend. Hàm `_request()` xử lý thời gian chờ, JSON và thông báo lỗi chung.
3. `lib/book.dart`: `Book.fromJson()` chuyển một đối tượng JSON từ API thành đối tượng `Book` để giao diện dùng dễ hơn.
4. Quay lại `lib/main.dart`: `BooksPage` gọi `getBooks()` và hiển thị bằng `FutureBuilder`; khi bấm một sách, `BookDetailPage` gọi `getBook(id)`.

### Các khái niệm cần nhớ

- `async`/`await`: đợi API trả kết quả mà không làm đứng giao diện.
- `Future<T>`: kết quả sẽ có sau, ví dụ `Future<List<Book>>` là danh sách sách đang tải.
- `setState()`: báo Flutter vẽ lại màn hình khi dữ liệu thay đổi.
- `FutureBuilder`: tự hiện trạng thái đang tải, lỗi hoặc dữ liệu đã nhận.
- `Navigator.push()`: mở trang chi tiết; nút quay lại của Android sẽ về danh sách.
- `mounted`: kiểm tra màn hình còn tồn tại trước khi cập nhật giao diện sau lời gọi API.

Luồng đầy đủ: nhập tài khoản → `AuthPage.submit()` → `BookstoreApi.login()` → API Java `/api/auth/login` → `BookstoreApp` đổi sang `BooksPage` → `getBooks()` → bấm sách → `getBook(id)`.

## Chạy

1. Mở terminal tại `demo` và chạy API: `./mvnw.cmd spring-boot:run`.
2. Mở Android emulator, vào thư mục `bookstore_mobile`, chạy `flutter run`.

App dùng `http://10.0.2.2:8080` để emulator truy cập API trên máy tính.

## Điện thoại Android cắm USB

Sau khi bật USB debugging và thấy điện thoại trong `flutter devices`, chạy app:

```powershell
flutter run -d DEVICE_ID --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Sau khi app được cài và mở, chạy lệnh chuyển tiếp cổng trong một terminal khác:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s DEVICE_ID reverse tcp:8080 tcp:8080
```

Nếu rút cáp, cắm lại hoặc Flutter ngắt kết nối, chạy lại lệnh chuyển tiếp cổng rồi bấm thử lại trong app.

Nếu dùng điện thoại qua Wi-Fi thay vì USB, máy tính và điện thoại cần cùng mạng; chạy:

```powershell
flutter run --dart-define=API_BASE_URL=http://IP_MAY_TINH:8080
```

Không dùng `localhost` trên emulator hoặc điện thoại vì địa chỉ đó trỏ về chính thiết bị.
API đăng nhập hiện chỉ trả username; app giữ trạng thái đăng nhập trong bộ nhớ và sẽ yêu cầu đăng nhập lại khi mở app.
