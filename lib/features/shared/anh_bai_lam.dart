import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/app_state.dart';

/// Một tấm ảnh bài làm, dạng ô vuông nhỏ. Chạm vào là mở xem cả màn hình
/// ([moXemAnh]) khi có [onTap].
///
/// Đường dẫn lưu trong báo cáo có ba dạng, và [_NoiDungAnh] lo cả ba:
///
/// - `demo:...` — dữ liệu mẫu, vẽ ô giữ chỗ kẻ dòng.
/// - đường dẫn trên máy — ảnh vừa chụp, chưa kịp tải lên.
/// - đường dẫn trong kho — phải xin URL ký có hạn mới xem được, vì kho để
///   riêng tư. Đây là ảnh vở của trẻ con, không phát tán link công khai.
class AnhBaiLam extends StatelessWidget {
  const AnhBaiLam({
    super.key,
    required this.duongDan,
    this.canh = 132,
    this.onXoa,
    this.onTap,
  });

  final String duongDan;
  final double canh;
  final VoidCallback? onXoa;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: AppColor.sky,
          borderRadius: BorderRadius.circular(R.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              width: canh,
              height: canh,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(R.md),
                border: Border.all(color: AppColor.dongKe),
              ),
              child: _NoiDungAnh(duongDan: duongDan, fit: BoxFit.cover),
            ),
          ),
        ),
        if (onXoa != null)
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: onXoa,
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
}

/// Phần ruột của một tấm ảnh: tự nhận ra đường dẫn thuộc dạng nào, xin link
/// nếu cần, rồi vẽ. Dùng chung cho ô nhỏ lẫn màn xem lớn.
class _NoiDungAnh extends StatefulWidget {
  const _NoiDungAnh({required this.duongDan, required this.fit, this.lon = false});

  final String duongDan;
  final BoxFit fit;

  /// Đang vẽ trên màn xem lớn: ô giữ chỗ và ô mất ảnh to hơn, chữ sáng.
  final bool lon;

  @override
  State<_NoiDungAnh> createState() => _NoiDungAnhState();
}

class _NoiDungAnhState extends State<_NoiDungAnh> {
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
    if (_laDemo) return _GiuCho(lon: widget.lon);

    if (_laTepCucBo) {
      return Image.file(
        File(widget.duongDan),
        fit: widget.fit,
        errorBuilder: (_, _, _) => AnhHong(lon: widget.lon),
      );
    }

    return FutureBuilder<String?>(
      future: _url,
      builder: (_, kq) {
        if (kq.connectionState != ConnectionState.done) return const _DangTai();
        final url = kq.data;
        if (url == null) return AnhHong(lon: widget.lon);
        return Image.network(
          url,
          fit: widget.fit,
          loadingBuilder: (_, con, tien) => tien == null ? con : const _DangTai(),
          errorBuilder: (_, _, _) => AnhHong(lon: widget.lon),
        );
      },
    );
  }
}

// ----------------------------------------------------------------- xem lớn

/// Mở ảnh cả màn hình: vuốt ngang qua từng tấm, hai ngón phóng to để đọc
/// chữ trong vở, nút đóng hoặc phím lùi để về.
Future<void> moXemAnh(BuildContext context, {required List<String> duongDan, int batDau = 0}) {
  if (duongDan.isEmpty) return Future.value();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _XemAnh(duongDan: duongDan, batDau: batDau.clamp(0, duongDan.length - 1)),
    ),
  );
}

class _XemAnh extends StatefulWidget {
  const _XemAnh({required this.duongDan, required this.batDau});
  final List<String> duongDan;
  final int batDau;

  @override
  State<_XemAnh> createState() => _XemAnhState();
}

class _XemAnhState extends State<_XemAnh> {
  late final _trang = PageController(initialPage: widget.batDau);
  late int _hienTai = widget.batDau;

  /// Đang phóng to một tấm: khóa lật trang, để kéo là dời ảnh chứ không
  /// nhảy sang tấm khác.
  bool _dangPhongTo = false;

  @override
  void dispose() {
    _trang.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nhieu = widget.duongDan.length > 1;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _trang,
            physics: _dangPhongTo
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: widget.duongDan.length,
            onPageChanged: (i) => setState(() => _hienTai = i),
            itemBuilder: (_, i) => _TrangAnh(
              duongDan: widget.duongDan[i],
              onPhongTo: (co) {
                if (co != _dangPhongTo) setState(() => _dangPhongTo = co);
              },
            ),
          ),
          // Thanh trên: đóng bên trái, đếm bên phải. Nền mờ để đọc được trên
          // ảnh sáng.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.xs),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: .45),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const Spacer(),
                    if (nhieu)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(R.pill),
                        ),
                        child: Text(
                          '${_hienTai + 1}/${widget.duongDan.length}',
                          style: AppType.numeric(13, w: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (nhieu)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Gap.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.duongDan.length; i++)
                        Container(
                          width: i == _hienTai ? 18 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: i == _hienTai ? .95 : .45),
                            borderRadius: BorderRadius.circular(R.pill),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Một tấm trên màn xem lớn. Chưa phóng to thì không bắt cử chỉ kéo — kéo
/// ngang là việc của PageView để lật trang; phóng to rồi mới kéo được ảnh.
/// Chạm đôi để phóng vào chỗ vừa chạm, chạm đôi nữa để về.
class _TrangAnh extends StatefulWidget {
  const _TrangAnh({required this.duongDan, required this.onPhongTo});
  final String duongDan;
  final ValueChanged<bool> onPhongTo;

  @override
  State<_TrangAnh> createState() => _TrangAnhState();
}

class _TrangAnhState extends State<_TrangAnh> {
  final _bienDoi = TransformationController();
  bool _phongTo = false;
  Offset? _chamDoi;

  @override
  void initState() {
    super.initState();
    _bienDoi.addListener(_doiTiLe);
  }

  @override
  void dispose() {
    _bienDoi.removeListener(_doiTiLe);
    _bienDoi.dispose();
    super.dispose();
  }

  void _doiTiLe() {
    final co = _bienDoi.value.getMaxScaleOnAxis() > 1.01;
    if (co != _phongTo) {
      setState(() => _phongTo = co);
      widget.onPhongTo(co);
    }
  }

  void _chamDoiXong() {
    if (_phongTo) {
      _bienDoi.value = Matrix4.identity();
      return;
    }
    final tam = _chamDoi;
    if (tam == null) return;
    const ti = 2.5;
    // Phóng quanh điểm chạm: dời sao cho điểm đó đứng yên.
    _bienDoi.value = Matrix4.identity()
      ..translateByDouble(-tam.dx * (ti - 1), -tam.dy * (ti - 1), 0, 1)
      ..scaleByDouble(ti, ti, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _chamDoi = d.localPosition,
      onDoubleTap: _chamDoiXong,
      child: InteractiveViewer(
        transformationController: _bienDoi,
        panEnabled: _phongTo,
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: _NoiDungAnh(duongDan: widget.duongDan, fit: BoxFit.contain, lon: true),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ phụ

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

/// Ô giữ chỗ cho ảnh mẫu: giấy kẻ dòng.
class _GiuCho extends StatelessWidget {
  const _GiuCho({required this.lon});
  final bool lon;

  @override
  Widget build(BuildContext context) {
    final o = CustomPaint(
      painter: _GiayNhap(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_rounded, size: lon ? 40 : 22, color: AppColor.muc.withValues(alpha: .45)),
            const SizedBox(height: 6),
            Text('Ảnh bài làm',
                style: AppType.ui(lon ? 14 : 11, color: AppColor.mucNhat, w: FontWeight.w600)),
          ],
        ),
      ),
    );
    if (!lon) return o;
    return Container(
      width: 280,
      height: 280,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColor.sky,
        borderRadius: BorderRadius.circular(R.md),
      ),
      child: o,
    );
  }
}

/// Ảnh không tải được — nói thẳng là mất ảnh, đừng để một ô xám vô nghĩa.
class AnhHong extends StatelessWidget {
  const AnhHong({super.key, this.lon = false});
  final bool lon;

  @override
  Widget build(BuildContext context) {
    final mau = lon ? Colors.white70 : AppColor.mucNhat;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: lon ? 40 : 20, color: mau),
          const SizedBox(height: 5),
          Text('Không tải được ảnh',
              style: AppType.ui(lon ? 14 : 10.5, color: mau, w: FontWeight.w500)),
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
