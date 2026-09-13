import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/anh/tai_anh.dart';
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

/// Mở ảnh cả màn hình: vuốt ngang qua từng tấm, hai ngón hay nút +/− để
/// phóng to đọc chữ trong vở, xoay khi ảnh nằm nghiêng, tải về máy. Nút đóng
/// hoặc phím lùi để về.
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
  static const _tiLeToiDa = 5.0;

  late final _trang = PageController(initialPage: widget.batDau);
  late int _hienTai = widget.batDau;

  /// Mỗi tấm giữ phép biến đổi và số lần xoay riêng — lật sang tấm khác rồi
  /// quay lại vẫn thấy đúng chỗ đang xem.
  final _bienDoi = <int, TransformationController>{};
  final _xoay = <int, int>{};

  /// Đang phóng to một tấm: khóa lật trang, để kéo là dời ảnh chứ không
  /// nhảy sang tấm khác.
  bool _dangPhongTo = false;
  bool _dangTai = false;

  TransformationController _bienDoiCua(int i) =>
      _bienDoi.putIfAbsent(i, TransformationController.new);

  @override
  void dispose() {
    _trang.dispose();
    for (final c in _bienDoi.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _tiLe => _bienDoiCua(_hienTai).value.getMaxScaleOnAxis();

  /// Phóng quanh tâm màn hình theo hệ số [k]; về 1 thì đặt lại cho sạch.
  void _phong(double k) {
    final c = _bienDoiCua(_hienTai);
    final cu = c.value.getMaxScaleOnAxis();
    final moi = (cu * k).clamp(1.0, _tiLeToiDa);
    if (moi <= 1.001) {
      c.value = Matrix4.identity();
      return;
    }
    final kThat = moi / cu;
    final kt = MediaQuery.sizeOf(context);
    final tam = Offset(kt.width / 2, kt.height / 2);
    c.value = (Matrix4.identity()
          ..translateByDouble(tam.dx, tam.dy, 0, 1)
          ..scaleByDouble(kThat, kThat, 1, 1)
          ..translateByDouble(-tam.dx, -tam.dy, 0, 1))
        .multiplied(c.value);
  }

  void _xoayTam() => setState(() => _xoay[_hienTai] = ((_xoay[_hienTai] ?? 0) + 1) % 4);

  Future<void> _tai() async {
    if (_dangTai) return;
    final s = context.read<AppState>();
    final tb = ScaffoldMessenger.of(context);
    final dd = widget.duongDan[_hienTai];
    setState(() => _dangTai = true);
    String ketQua;
    try {
      if (dd.startsWith('demo:')) {
        ketQua = 'Đây là ảnh mẫu, không có gì để tải.';
      } else if (dd.startsWith('http') || dd.startsWith('blob:')) {
        ketQua = await taiAnhVeMay(url: dd);
      } else if (!kIsWeb && File(dd).existsSync()) {
        ketQua = await taiAnhVeMay(duongDan: dd);
      } else {
        final url = await s.urlAnh(dd);
        ketQua = url == null ? 'Không lấy được ảnh từ kho.' : await taiAnhVeMay(url: url);
      }
    } catch (e) {
      ketQua = 'Không tải được ảnh: $e';
    }
    if (mounted) setState(() => _dangTai = false);
    tb.showSnackBar(SnackBar(content: Text(ketQua)));
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
            onPageChanged: (i) => setState(() {
              _hienTai = i;
              _dangPhongTo = _bienDoiCua(i).value.getMaxScaleOnAxis() > 1.01;
            }),
            itemBuilder: (_, i) => _TrangAnh(
              duongDan: widget.duongDan[i],
              bienDoi: _bienDoiCua(i),
              xoay: _xoay[i] ?? 0,
              tiLeToiDa: _tiLeToiDa,
              onPhongTo: (co) {
                if (i == _hienTai && co != _dangPhongTo) setState(() => _dangPhongTo = co);
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
                    _NutToi(icon: Icons.close_rounded, tooltip: 'Đóng', onTap: () => Navigator.of(context).pop()),
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
          // Thanh dưới: chấm trang, rồi bốn nút — thu nhỏ, phóng to, xoay, tải.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (nhieu)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.md),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _NutToi(
                          icon: Icons.zoom_out_rounded,
                          tooltip: 'Thu nhỏ',
                          onTap: _tiLe > 1.001 ? () => _phong(1 / 1.6) : null,
                        ),
                        const SizedBox(width: Gap.sm),
                        _NutToi(
                          icon: Icons.zoom_in_rounded,
                          tooltip: 'Phóng to',
                          onTap: _tiLe < _tiLeToiDa - .001 ? () => _phong(1.6) : null,
                        ),
                        const SizedBox(width: Gap.sm),
                        _NutToi(icon: Icons.rotate_right_rounded, tooltip: 'Xoay', onTap: _xoayTam),
                        const SizedBox(width: Gap.sm),
                        _NutToi(
                          icon: Icons.download_rounded,
                          tooltip: 'Tải về máy',
                          onTap: _dangTai ? null : _tai,
                          dangBan: _dangTai,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút tròn nền mờ trên màn xem ảnh.
class _NutToi extends StatelessWidget {
  const _NutToi({required this.icon, required this.tooltip, required this.onTap, this.dangBan = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool dangBan;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: .45),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
        disabledBackgroundColor: Colors.black.withValues(alpha: .3),
        minimumSize: const Size(46, 46),
      ),
      icon: dangBan
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon),
    );
  }
}

/// Một tấm trên màn xem lớn. Chưa phóng to thì không bắt cử chỉ kéo — kéo
/// ngang là việc của PageView để lật trang; phóng to rồi mới kéo được ảnh.
/// Chạm đôi để phóng vào chỗ vừa chạm, chạm đôi nữa để về.
class _TrangAnh extends StatefulWidget {
  const _TrangAnh({
    required this.duongDan,
    required this.bienDoi,
    required this.xoay,
    required this.tiLeToiDa,
    required this.onPhongTo,
  });

  final String duongDan;
  final TransformationController bienDoi;

  /// Số lần xoay 90° theo chiều kim đồng hồ.
  final int xoay;
  final double tiLeToiDa;
  final ValueChanged<bool> onPhongTo;

  @override
  State<_TrangAnh> createState() => _TrangAnhState();
}

class _TrangAnhState extends State<_TrangAnh> {
  bool _phongTo = false;
  Offset? _chamDoi;

  @override
  void initState() {
    super.initState();
    widget.bienDoi.addListener(_doiTiLe);
    _phongTo = widget.bienDoi.value.getMaxScaleOnAxis() > 1.01;
  }

  @override
  void didUpdateWidget(covariant _TrangAnh cu) {
    super.didUpdateWidget(cu);
    if (cu.bienDoi != widget.bienDoi) {
      cu.bienDoi.removeListener(_doiTiLe);
      widget.bienDoi.addListener(_doiTiLe);
    }
  }

  @override
  void dispose() {
    widget.bienDoi.removeListener(_doiTiLe);
    super.dispose();
  }

  void _doiTiLe() {
    final co = widget.bienDoi.value.getMaxScaleOnAxis() > 1.01;
    if (co != _phongTo) {
      setState(() => _phongTo = co);
      widget.onPhongTo(co);
    } else {
      // Nút +/− đổi tỉ lệ mà không qua ngưỡng thì vẫn cần vẽ lại nút.
      setState(() {});
    }
  }

  void _chamDoiXong() {
    if (_phongTo) {
      widget.bienDoi.value = Matrix4.identity();
      return;
    }
    final tam = _chamDoi;
    if (tam == null) return;
    const ti = 2.5;
    // Phóng quanh điểm chạm: dời sao cho điểm đó đứng yên.
    widget.bienDoi.value = Matrix4.identity()
      ..translateByDouble(-tam.dx * (ti - 1), -tam.dy * (ti - 1), 0, 1)
      ..scaleByDouble(ti, ti, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _chamDoi = d.localPosition,
      onDoubleTap: _chamDoiXong,
      child: InteractiveViewer(
        transformationController: widget.bienDoi,
        panEnabled: _phongTo,
        minScale: 1,
        maxScale: widget.tiLeToiDa,
        child: Center(
          child: RotatedBox(
            quarterTurns: widget.xoay,
            child: _NoiDungAnh(duongDan: widget.duongDan, fit: BoxFit.contain, lon: true),
          ),
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
