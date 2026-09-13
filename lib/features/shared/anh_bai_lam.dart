import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/app_state.dart';

/// Một tấm ảnh bài làm.
///
/// Đường dẫn lưu trong báo cáo có ba dạng, và widget này lo cả ba:
///
/// - `demo:...` — dữ liệu mẫu, vẽ ô giữ chỗ kẻ dòng.
/// - đường dẫn trên máy — ảnh vừa chụp, chưa kịp tải lên.
/// - đường dẫn trong kho — phải xin URL ký có hạn mới xem được, vì kho để
///   riêng tư. Đây là ảnh vở của trẻ con, không phát tán link công khai.
class AnhBaiLam extends StatefulWidget {
  const AnhBaiLam({
    super.key,
    required this.duongDan,
    this.canh = 132,
    this.onXoa,
  });

  final String duongDan;
  final double canh;
  final VoidCallback? onXoa;

  @override
  State<AnhBaiLam> createState() => _AnhBaiLamState();
}

class _AnhBaiLamState extends State<AnhBaiLam> {
  Future<String?>? _url;

  bool get _laDemo => widget.duongDan.startsWith('demo:');

  /// Ảnh vừa chọn trên web là một địa chỉ blob: của trình duyệt — xem thẳng,
  /// không phải xin link ký từ kho.
  bool get _laUrl =>
      widget.duongDan.startsWith('blob:') || widget.duongDan.startsWith('http');

  /// Ảnh vừa chụp còn nằm trên máy; ảnh đã lưu thì không.
  bool get _laTepCucBo {
    if (kIsWeb || _laDemo) return false;
    try {
      return File(widget.duongDan).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (_laUrl) {
      _url = Future.value(widget.duongDan);
    } else if (!_laDemo && !_laTepCucBo) {
      _url = context.read<AppState>().urlAnh(widget.duongDan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: widget.canh,
          height: widget.canh,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColor.sky,
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: AppColor.dongKe),
          ),
          child: _noiDung(),
        ),
        if (widget.onXoa != null)
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: widget.onXoa,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColor.ink.withValues(alpha: .82),
                  borderRadius: BorderRadius.circular(R.sm),
                ),
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _noiDung() {
    if (_laDemo) {
      return CustomPaint(
        painter: _GiayNhap(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_rounded, size: 22, color: AppColor.muc.withValues(alpha: .45)),
              const SizedBox(height: 6),
              Text('Ảnh bài làm',
                  style: AppType.ui(11, color: AppColor.mucNhat, w: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    if (_laTepCucBo) {
      return Image.file(
        File(widget.duongDan),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const AnhHong(),
      );
    }

    return FutureBuilder<String?>(
      future: _url,
      builder: (_, kq) {
        if (kq.connectionState != ConnectionState.done) return const _DangTai();
        final url = kq.data;
        if (url == null) return const AnhHong();
        return Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, con, tien) => tien == null ? con : const _DangTai(),
          errorBuilder: (_, _, _) => const AnhHong(),
        );
      },
    );
  }
}

class _DangTai extends StatelessWidget {
  const _DangTai();

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.mucNhat),
        ),
      );
}

/// Ảnh không tải được — nói thẳng là mất ảnh, đừng để một ô xám vô nghĩa.
class AnhHong extends StatelessWidget {
  const AnhHong({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, size: 20, color: AppColor.mucNhat),
          const SizedBox(height: 5),
          Text('Không tải được ảnh',
              style: AppType.ui(10.5, color: AppColor.mucNhat, w: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _GiayNhap extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColor.dongKeDam.withValues(alpha: .5)
      ..strokeWidth = 1;
    for (var y = 14.0; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_GiayNhap old) => false;
}
