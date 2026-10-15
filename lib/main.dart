import 'package:flutter/material.dart';

import 'book.dart';
import 'bookstore_api.dart';

// Điểm bắt đầu của app Flutter.
void main() => runApp(const BookstoreApp());

class BookstoreApp extends StatefulWidget {
  const BookstoreApp({super.key});

  @override
  State<BookstoreApp> createState() => _BookstoreAppState();
}

class _BookstoreAppState extends State<BookstoreApp> {
  // Dùng chung một API client cho các màn hình.
  final api = BookstoreApi();
  // null nghĩa là chưa đăng nhập; API hiện chưa trả token để lưu phiên lâu dài.
  String? username;

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Tiệm sách',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF326A57)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F7F2),
    ),
    // Chuyển màn hình bằng trạng thái đăng nhập đang giữ trong bộ nhớ.
    home: username == null
        ? AuthPage(api: api, onLogin: (name) => setState(() => username = name))
        : BooksPage(api: api, onLogout: () => setState(() => username = null)),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.api, required this.onLogin});
  final BookstoreApi api;
  final ValueChanged<String> onLogin;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Form và controller giúp đọc/kiểm tra nội dung người dùng nhập.
  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  // Cùng một form dùng cho hai chế độ: đăng ký và đăng nhập.
  bool registerMode = false;
  bool loading = false;
  bool hidePassword = true;
  String? error;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Kiểm tra dữ liệu, gọi API tương ứng rồi cập nhật giao diện.
  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
      error = null;
    });
    final username = usernameController.text.trim();
    final password = passwordController.text;
    try {
      if (registerMode) {
        await widget.api.register(username, password);
        if (!mounted) return;
        // Đăng ký xong, quay về form đăng nhập và giữ sẵn username.
        passwordController.clear();
        setState(() => registerMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công. Hãy đăng nhập.')),
        );
      } else {
        final name = await widget.api.login(username, password);
        // Báo cho BookstoreApp để đổi từ màn hình đăng nhập sang danh sách sách.
        if (mounted) widget.onLogin(name);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'Có lỗi xảy ra. Hãy thử lại.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tiệm sách',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    registerMode
                        ? 'Tạo tài khoản mới'
                        : 'Đăng nhập để xem sách',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nhập tên đăng nhập'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    onFieldSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: hidePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                        onPressed: () =>
                            setState(() => hidePassword = !hidePassword),
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nhập mật khẩu';
                      }
                      if (registerMode && value.length < 8) {
                        return 'Mật khẩu cần ít nhất 8 ký tự';
                      }
                      return null;
                    },
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: loading ? null : submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(registerMode ? 'Đăng ký' : 'Đăng nhập'),
                    ),
                  ),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                            registerMode = !registerMode;
                            error = null;
                            passwordController.clear();
                          }),
                    child: Text(
                      registerMode
                          ? 'Đã có tài khoản? Đăng nhập'
                          : 'Chưa có tài khoản? Đăng ký',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class BooksPage extends StatefulWidget {
  const BooksPage({super.key, required this.api, required this.onLogout});
  final BookstoreApi api;
  final VoidCallback onLogout;

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  // Future giữ kết quả đang tải, đã tải hoặc lỗi để FutureBuilder hiển thị.
  late Future<List<Book>> books;

  @override
  void initState() {
    super.initState();
    books = widget.api.getBooks();
  }

  Future<void> refresh() async {
    // Thay Future cũ để FutureBuilder tải lại khi người dùng kéo xuống.
    final request = widget.api.getBooks();
    setState(() => books = request);
    try {
      await request;
    } catch (_) {
      // FutureBuilder sẽ hiển thị lỗi và nút Thử lại.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Danh sách sách'),
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Đăng xuất',
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    // Tùy trạng thái API: hiện vòng chờ, lỗi, danh sách rỗng hoặc danh sách sách.
    body: FutureBuilder<List<Book>>(
      future: books,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorPanel(
            message: snapshot.error.toString(),
            onRetry: refresh,
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Chưa có sách nào.'));
        }
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final book = items[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const CircleAvatar(child: Icon(Icons.auto_stories)),
                  title: Text(book.name, maxLines: 2),
                  subtitle: Text(
                    '${book.author.isEmpty ? 'Chưa rõ tác giả' : book.author}\n${formatPrice(book.price)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  // Bấm vào sách để mở trang chi tiết với book.id tương ứng.
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          BookDetailPage(api: widget.api, id: book.id),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class BookDetailPage extends StatefulWidget {
  const BookDetailPage({super.key, required this.api, required this.id});
  final BookstoreApi api;
  final int id;

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  late Future<Book> book;

  @override
  void initState() {
    super.initState();
    // Lấy chi tiết bằng id nhận từ trang danh sách.
    book = widget.api.getBook(widget.id);
  }

  void retry() => setState(() => book = widget.api.getBook(widget.id));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết sách')),
    body: FutureBuilder<Book>(
      future: book,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorPanel(message: snapshot.error.toString(), onRetry: retry);
        }
        final item = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.menu_book_rounded, size: 90),
            ),
            const SizedBox(height: 24),
            Text(item.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              formatPrice(item.price),
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 24),
            DetailRow(label: 'Tác giả', value: item.author),
            DetailRow(label: 'Nhà xuất bản', value: item.publisher),
            const SizedBox(height: 16),
            Text('Giới thiệu', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(item.summary.isEmpty ? 'Chưa có mô tả.' : item.summary),
          ],
        );
      },
    ),
  );
}

/// Dòng thông tin nhãn + giá trị dùng cho tác giả, nhà xuất bản.
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label)),
        Expanded(child: Text(value.isEmpty ? 'Chưa có' : value)),
      ],
    ),
  );
}

/// Giao diện báo lỗi chung cho danh sách và chi tiết sách.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}

/// Hiển thị giá dạng 120.000 đ cho dễ đọc trên giao diện.
String formatPrice(num price) {
  final digits = price.round().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  return '$grouped đ';
}
