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
    final hien = ds.where((t) => !t.phanThuong.xongHan).take(2).toList();

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
    final s = context.read<AppState>();
    final pt = td.phanThuong;
    final laDiem = pt.loai == LoaiPhanThuong.diem;
    final lanThu = pt.lapLai && pt.soLanTrao > 0 ? ' lần thứ ${pt.soLanTrao + 1}' : '';
    final baiMoi = td.baiDat.firstOrNull;
    final (chu, mau) = td.dat
        ? (
            laDiem && baiMoi != null
                ? '${baiMoi.diemChu} ${baiMoi.loai.nhan.toLowerCase()} ${s.tenMon(baiMoi.monId)}'
                    '${td.conNo > 1 ? ' và ${td.conNo - 1} bài nữa' : ''} — '
                    '${laPhuHuynh ? 'trao quà thôi!' : 'chờ bố mẹ trao'}'
                : laPhuHuynh
                    ? '$ten đã đạt${td.conNo > 1 ? ' ${td.conNo} lần' : ''} — trao quà thôi!'
                    : 'Đạt rồi! Chờ bố mẹ trao${td.conNo > 1 ? ' (${td.conNo} lần)' : ''}',
            AppColor.xong
          )
        : laDiem
            ? (moTaDieuKien(pt, s), AppColor.mucNhat)
            : td.conLai == pt.moc
                ? ('${pt.moc} ngày liền xong hết bài${pt.lapLai ? ', lặp lại' : ''}', AppColor.mucNhat)
                : ('Còn ${td.conLai} ngày nữa$lanThu', AppColor.muc);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                td.dat
                    ? Icons.redeem_rounded
                    : laDiem
                        ? Icons.grade_rounded
                        : Icons.card_giftcard_rounded,
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
              if (!laDiem)
                Text('${td.hienTai.clamp(0, pt.moc)}/${pt.moc}',
                    style: AppType.numeric(12.5, color: AppColor.mucNhat, w: FontWeight.w600))
              else if (pt.soLanTrao > 0)
                Text('${pt.soLanTrao} lần',
                    style: AppType.numeric(12.5, color: AppColor.mucNhat, w: FontWeight.w600)),
            ],
          ),
          // Quà điểm thi không có "tiến độ" — chỉ có đạt hay chưa.
          if (!laDiem || td.dat) ...[
            const SizedBox(height: Gap.sm),
            ThanhTienDo(td.tiLe, mau: td.dat ? AppColor.xong : AppColor.muc),
          ],
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

/// "Cứ 7 ngày liền xong hết bài lại được một lần" / "Điểm giữa kì Toán từ 8
/// trở lên" — một câu nói đủ điều kiện, dùng ở khung, danh sách và bảng treo.
String moTaDieuKien(PhanThuong pt, AppState s) {
  if (pt.loai == LoaiPhanThuong.diem) {
    final ki = pt.kiThi?.nhan.toLowerCase() ?? 'giữa hoặc cuối kì';
    final mon = pt.monId == null ? 'môn nào cũng được' : s.tenMon(pt.monId);
    return 'Điểm $ki $mon từ ${chuDiem(pt.diemToiThieu ?? 8)} trở lên';
  }
  return pt.lapLai
      ? 'Cứ ${pt.moc} ngày liền xong hết bài lại được một lần'
      : '${pt.moc} ngày liền xong hết bài, một lần';
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
    final laDiem = pt.loai == LoaiPhanThuong.diem;
    final xong = pt.xongHan;
    final mau = xong
        ? AppColor.mucNhat
        : td.dat
            ? AppColor.xong
            : AppColor.hocThem;
    final daTrao = pt.soLanTrao == 0
        ? ''
        : pt.lapLai
            ? ' · đã trao ${pt.soLanTrao} lần'
            : '';
    final baiMoi = td.baiDat.firstOrNull;
    final trangThai = xong
        ? 'Đã trao ${Ngay.ddMM(pt.traoLuc!)}'
        : td.dat
            ? laDiem && baiMoi != null
                ? '${baiMoi.diemChu} ${baiMoi.loai.nhan.toLowerCase()} ${s.tenMon(baiMoi.monId)} '
                    '${Ngay.ddMM(baiMoi.ngay)}${td.conNo > 1 ? ' và ${td.conNo - 1} bài nữa' : ''} — chờ trao$daTrao'
                : 'Đã đạt${td.conNo > 1 ? ' ${td.conNo} lần' : ''} — chờ trao$daTrao'
            : laDiem
                ? 'Chờ bài kiểm tra tới · tính từ ${Ngay.ddMM(pt.tuNgay)}$daTrao'
                : 'Còn ${td.conLai} ngày · tính từ ${Ngay.ddMM(pt.tuNgay)}$daTrao';

    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.md, Gap.sm),
      decoration: BoxDecoration(
        color: xong ? AppColor.skySoft : AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: td.dat ? AppColor.xong.withValues(alpha: .45) : AppColor.dongKe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  xong
                      ? Icons.check_circle_rounded
                      : laDiem
                          ? Icons.grade_rounded
                          : Icons.card_giftcard_rounded,
                  size: 20,
                  color: mau),
              const SizedBox(width: Gap.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pt.ten, style: AppType.ui(15, w: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      moTaDieuKien(pt, s),
                      style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (!laDiem)
                Text('${td.hienTai.clamp(0, pt.moc)}/${pt.moc}',
                    style: AppType.numeric(13, color: AppColor.mucNhat, w: FontWeight.w600)),
            ],
          ),
          if (!laDiem || td.dat) ...[
            const SizedBox(height: Gap.sm),
            ThanhTienDo(xong ? 1 : td.tiLe, mau: mau),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(trangThai, style: AppType.ui(12.5, color: mau, w: FontWeight.w600)),
              ),
              if (laPhuHuynh) ...[
                if (xong)
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

  static const _diemNhanh = [7.0, 8.0, 8.5, 9.0, 9.5, 10.0];

  late final _ten = TextEditingController(text: widget.pt?.ten ?? '');
  late final _mocKhac = TextEditingController();
  late LoaiPhanThuong _loai = widget.pt?.loai ?? LoaiPhanThuong.chuoi;
  late int _moc = widget.pt?.moc ?? 7;
  late bool _lapLai = widget.pt?.lapLai ?? true;
  late String? _monId = widget.pt?.monId;
  late LoaiKiemTra? _kiThi = widget.pt?.kiThi;
  late double _diemToiThieu = widget.pt?.diemToiThieu ?? 8;
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
        if (_loai == LoaiPhanThuong.diem) {
          await s.treoPhanThuongDiem(
              ten: ten, diemToiThieu: _diemToiThieu, monId: _monId, kiThi: _kiThi);
        } else {
          await s.treoPhanThuong(moc: _moc, ten: ten, lapLai: _lapLai);
        }
      } else {
        await s.luuPhanThuong(cu.copyWith(
          loai: _loai,
          moc: _loai == LoaiPhanThuong.diem ? 1 : _moc,
          ten: ten,
          lapLai: _loai == LoaiPhanThuong.diem ? true : _lapLai,
          monId: () => _loai == LoaiPhanThuong.diem ? _monId : null,
          kiThi: () => _loai == LoaiPhanThuong.diem ? _kiThi : null,
          diemToiThieu: _diemToiThieu,
        ));
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
    final s = context.read<AppState>();
    final ten = s.hocSinhHienTai?.tenGoi ?? 'con';
    final chuoi = s.chuoi;
    final suaCu = widget.pt != null;

    return KhungBieuMau(
      tieuDe: suaCu ? 'Sửa phần thưởng' : 'Treo phần thưởng cho $ten',
      eyebrow: 'App đếm ngày, bạn trao quà',
      nhanLuu: suaCu ? 'Lưu' : 'Treo',
      dangLuu: _dangLuu,
      onLuu: _luu,
      children: [
        const NhanO('Thưởng cho việc gì?'),
        Row(
          children: [
            for (final l in LoaiPhanThuong.values) ...[
              Expanded(
                child: OChon(
                  icon: l == LoaiPhanThuong.chuoi
                      ? Icons.local_fire_department_rounded
                      : Icons.grade_rounded,
                  nhan: l == LoaiPhanThuong.chuoi ? 'Chuỗi ngày trọn bài' : 'Điểm thi cao',
                  mau: AppColor.muc,
                  mauNen: AppColor.sky,
                  chon: _loai == l,
                  onTap: () => setState(() => _loai = l),
                ),
              ),
              if (l != LoaiPhanThuong.values.last) const SizedBox(width: Gap.sm),
            ],
          ],
        ),
        const SizedBox(height: Gap.lg),
        if (_loai == LoaiPhanThuong.diem) ...[
          const NhanO('Môn nào?'),
          DropdownButtonFormField<String?>(
            initialValue: s.monHoc.any((m) => m.id == _monId) ? _monId : null,
            isExpanded: true,
            style: AppType.ui(15, w: FontWeight.w500),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Môn nào cũng được')),
              for (final m in s.monHoc) DropdownMenuItem<String?>(value: m.id, child: Text(m.ten)),
            ],
            onChanged: (v) => setState(() => _monId = v),
          ),
          const SizedBox(height: Gap.lg),
          const NhanO('Bài nào?'),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final (LoaiKiemTra? ki, String nhan) in [
                (null, 'Giữa hoặc cuối kì'),
                (LoaiKiemTra.giuaKi, 'Giữa kì'),
                (LoaiKiemTra.cuoiKi, 'Cuối kì'),
              ])
                ChoiceChip(
                  label: Text(nhan),
                  selected: _kiThi == ki,
                  showCheckmark: false,
                  selectedColor: AppColor.muc,
                  labelStyle: AppType.ui(13,
                      w: FontWeight.w600, color: _kiThi == ki ? Colors.white : AppColor.muc),
                  onSelected: (_) => setState(() => _kiThi = ki),
                ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          const NhanO('Điểm từ bao nhiêu trở lên?'),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final d in _diemNhanh)
                ChoiceChip(
                  label: Text(chuDiem(d)),
                  selected: _diemToiThieu == d,
                  showCheckmark: false,
                  selectedColor: AppColor.muc,
                  labelStyle: AppType.numeric(13,
                      w: FontWeight.w600, color: _diemToiThieu == d ? Colors.white : AppColor.muc),
                  onSelected: (_) => setState(() => _diemToiThieu = d),
                ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(
            'Mỗi bài đạt là một lần quà. Điểm miệng, 15 phút không tính — chỉ giữa kì và '
            'cuối kì, ghi trong bảng điểm.',
            style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.45),
          ),
        ] else ...[
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
        const SizedBox(height: Gap.md),
        // Lặp lại là mặc định: thưởng đều mới giữ được nếp; quà lớn một lần
        // (bộ Lego) thì tắt đi.
        SwitchListTile.adaptive(
          value: _lapLai,
          onChanged: (v) => setState(() => _lapLai = v),
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          title: Text('Lặp lại — cứ $_moc ngày lại được một lần',
              style: AppType.ui(14, w: FontWeight.w600)),
          subtitle: Text(
            _lapLai
                ? 'Chuỗi ${_moc * 2} ngày là hai lần quà. Đứt rồi nối lại thì đếm tiếp.'
                : 'Một lần duy nhất. Trao xong bấm "Treo lại" nếu muốn đếm lại.',
            style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.4),
          ),
        ),
        const SizedBox(height: Gap.sm),
        // Chuỗi đang có và kỷ lục — để chọn mốc vừa sức: xa hơn kỷ lục một
        // chút thì hay, gấp ba thì con nản.
        Text(
          chuoi.daiNhat == 0
              ? '$ten chưa có chuỗi ngày nào. Mốc đầu nên ngắn — 3 hay 5 ngày.'
              : '$ten đang có chuỗi ${chuoi.hienTai} ngày, dài nhất từng đạt '
                  '${chuoi.daiNhat} ngày. Mốc nhỉnh hơn kỷ lục một chút là vừa sức.',
          style: AppType.ui(12.5, color: AppColor.muc, w: FontWeight.w600, height: 1.45),
        ),
        const SizedBox(height: 4),
        Text(
          'Ngày không có tiết trong thời khóa biểu không tính, và mỗi tuần $ten '
          'được một vé nghỉ — bận một tối cũng không đứt chuỗi.',
          style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.45),
        ),
        ],
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
        if (suaCu && _loai == LoaiPhanThuong.chuoi) ...[
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
