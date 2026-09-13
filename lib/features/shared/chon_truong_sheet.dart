import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/repositories/hoc_tap_repository.dart';
import '../auth/dang_nhap_screen.dart' show HopLoi;

/// Học sinh chọn (hay đổi) trường của mình: tỉnh → trường, lấy từ danh mục
/// quản trị đã nhập. Đổi xong, danh sách thầy cô trên lớp đổi theo.
Future<void> moChonTruong(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: const _ChonTruong(),
      ),
    );

class _ChonTruong extends StatefulWidget {
  const _ChonTruong();

  @override
  State<_ChonTruong> createState() => _ChonTruongState();
}

class _ChonTruongState extends State<_ChonTruong> {
  String? _tinhId;
  String? _truongId;
  bool _dangLuu = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _truongId = s.nguoiDung?.truongId;
    _tinhId = s.truongTheoId(_truongId)?.tinhId;
  }

  Future<void> _luu() async {
    final s = context.read<AppState>();
    final nd = s.nguoiDung;
    if (nd == null || _truongId == null) return;
    setState(() {
      _dangLuu = true;
      _loi = null;
    });
    try {
      await s.capNhatHoSo(nd.copyWith(truongId: _truongId, truong: s.tenTruong(_truongId)));
      if (!mounted) return;
      Navigator.of(context).pop();
    } on LoiHocTap catch (e) {
      if (mounted) setState(() => _loi = e.thongDiep);
    } catch (e) {
      if (mounted) setState(() => _loi = 'Không lưu được ($e).');
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final dsTruong = s.truongTheoTinh(_tinhId);
    final hienTai = dsTruong.any((t) => t.id == _truongId) ? _truongId : null;

    return KhungBieuMau(
      tieuDe: 'Trường của con',
      eyebrow: 'Hồ sơ',
      nhanLuu: 'Lưu',
      dangLuu: _dangLuu,
      onLuu: hienTai == null ? null : _luu,
      children: [
        if (s.truong.isEmpty)
          Text(
            'Danh mục trường còn trống. Nhờ quản trị thêm trường rồi quay lại chọn.',
            style: AppType.ui(13.5, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.5),
          )
        else ...[
          if (s.tinh.isNotEmpty) ...[
            const NhanO('Tỉnh / thành phố'),
            DropdownButtonFormField<String?>(
              key: ValueKey('tinh-$_tinhId'),
              initialValue: _tinhId,
              isExpanded: true,
              style: AppType.ui(15, w: FontWeight.w500),
              hint: const Text('Mọi tỉnh'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Mọi tỉnh')),
                for (final t in s.tinh)
                  DropdownMenuItem<String?>(value: t.id, child: Text(t.ten)),
              ],
              onChanged: (v) => setState(() {
                _tinhId = v;
                if (v != null && s.truongTheoId(_truongId)?.tinhId != v) _truongId = null;
              }),
            ),
            const SizedBox(height: Gap.lg),
          ],
          const NhanO('Trường'),
          DropdownButtonFormField<String?>(
            key: ValueKey('truong-$_tinhId-$hienTai'),
            initialValue: hienTai,
            isExpanded: true,
            style: AppType.ui(15, w: FontWeight.w500),
            hint: const Text('Chọn trường'),
            items: [
              for (final t in dsTruong)
                DropdownMenuItem<String?>(
                  value: t.id,
                  child: Text(t.ten, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _truongId = v),
          ),
          const SizedBox(height: Gap.sm),
          Text(
            'Chọn đúng trường thì lúc viết báo cáo chỉ hiện thầy cô của trường mình.',
            style: AppType.ui(12, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.45),
          ),
        ],
        if (_loi != null) ...[const SizedBox(height: Gap.md), HopLoi(_loi!)],
      ],
    );
  }
}
