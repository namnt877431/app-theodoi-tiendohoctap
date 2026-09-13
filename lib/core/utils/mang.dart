import 'dart:async';
import 'dart:io';

/// Lỗi này có phải "không có mạng" không — khác với bị máy chủ từ chối.
///
/// Không có mạng thì bài viết ra được cất lại chờ gửi; bị từ chối (hết phiên,
/// vi phạm luật) thì phải báo ngay, cất đi cũng không tự lành. Supabase gói
/// lỗi mạng theo nhiều kiểu tùy tầng (Auth, PostgREST, Storage), nên dò cả
/// theo kiểu lẫn theo chữ trong thông báo.
bool laLoiMang(Object e) {
  if (e is SocketException || e is TimeoutException || e is HandshakeException) {
    return true;
  }
  final m = e.toString().toLowerCase();
  return m.contains('socketexception') ||
      m.contains('clientexception') ||
      m.contains('failed host lookup') ||
      m.contains('connection refused') ||
      m.contains('connection reset') ||
      m.contains('connection closed') ||
      m.contains('network is unreachable') ||
      m.contains('software caused connection abort') ||
      m.contains('không có mạng');
}
