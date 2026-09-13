/// Địa chỉ dự án Supabase, truyền vào lúc build để khóa không nằm trong mã nguồn:
///
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
/// ```
///
/// Tiện hơn thì để trong `.env.json` rồi
/// `flutter run --dart-define-from-file=.env.json`.
///
/// Khóa này vốn được thiết kế để lộ ra ứng dụng — nó không cho quyền gì ngoài
/// những gì RLS cho phép. Dù vậy vẫn không nên commit, vì nó gắn với đúng một
/// dự án và đổi khóa thì phải build lại.
abstract final class CauHinh {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  // Supabase đang đổi tên "anon key" thành "publishable key", bảng điều khiển
  // của mỗi người một kiểu tùy thời điểm tạo dự án. Nhận cả hai tên để khỏi
  // phải nhớ mình đang ở phía nào của lần đổi tên đó.
  static const _khoaMoi = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _khoaCu = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseKey => _khoaMoi.isNotEmpty ? _khoaMoi : _khoaCu;

  /// Chưa khai báo đủ thì app chạy bằng dữ liệu mẫu.
  static bool get coSupabase => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
