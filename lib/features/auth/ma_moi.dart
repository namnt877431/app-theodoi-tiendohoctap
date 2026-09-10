import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import '../../data/repositories/hoc_tap_repository.dart';
import 'dang_nhap_screen.dart';

/// Sáu chữ số, mỗi số một ô — đúng dáng ô điền của phiếu trắc nghiệm, và đủ
/// to để đọc qua điện thoại cho bố mẹ nghe.
class _OSo extends StatelessWidget {
  const _OSo(this.chuSo, {this.mo = false});
  final String chuSo;
  final bool mo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: mo ? AppColor.sky.withValues(alpha: .5) : AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: mo ? AppColor.dongKe : AppColor.muc.withValues(alpha: .35)),
      ),
      child: Text(
        chuSo,
        style: AppType.numeric(24, w: FontWeight.w700, color: mo ? AppColor.dongKeDam : AppColor.ink),
      ),
    );
  }
}

class _DayOSo extends StatelessWidget {
  const _DayOSo(this.ma);
  final String? ma;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 6; i++) ...[
          if (i == 3) const SizedBox(width: Gap.md),
          _OSo(ma == null ? '·' : ma![i], mo: ma == null),
          if (i != 5 && i != 2) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

/// Thẻ trên trang Tài khoản của học sinh: sinh mã để bố mẹ nhập.
class TaoMaMoiThe extends StatefulWidget {
  const TaoMaMoiThe({super.key});

  @override
  State<TaoMaMoiThe> createState() => _TaoMaMoiTheState();
}

class _TaoMaMoiTheState extends State<TaoMaMoiThe> {
  MaMoi? _ma;
  Timer? _dongHo;
  bool _dangTao = false;
  String? _loi;

  @override
  void dispose() {
    _dongHo?.cancel();
    super.dispose();
  }

  Future<void> _tao() async {
    setState(() {
      _dangTao = true;
      _loi = null;
    });
    try {
      final ma = await context.read<AppState>().taoMaMoi();
      if (!mounted) return;
      setState(() => _ma = ma);
      _dongHo?.cancel();
      _dongHo = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() {});
        if (!(_ma?.conHieuLuc ?? false)) t.cancel();
      });
    } on LoiHocTap catch (e) {
      if (mounted) setState(() => _loi = e.thongDiep);
    } finally {
      if (mounted) setState(() => _dangTao = false);
    }
  }

  String get _conLai {
    final d = _ma?.conLai ?? Duration.zero;
    if (d.isNegative) return 'đã hết hạn';
    final p = d.inMinutes;
    final g = d.inSeconds % 60;
    return 'còn $p:${g.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final song = _ma?.conHieuLuc ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TieuDeMuc('Cho bố mẹ theo dõi', eyebrow: 'Mã mời'),
        const SizedBox(height: Gap.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Gap.lg),
          decoration: BoxDecoration(
            color: AppColor.giayTrang,
            borderRadius: BorderRadius.circular(R.lg),
            border: Border.all(color: AppColor.dongKe),
          ),
          child: Column(
            children: [
              Text(
                song
                    ? 'Đọc sáu số này cho bố mẹ nhập vào app của họ.'
                    : 'Tạo một mã sáu số rồi đọc cho bố mẹ. Mã sống 15 phút và chỉ dùng được một lần.',
                textAlign: TextAlign.center,
                style: AppType.ui(13, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.5),
              ),
              const SizedBox(height: Gap.lg),
              _DayOSo(song ? _ma!.ma : null),
              const SizedBox(height: Gap.md),
              if (song)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 14,
                        color: _ma!.conLai.inMinutes < 3 ? AppColor.butDo : AppColor.mucNhat),
                    const SizedBox(width: 5),
                    Text(
                      'Hiệu lực $_conLai',
                      style: AppType.ui(12,
                          w: FontWeight.w600,
                          color: _ma!.conLai.inMinutes < 3
                              ? AppColor.butDo
                              : AppColor.mucNhat),
                    ),
                    const SizedBox(width: Gap.md),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _ma!.ma));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã chép mã')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 15),
                      label: const Text('Chép mã'),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
              if (_loi != null) ...[
                const SizedBox(height: Gap.sm),
                HopLoi(_loi!),
              ],
              const SizedBox(height: Gap.md),
              SizedBox(
                width: double.infinity,
                child: song
                    ? OutlinedButton(
                        onPressed: _dangTao ? null : _tao,
                        child: const Text('Tạo mã khác'),
                      )
                    : FilledButton(
                        onPressed: _dangTao ? null : _tao,
                        child: Text(_dangTao ? 'Đang tạo…' : 'Tạo mã mời'),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bảng phụ huynh nhập mã sáu số con vừa đọc.
Future<void> moNhapMaMoi(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: const _NhapMaMoi(),
    ),
  );
}

class _NhapMaMoi extends StatefulWidget {
  const _NhapMaMoi();

  @override
  State<_NhapMaMoi> createState() => _NhapMaMoiState();
}

class _NhapMaMoiState extends State<_NhapMaMoi> {
  final _c = TextEditingController();
  bool _dangNoi = false;
  String? _loi;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _noi() async {
    setState(() {
      _dangNoi = true;
      _loi = null;
    });
    try {
      final hs = await context.read<AppState>().dungMaMoi(_c.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã nối với tài khoản của ${hs.hoTen}')),
      );
    } on LoiHocTap catch (e) {
      if (mounted) setState(() => _loi = e.thongDiep);
    } catch (_) {
      if (mounted) setState(() => _loi = 'Không nối được. Kiểm tra mạng rồi thử lại.');
    } finally {
      if (mounted) setState(() => _dangNoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final du = _c.text.replaceAll(RegExp(r'\D'), '').length == 6;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColor.giayTrang,
          borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg + 4)),
        ),
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.lg),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColor.dongKeDam,
                    borderRadius: BorderRadius.circular(R.pill),
                  ),
                ),
              ),
              const SizedBox(height: Gap.lg),
              TieuDeMuc('Nhập mã mời của con', eyebrow: 'Nối hai tài khoản'),
              const SizedBox(height: Gap.sm),
              Text(
                'Nhờ con mở app, vào mục Tài khoản, bấm "Tạo mã mời" rồi đọc sáu số cho bạn.',
                style: AppType.ui(13, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.5),
              ),
              const SizedBox(height: Gap.lg),
              TextField(
                controller: _c,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => du ? _noi() : null,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppType.numeric(30, w: FontWeight.w700).copyWith(letterSpacing: 10),
                decoration: const InputDecoration(
                  hintText: '——————',
                  counterText: '',
                ),
              ),
              if (_loi != null) ...[
                const SizedBox(height: Gap.md),
                HopLoi(_loi!),
              ],
              const SizedBox(height: Gap.lg),
              FilledButton(
                onPressed: (!du || _dangNoi) ? null : _noi,
                child: Text(_dangNoi ? 'Đang nối…' : 'Nối vào tài khoản con'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trạng thái rỗng của phụ huynh chưa nối con nào — mời làm việc, không xin lỗi.
class LoiMoiNhapMa extends StatelessWidget {
  const LoiMoiNhapMa({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: AppColor.dongKe),
      ),
      child: TrangTrong(
        icon: Icons.link_rounded,
        tieuDe: 'Chưa nối với tài khoản nào',
        moTa: 'Nhờ con mở app, vào mục Tài khoản và tạo mã mời sáu số, rồi nhập mã đó vào đây.',
        hanhDong: FilledButton.icon(
          onPressed: () => moNhapMaMoi(context),
          icon: const Icon(Icons.tag_rounded, size: 18),
          label: const Text('Nhập mã mời'),
        ),
      ),
    );
  }
}
