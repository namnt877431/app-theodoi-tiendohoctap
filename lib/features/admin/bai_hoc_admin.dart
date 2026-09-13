import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/bo_cuc.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import '../../data/repositories/hoc_tap_repository.dart';
import '../auth/dang_nhap_screen.dart' show HopLoi;

/// Tab "Bài học" của màn Danh mục: chọn khối, chọn môn, xem danh sách bài
/// theo chương và sửa tóm tắt, câu hỏi. Dữ liệu gốc nạp bằng file SQL
/// (supabase/09_bai_hoc_lop*.sql); ở đây quản trị sửa những chỗ chưa ưng —
/// chạy lại file SQL không ghi đè bài đã sửa tay.
class DsBaiHoc extends StatefulWidget {
  const DsBaiHoc({super.key, required this.khoi, required this.onDoiKhoi});

  final int khoi;
  final ValueChanged<int> onDoiKhoi;

  @override
  State<DsBaiHoc> createState() => _DsBaiHocState();
}

class _DsBaiHocState extends State<DsBaiHoc> {
  String? _monId;
  bool _dangNap = false;

  @override
  void initState() {
    super.initState();
    _nap();
  }

  @override
  void didUpdateWidget(DsBaiHoc cu) {
    super.didUpdateWidget(cu);
    if (cu.khoi != widget.khoi) _nap();
  }

  Future<void> _nap({bool lamMoi = false}) async {
    setState(() => _dangNap = true);
    try {
      await context.read<AppState>().taiBaiHocKhoi(widget.khoi, lamMoi: lamMoi);
    } finally {
      if (mounted) setState(() => _dangNap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tatCa = s.baiHocKhoi(widget.khoi);
    // Chỉ liệt kê môn có bài; môn đang chọn mà không còn bài thì về môn đầu.
    final monCo = s.monHoc.where((m) => tatCa.any((b) => b.monId == m.id)).toList();
    final monId = monCo.any((m) => m.id == _monId) ? _monId : monCo.firstOrNull?.id;
    final ds = tatCa.where((b) => b.monId == monId).toList();

    return Column(
      children: [
        LayoutBuilder(builder: (context, rang) {
          final le = BoCuc.leCanhGiua(rang.maxWidth, BoCuc.le(context), toiDa: 900);
          return Padding(
          padding: EdgeInsets.fromLTRB(le, Gap.md, le, 0),
          child: Row(
            children: [
              SizedBox(
                width: 104,
                child: DropdownButtonFormField<int>(
                  initialValue: widget.khoi,
                  style: AppType.ui(14, w: FontWeight.w600),
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    for (var k = 1; k <= 12; k++)
                      DropdownMenuItem(value: k, child: Text('Lớp $k')),
                  ],
                  onChanged: (v) => v == null ? null : widget.onDoiKhoi(v),
                ),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('mon-${widget.khoi}-$monId'),
                  initialValue: monId,
                  isExpanded: true,
                  style: AppType.ui(14, w: FontWeight.w600),
                  decoration: const InputDecoration(isDense: true),
                  hint: const Text('Môn'),
                  items: [
                    for (final m in monCo)
                      DropdownMenuItem(
                        value: m.id,
                        child: Text('${m.ten} (${tatCa.where((b) => b.monId == m.id).length})'),
                      ),
                  ],
                  onChanged: monCo.isEmpty ? null : (v) => setState(() => _monId = v),
                ),
              ),
              const SizedBox(width: Gap.sm),
              NutO(
                icon: Icons.refresh_rounded,
                tooltip: 'Nạp lại từ máy chủ',
                onTap: _dangNap ? null : () => _nap(lamMoi: true),
              ),
            ],
          ),
        );
        }),
        Expanded(
          child: _dangNap && tatCa.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : tatCa.isEmpty
                  ? TrangTrong(
                      icon: Icons.menu_book_outlined,
                      tieuDe: 'Lớp ${widget.khoi} chưa có danh mục bài học',
                      moTa: 'Nạp bằng file supabase/09_bai_hoc_lop${widget.khoi}.sql (xem README), hoặc thêm từng bài bằng nút bên dưới.',
                    )
                  : _DanhSach(ds: ds),
        ),
      ],
    );
  }
}

class _DanhSach extends StatelessWidget {
  const _DanhSach({required this.ds});
  final List<BaiHoc> ds;

  @override
  Widget build(BuildContext context) {
    final muc = <Widget>[];
    String? chuongTruoc;
    final chuaCo = ds.where((b) => !b.coTomTat).length;
    if (chuaCo > 0) {
      muc.add(Padding(
        padding: const EdgeInsets.only(top: Gap.md),
        child: Text(
          '$chuaCo/${ds.length} bài chưa có tóm tắt',
          style: AppType.ui(12.5, color: AppColor.dangLam, w: FontWeight.w600),
        ),
      ));
    }
    for (final b in ds) {
      if (b.chuong != chuongTruoc) {
        chuongTruoc = b.chuong;
        muc.add(Padding(
          padding: const EdgeInsets.fromLTRB(2, Gap.lg, 2, Gap.xs),
          child: Eyebrow(b.chuong ?? 'Khác'),
        ));
      }
      muc.add(_Dong(bh: b));
    }
    return LayoutBuilder(builder: (context, rang) {
      final le = BoCuc.leCanhGiua(rang.maxWidth, BoCuc.le(context), toiDa: 900);
      return ListView(
        padding: EdgeInsets.fromLTRB(le, 0, le, 96),
        children: muc,
      );
    });
  }
}

class _Dong extends StatelessWidget {
  const _Dong({required this.bh});
  final BaiHoc bh;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(R.md),
      onTap: () => moSuaBaiHoc(context, bh: bh),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.sm + 1),
        child: Row(
          children: [
            Icon(
              bh.coTomTat ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: bh.coTomTat ? AppColor.xong : AppColor.dongKeDam,
            ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: Text(bh.ten, style: AppType.ui(14, w: FontWeight.w500)),
            ),
            if (bh.kiemTra.isNotEmpty) ...[
              const SizedBox(width: Gap.sm),
              Text('${bh.kiemTra.length} câu hỏi',
                  style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mở bảng sửa một bài, hoặc thêm bài mới cho môn/khối khi [bh] null.
Future<void> moSuaBaiHoc(
  BuildContext context, {
  BaiHoc? bh,
  int? khoi,
  String? monId,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: _SuaBaiHoc(bh: bh, khoi: khoi, monId: monId),
      ),
    );

class _SuaBaiHoc extends StatefulWidget {
  const _SuaBaiHoc({this.bh, this.khoi, this.monId});
  final BaiHoc? bh;
  final int? khoi;
  final String? monId;

  @override
  State<_SuaBaiHoc> createState() => _SuaBaiHocState();
}

class _SuaBaiHocState extends State<_SuaBaiHoc> {
  final _form = GlobalKey<FormState>();
  late final _ten = TextEditingController(text: widget.bh?.ten ?? '');
  late final _chuong = TextEditingController(text: widget.bh?.chuong ?? '');
  late final _tomTat = TextEditingController(text: widget.bh?.tomTat ?? '');
  late final _hoi = TextEditingController(text: (widget.bh?.kiemTra ?? const []).join('\n'));
  bool _dangLuu = false;
  String? _loi;

  /// Môn của bài mới; bài đang sửa thì giữ nguyên môn.
  late String? _monId = widget.bh?.monId ?? widget.monId;

  @override
  void dispose() {
    _ten.dispose();
    _chuong.dispose();
    _tomTat.dispose();
    _hoi.dispose();
    super.dispose();
  }

  Future<void> _chay(Future<void> Function() viec) async {
    setState(() {
      _dangLuu = true;
      _loi = null;
    });
    try {
      await viec();
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

  Future<void> _xoa() async {
    final bh = widget.bh!;
    final dongY = await hoiXoa(
      context,
      'Xóa "${bh.ten}"?',
      giaiThich: 'Báo cáo đã gắn bài này vẫn còn, chỉ mất liên kết tới bài.',
    );
    if (!dongY || !mounted) return;
    await _chay(() => context.read<AppState>().xoaBaiHoc(bh));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final cu = widget.bh;
    final sua = cu != null;
    final khoi = cu?.lop ?? widget.khoi ?? 8;
    final monId = _monId ?? s.monMacDinh;

    return Form(
      key: _form,
      child: KhungBieuMau(
        tieuDe: sua ? 'Sửa bài học' : 'Thêm bài học',
        eyebrow: '${s.tenMon(monId)} · lớp $khoi',
        nhanLuu: sua ? 'Lưu thay đổi' : 'Thêm',
        dangLuu: _dangLuu,
        onXoa: sua ? _xoa : null,
        onLuu: () {
          if (!_form.currentState!.validate()) return;
          final hoi = _hoi.text
              .split('\n')
              .map((d) => d.trim())
              .where((d) => d.isNotEmpty)
              .toList();
          final chuong = _chuong.text.trim();
          final tomTat = _tomTat.text.trim();
          final ds = s.baiHocKhoi(khoi).where((b) => b.monId == monId);
          final thuTu = cu?.thuTu ??
              (ds.isEmpty ? 1 : ds.map((b) => b.thuTu).reduce((a, b) => a > b ? a : b) + 1);
          _chay(() => s.luuBaiHoc(BaiHoc(
                id: cu?.id ?? '',
                monId: monId,
                lop: khoi,
                hocKi: cu?.hocKi,
                thuTu: thuTu,
                ten: _ten.text.trim(),
                chuong: chuong.isEmpty ? null : chuong,
                tomTat: tomTat.isEmpty ? null : tomTat,
                kiemTra: hoi,
              )));
        },
        children: [
          if (!sua) ...[
            const NhanO('Môn'),
            DropdownButtonFormField<String>(
              initialValue: monId,
              isExpanded: true,
              style: AppType.ui(15, w: FontWeight.w500),
              items: [
                for (final m in s.monHoc) DropdownMenuItem(value: m.id, child: Text(m.ten)),
              ],
              onChanged: (v) => setState(() => _monId = v),
            ),
            const SizedBox(height: Gap.lg),
          ],
          const NhanO('Tên bài'),
          TextFormField(
            controller: _ten,
            autofocus: !sua,
            textCapitalization: TextCapitalization.sentences,
            style: AppType.ui(15, w: FontWeight.w500),
            decoration: const InputDecoration(hintText: 'Bài 6: Lũy thừa với số mũ tự nhiên'),
            validator: (v) => (v ?? '').trim().isNotEmpty ? null : 'Nhập tên bài',
          ),
          const SizedBox(height: Gap.lg),
          const NhanO('Chương / chủ đề'),
          TextFormField(
            controller: _chuong,
            textCapitalization: TextCapitalization.sentences,
            style: AppType.ui(15, w: FontWeight.w500),
            decoration: const InputDecoration(hintText: 'Chương 1: Tập hợp các số tự nhiên'),
          ),
          const SizedBox(height: Gap.lg),
          const NhanO('Tóm tắt cho phụ huynh'),
          TextFormField(
            controller: _tomTat,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            style: AppType.ui(14.5, w: FontWeight.w400, height: 1.45),
            decoration: const InputDecoration(
              hintText: 'Hai ba câu: bài này con học gì, cần nhớ gì.',
            ),
          ),
          const SizedBox(height: Gap.lg),
          const NhanO('Câu hỏi để bố mẹ hỏi con — mỗi dòng một câu'),
          TextFormField(
            controller: _hoi,
            minLines: 3,
            maxLines: 10,
            style: AppType.ui(14.5, w: FontWeight.w400, height: 1.45),
            decoration: const InputDecoration(
              hintText: '3⁴ bằng bao nhiêu? → 81\nĐặt một câu với "when".',
            ),
          ),
          const SizedBox(height: Gap.sm),
          Text(
            'Viết " → " rồi đáp án ở cuối câu nếu muốn app hiện gợi ý đáp án.',
            style: AppType.ui(12, color: AppColor.mucNhat, w: FontWeight.w500),
          ),
          if (_loi != null) ...[const SizedBox(height: Gap.md), HopLoi(_loi!)],
        ],
      ),
    );
  }
}
