import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/huy_hieu/chuoi.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/ngay.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';

/// Khung phần thưởng trên trang chủ — cả của con lẫn của bố mẹ.
///
/// Con nhìn thấy đúng một câu: "còn 3 ngày nữa là được đi ăn kem", kèm chuỗi
/// đang có và vé nghỉ tuần này. Bố mẹ thấy y như con, cộng nút quản lý —
/// treo, trao, treo lại, xóa đều ở phía bố mẹ, vì quà là chuyện của nhà.
class KhungPhanThuong extends StatelessWidget {
  const KhungPhanThuong({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final laPhuHuynh = s.nguoiDung?.vaiTro == VaiTro.phuHuynh;
    final ds = s.tienDoPhanThuong;
    // Con chưa có quà nào thì không bày một khung trống ra — bố mẹ mới là
    // người cần thấy lời mời treo.
    if (ds.isEmpty && !laPhuHuynh) return const SizedBox.shrink();

    final chuoi = s.chuoi;
    final ten = s.hocSinhHienTai?.tenGoi ?? 'con';
    final hien = ds.where((t) => !t.phanThuong.daTrao).take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TieuDeMuc(
          'Phần thưởng',
          eyebrow: chuoi.hienTai == 0
              ? 'Chưa có chuỗi ngày nào'
              : 'Chuỗi ${chuoi.hienTai} ngày trọn bài',
          hanhDong: ds.isEmpty
              ? null
              : TextButton(
                  onPressed: () => moDanhSachPhanThuong(context),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: Text(laPhuHuynh ? 'Quản lý' : 'Xem tất cả'),
                ),
        ),
        const SizedBox(height: Gap.md),
        Container(
          decoration: BoxDecoration(
            color: AppColor.giayTrang,
            borderRadius: BorderRadius.circular(R.lg),
            border: Border.all(color: AppColor.dongKe),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ds.isEmpty)
                _LoiMoiTreo(ten: ten)
              else if (hien.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(Gap.lg),
                  child: Text(
                    'Quà nào cũng đã trao rồi. ${laPhuHuynh ? 'Treo lại hoặc treo quà mới cho $ten nhé.' : 'Chờ bố mẹ treo quà mới nhé.'}',
                    style: AppType.ui(13.5, color: AppColor.mucNhat, w: FontWeight.w500, height: 1.5),
                  ),
                )
              else
                for (var i = 0; i < hien.length; i++) ...[
                  if (i > 0) const Divider(indent: Gap.lg, endIndent: Gap.lg, height: 1),
                  _DongTienDo(td: hien[i], ten: ten, laPhuHuynh: laPhuHuynh),
                ],
              const Divider(indent: Gap.lg, endIndent: Gap.lg, height: 1),
              _VeNghi(chuoi: chuoi),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoiMoiTreo extends StatelessWidget {
  const _LoiMoiTreo({required this.ten});
  final String ten;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Treo một phần thưởng cho $ten', style: AppType.ui(15, w: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Ví dụ: 7 ngày liền xong hết bài → cả nhà đi ăn kem. App đếm ngày, '
            'bạn trao quà. $ten thấy trên trang chủ còn bao nhiêu ngày nữa.',
            style: AppType.ui(13, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.5),
          ),
          const SizedBox(height: Gap.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => moSoanPhanThuong(context),
              icon: const Icon(Icons.card_giftcard_rounded, size: 18),
              label: const Text('Treo phần thưởng'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một phần thưởng với thanh tiến độ và câu nói thẳng còn bao xa.
class _DongTienDo extends StatelessWidget {
  const _DongTienDo({required this.td, required this.ten, required this.laPhuHuynh});
  final TienDoPhanThuong td;
  final String ten;
  final bool laPhuHuynh;

  @override
  Widget build(BuildContext context) {
    final pt = td.phanThuong;
    final (chu, mau) = td.dat
        ? (laPhuHuynh ? '$ten đã đạt rồi — trao quà thôi!' : 'Đạt rồi! Chờ bố mẹ trao', AppColor.xong)
        : td.conLai == pt.moc
            ? ('${pt.moc} ngày liền xong hết bài', AppColor.mucNhat)
            : ('Còn ${td.conLai} ngày nữa', AppColor.muc);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                td.dat ? Icons.redeem_rounded : Icons.card_giftcard_rounded,
                size: 20,
                color: td.dat ? AppColor.xong : AppColor.hocThem,
              ),
              const SizedBox(width: Gap.sm + 2),
              Expanded(
                child: Text(pt.ten,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.ui(15, w: FontWeight.w700)),
              ),
              const SizedBox(width: Gap.sm),
              Text('${td.hienTai.clamp(0, pt.moc)}/${pt.moc}',
                  style: AppType.numeric(12.5, color: AppColor.mucNhat, w: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: Gap.sm),
          ThanhTienDo(td.tiLe, mau: td.dat ? AppColor.xong : AppColor.muc),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(chu, style: AppType.ui(12.5, color: mau, w: FontWeight.w600)),
              ),
              if (td.dat && laPhuHuynh)
                TextButton(
                  onPressed: () => _trao(context, pt),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('Đã trao'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dòng vé nghỉ: nói rõ tuần này còn được nghỉ không, để con không sợ đứt
/// chuỗi vì một tối bận, và cũng không tưởng nghỉ thoải mái.
class _VeNghi extends StatelessWidget {
  const _VeNghi({required this.chuoi});
  final KetQuaChuoi chuoi;

  @override
  Widget build(BuildContext context) {
    final conVe = chuoi.veConLaiTuanNay;
    final ngayDung = chuoi.ngayDungVeGanNhat;
    final dungTuanNay = ngayDung != null && chuoi.veDaDungTuanNay > 0;
    final chu = conVe > 0
        ? 'Vé nghỉ tuần này: còn $conVe — bận một tối cũng không đứt chuỗi.'
        : dungTuanNay
            ? 'Đã dùng vé nghỉ hôm ${Ngay.thu(ngayDung)} — tuần này đừng bỏ thêm ngày nào nhé.'
            : 'Tuần này hết vé nghỉ.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm + 2, Gap.lg, Gap.sm + 2),
      child: Row(
        children: [
          Icon(Icons.confirmation_number_outlined,
              size: 15, color: conVe > 0 ? AppColor.muc : AppColor.dangLam),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(chu,
                style: AppType.ui(12, color: AppColor.mucNhat, w: FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

Future<void> _trao(BuildContext context, PhanThuong pt) async {
  final s = context.read<AppState>();
  final tb = ScaffoldMessenger.of(context);
  await s.traoPhanThuong(pt);
  tb.showSnackBar(SnackBar(
    content: Text('Đã ghi là trao "${pt.ten}". Muốn con làm tiếp thì bấm Treo lại.'),
  ));
}

// ------------------------------------------------------------ danh sách

/// Toàn bộ phần thưởng của con. Bố mẹ có nút treo mới và các hành động trên
/// từng món; con chỉ xem.
Future<void> moDanhSachPhanThuong(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: const _DanhSachPhanThuong(),
    ),
  );
}

class _DanhSachPhanThuong extends StatelessWidget {
  const _DanhSachPhanThuong();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final laPhuHuynh = s.nguoiDung?.vaiTro == VaiTro.phuHuynh;
    final ds = s.tienDoPhanThuong;
    final ten = s.hocSinhHienTai?.tenGoi ?? 'con';

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
      decoration: const BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg + 4)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Gap.md),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.dongKeDam,
                borderRadius: BorderRadius.circular(R.pill),
              ),
            ),
            const SizedBox(height: Gap.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: TieuDeMuc(
                'Phần thưởng của $ten',
                eyebrow: 'Chuỗi ${s.chuoi.hienTai} ngày · dài nhất ${s.chuoi.daiNhat}',
                hanhDong: laPhuHuynh
                    ? TextButton.icon(
                        onPressed: () => moSoanPhanThuong(context),
                        icon: const Icon(Icons.add_rounded, size: 17),
                        label: const Text('Treo mới'),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: Gap.md),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xl),
                itemCount: ds.length,
                separatorBuilder: (_, _) => const SizedBox(height: Gap.sm + 2),
                itemBuilder: (_, i) => _TheMon(td: ds[i], ten: ten, laPhuHuynh: laPhuHuynh),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TheMon extends StatelessWidget {
  const _TheMon({required this.td, required this.ten, required this.laPhuHuynh});
  final TienDoPhanThuong td;
  final String ten;
  final bool laPhuHuynh;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final pt = td.phanThuong;
    final mau = pt.daTrao
        ? AppColor.mucNhat
        : td.dat
            ? AppColor.xong
            : AppColor.hocThem;
    final trangThai = pt.daTrao
        ? 'Đã trao ${Ngay.ddMM(pt.traoLuc!)}'
        : td.dat
            ? 'Đã đạt — chờ trao'
            : 'Còn ${td.conLai} ngày · tính từ ${Ngay.ddMM(pt.tuNgay)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.md, Gap.sm),
      decoration: BoxDecoration(
        color: pt.daTrao ? AppColor.skySoft : AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: td.dat && !pt.daTrao ? AppColor.xong.withValues(alpha: .45) : AppColor.dongKe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(pt.daTrao ? Icons.check_circle_rounded : Icons.card_giftcard_rounded,
                  size: 20, color: mau),
              const SizedBox(width: Gap.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pt.ten, style: AppType.ui(15, w: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${pt.moc} ngày liền xong hết bài',
                        style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w500)),
                  ],
                ),
              ),
              Text('${td.hienTai.clamp(0, pt.moc)}/${pt.moc}',
                  style: AppType.numeric(13, color: AppColor.mucNhat, w: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: Gap.sm),
          ThanhTienDo(pt.daTrao ? 1 : td.tiLe, mau: mau),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(trangThai, style: AppType.ui(12.5, color: mau, w: FontWeight.w600)),
              ),
              if (laPhuHuynh) ...[
                if (pt.daTrao)
                  TextButton(
                    onPressed: () => s.treoLaiPhanThuong(pt),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Treo lại'),
                  )
                else if (td.dat)
                  TextButton(
                    onPressed: () => _trao(context, pt),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Đã trao'),
                  )
                else
                  TextButton(
                    onPressed: () => moSoanPhanThuong(context, pt: pt),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Sửa'),
                  ),
                IconButton(
                  tooltip: 'Xóa',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColor.mucNhat),
                  onPressed: () async {
                    final dongY = await hoiXoa(context, 'Xóa phần thưởng "${pt.ten}"?');
                    if (dongY) await s.xoaPhanThuong(pt);
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- treo mới

/// Bảng treo hoặc sửa một phần thưởng: mốc ngày và tên quà.
Future<void> moSoanPhanThuong(BuildContext context, {PhanThuong? pt}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: _SoanPhanThuong(pt: pt),
    ),
  );
}

class _SoanPhanThuong extends StatefulWidget {
  const _SoanPhanThuong({this.pt});
  final PhanThuong? pt;

  @override
  State<_SoanPhanThuong> createState() => _SoanPhanThuongState();
}

class _SoanPhanThuongState extends State<_SoanPhanThuong> {
  static const _mocNhanh = [3, 5, 7, 14, 21, 30];
  static const _goiYQua = [
    'Đi ăn kem cả nhà',
    'Thêm 30 phút chơi game',
    'Đi công viên cuối tuần',
    'Chọn món ăn tối',
    'Một cuốn truyện mới',
  ];

  late final _ten = TextEditingController(text: widget.pt?.ten ?? '');
  late final _mocKhac = TextEditingController();
  late int _moc = widget.pt?.moc ?? 7;
  bool _dangLuu = false;

  @override
  void dispose() {
    _ten.dispose();
    _mocKhac.dispose();
    super.dispose();
  }

  Future<void> _luu() async {
    final ten = _ten.text.trim();
    if (ten.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ghi tên quà đã nhé')),
      );
      return;
    }
    setState(() => _dangLuu = true);
    final s = context.read<AppState>();
    final cu = widget.pt;
    try {
      if (cu == null) {
        await s.treoPhanThuong(moc: _moc, ten: ten);
      } else {
        await s.luuPhanThuong(cu.copyWith(moc: _moc, ten: ten));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangLuu = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không lưu được: $e')));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ten = context.read<AppState>().hocSinhHienTai?.tenGoi ?? 'con';
    final suaCu = widget.pt != null;

    return KhungBieuMau(
      tieuDe: suaCu ? 'Sửa phần thưởng' : 'Treo phần thưởng cho $ten',
      eyebrow: 'App đếm ngày, bạn trao quà',
      nhanLuu: suaCu ? 'Lưu' : 'Treo',
      dangLuu: _dangLuu,
      onLuu: _luu,
      children: [
        const NhanO('Bao nhiêu ngày liền xong hết bài?'),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final m in _mocNhanh)
              ChoiceChip(
                label: Text('$m ngày'),
                selected: _moc == m,
                showCheckmark: false,
                selectedColor: AppColor.muc,
                labelStyle: AppType.ui(13,
                    w: FontWeight.w600, color: _moc == m ? Colors.white : AppColor.muc),
                onSelected: (_) => setState(() {
                  _moc = m;
                  _mocKhac.clear();
                }),
              ),
            SizedBox(
              width: 96,
              child: TextField(
                controller: _mocKhac,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppType.ui(13.5, w: FontWeight.w600),
                decoration: const InputDecoration(hintText: 'Số khác', isDense: true),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n >= 1 && n <= 365) setState(() => _moc = n);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.sm),
        Text(
          'Ngày không có tiết trong thời khóa biểu không tính, và mỗi tuần $ten '
          'được một vé nghỉ — bận một tối cũng không đứt chuỗi.',
          style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.45),
        ),
        const SizedBox(height: Gap.lg),
        const NhanO('Quà là gì?'),
        TextField(
          controller: _ten,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 120,
          style: AppType.ui(15, w: FontWeight.w500),
          decoration: const InputDecoration(hintText: 'Đi ăn kem cả nhà', counterText: ''),
        ),
        const SizedBox(height: Gap.sm),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final q in _goiYQua)
              ActionChip(
                label: Text(q),
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _ten.text = q),
              ),
          ],
        ),
        if (suaCu) ...[
          const SizedBox(height: Gap.md),
          Text(
            'Đổi mốc không đếm lại từ đầu — chuỗi vẫn tính từ ${Ngay.ddMM(widget.pt!.tuNgay)}.',
            style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.45),
          ),
        ],
      ],
    );
  }
}
