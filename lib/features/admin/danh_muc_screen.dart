import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/bo_cuc.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/mock/seed.dart';
import '../../data/models/models.dart';
import '../../data/repositories/supabase_repository.dart';
import '../shared/sua_giao_vien_sheet.dart';
import 'bai_hoc_admin.dart';
import 'sua_danh_muc.dart';

/// Danh mục dùng chung, ba tab: trường, môn học, thầy cô.
///
/// Thầy cô trên lớp gắn với trường — học sinh khai trường nào thì chỉ thấy
/// thầy cô trường đó. Thầy dạy thêm chỉ theo môn. Hàng chip tỉnh ở trên lọc
/// trường và thầy cô cho gọn; quản trị nào cũng thấy hết, tỉnh không phải
/// một tầng phân quyền.
class DanhMucScreen extends StatefulWidget {
  const DanhMucScreen({super.key});

  @override
  State<DanhMucScreen> createState() => _DanhMucScreenState();
}

class _DanhMucScreenState extends State<DanhMucScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this)
    ..addListener(() => setState(() {}));

  /// Tỉnh đang lọc; null là tất cả.
  String? _tinhId;

  /// Khối đang xem ở tab Bài học.
  int _khoi = 8;

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _them() {
    switch (_tab.index) {
      case 0:
        moSuaTruong(context, tinhMacDinh: _tinhId);
      case 1:
        moSuaMon(context);
      case 2:
        moSuaGiaoVien(context);
      default:
        moSuaBaiHoc(context, khoi: _khoi);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    // Tỉnh vừa bị xóa thì bỏ lọc, không để màn hình trống trơn mà không rõ vì sao.
    if (_tinhId != null && s.tinhTheoId(_tinhId) == null) _tinhId = null;

    final truong = s.truongTheoTinh(_tinhId);
    final gv = _locGv(s, _tinhId);
    final trong = s.tinh.isEmpty && s.truong.isEmpty && s.monHoc.isEmpty && s.giaoVien.isEmpty;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            LeTrang(
              tren: Gap.md,
              duoi: Gap.sm,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text('Danh mục', style: AppType.display(24))),
                  NutO(
                    icon: Icons.map_outlined,
                    tooltip: 'Tỉnh / thành phố',
                    onTap: () => _moTinh(context),
                  ),
                ],
              ),
            ),
            if (s.tinh.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                  children: [
                    _Chip(
                      nhan: 'Tất cả',
                      chon: _tinhId == null,
                      onTap: () => setState(() => _tinhId = null),
                    ),
                    for (final t in s.tinh)
                      _Chip(
                        nhan: t.ten,
                        chon: _tinhId == t.id,
                        onTap: () => setState(() => _tinhId = t.id),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: Gap.sm),
            TabBar(
              controller: _tab,
              labelStyle: AppType.ui(14, w: FontWeight.w700),
              unselectedLabelStyle: AppType.ui(14, w: FontWeight.w500),
              labelColor: AppColor.muc,
              unselectedLabelColor: AppColor.mucNhat,
              indicatorColor: AppColor.muc,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: AppColor.dongKe,
              tabs: [
                Tab(text: 'Trường (${truong.length})'),
                Tab(text: 'Môn (${s.monHoc.length})'),
                Tab(text: 'Thầy cô (${gv.length})'),
                const Tab(text: 'Bài học'),
              ],
            ),
            Expanded(
              child: trong
                  ? const _DanhMucTrong()
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _DsTruong(truong: truong),
                        _DsMon(mon: s.monHoc),
                        _DsGiaoVien(gv: gv),
                        DsBaiHoc(khoi: _khoi, onDoiKhoi: (k) => setState(() => _khoi = k)),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _them,
        backgroundColor: AppColor.muc,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(switch (_tab.index) {
          0 => 'Thêm trường',
          1 => 'Thêm môn',
          2 => 'Thêm thầy cô',
          _ => 'Thêm bài',
        }),
      ),
    );
  }

  /// Lọc thầy cô theo tỉnh: thầy trên lớp qua tỉnh của trường, thầy dạy thêm
  /// chung qua tỉnh ghi trên hàng. Thầy riêng của học sinh không có tỉnh nên
  /// chỉ hiện ở "Tất cả".
  List<GiaoVien> _locGv(AppState s, String? tinhId) {
    if (tinhId == null) return s.giaoVien;
    return s.giaoVien.where((g) {
      if (g.chuId != null) return false;
      if (g.loai == LoaiBaiTap.trenLop) {
        return s.truongTheoId(g.truongId)?.tinhId == tinhId;
      }
      return g.tinhId == tinhId;
    }).toList();
  }

  Future<void> _moTinh(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<AppState>(),
          child: const _DsTinhSheet(),
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.nhan, required this.chon, required this.onTap});
  final String nhan;
  final bool chon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Gap.sm),
      child: Material(
        color: chon ? AppColor.ink : AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.sm),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(R.sm),
              border: Border.all(color: chon ? AppColor.ink : AppColor.dongKe),
            ),
            child: Text(
              nhan,
              style: AppType.ui(12.5,
                  w: FontWeight.w600, color: chon ? Colors.white : AppColor.mucNhat),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ một dòng trong danh mục: ô nhỏ bên trái, tên, dòng phụ. Chạm để sửa.
class _The extends StatelessWidget {
  const _The({
    required this.o,
    required this.ten,
    this.phu,
    this.phai,
    required this.onTap,
  });

  final Widget o;
  final String ten;
  final String? phu;
  final Widget? phai;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.giayTrang,
      borderRadius: BorderRadius.circular(R.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(R.md),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: AppColor.dongKe),
          ),
          child: Row(
            children: [
              o,
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ten,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.ui(14, w: FontWeight.w700)),
                    if (phu != null && phu!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phu!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              ?phai,
              const SizedBox(width: Gap.xs),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColor.dongKeDam),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------- trường

class _DsTruong extends StatelessWidget {
  const _DsTruong({required this.truong});
  final List<Truong> truong;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (truong.isEmpty) {
      return const TrangTrong(
        icon: Icons.school_outlined,
        tieuDe: 'Chưa có trường nào',
        moTa: 'Thêm trường để học sinh chọn lúc đăng ký, rồi gắn thầy cô trên lớp vào từng trường.',
      );
    }
    return LayoutBuilder(builder: (context, rang) {
      final le = BoCuc.leCanhGiua(rang.maxWidth, BoCuc.le(context));
      return ListView(
      padding: EdgeInsets.fromLTRB(le, Gap.lg, le, 96),
      children: [
        LuoiThe(
          rongToiThieu: 340,
          khe: Gap.sm,
          children: [
            for (final t in truong) _theTruong(context, s, t),
          ],
        ),
      ],
    );
    });
  }

  Widget _theTruong(BuildContext context, AppState s, Truong t) {
        final soGv = s.giaoVien.where((g) => g.truongId == t.id).length;
        return _The(
          o: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColor.sky,
              borderRadius: BorderRadius.circular(R.sm),
            ),
            child: const Icon(Icons.school_rounded, size: 19, color: AppColor.muc),
          ),
          ten: t.ten,
          phu: [
            s.tenTinh(t.tinhId) ?? 'Chưa xếp tỉnh',
            soGv == 0 ? 'chưa có thầy cô' : '$soGv thầy cô',
          ].join(' · '),
          onTap: () => moSuaTruong(context, truong: t),
        );
  }
}

// ------------------------------------------------------------------------ môn

class _DsMon extends StatelessWidget {
  const _DsMon({required this.mon});
  final List<MonHoc> mon;

  @override
  Widget build(BuildContext context) {
    if (mon.isEmpty) {
      return const TrangTrong(
        icon: Icons.menu_book_outlined,
        tieuDe: 'Chưa có môn học nào',
        moTa: 'Không có môn thì học sinh không viết nổi báo cáo đầu tiên. Thêm tay, hoặc nạp bộ 12 môn cấp hai mẫu.',
        hanhDong: _NutNapMau(),
      );
    }
    return LayoutBuilder(builder: (context, rang) {
      final le = BoCuc.leCanhGiua(rang.maxWidth, BoCuc.le(context));
      return GridView.builder(
      padding: EdgeInsets.fromLTRB(le, Gap.lg, le, 96),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: Gap.sm,
        crossAxisSpacing: Gap.sm,
        mainAxisExtent: 68,
      ),
      itemCount: mon.length,
      itemBuilder: (_, i) => Material(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.md),
          onTap: () => moSuaMon(context, mon: mon[i]),
          child: Ink(
            padding: const EdgeInsets.all(Gap.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(R.md),
              border: Border.all(color: AppColor.dongKe),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColor.sky,
                    borderRadius: BorderRadius.circular(R.sm),
                  ),
                  child: Text(
                    mon[i].vietTat.length > 4 ? mon[i].vietTat.substring(0, 4) : mon[i].vietTat,
                    style: AppType.ui(11.5, w: FontWeight.w700, color: AppColor.muc),
                  ),
                ),
                const SizedBox(width: Gap.sm + 2),
                Expanded(
                  child: Text(
                    mon[i].ten,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.ui(13.5, w: FontWeight.w600, height: 1.25),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    });
  }
}

// -------------------------------------------------------------------- thầy cô

class _DsGiaoVien extends StatelessWidget {
  const _DsGiaoVien({required this.gv});
  final List<GiaoVien> gv;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (gv.isEmpty) {
      return const TrangTrong(
        icon: Icons.people_outline_rounded,
        tieuDe: 'Chưa có thầy cô nào',
        moTa: 'Thầy cô trên lớp gắn với trường và môn. Thầy dạy thêm chỉ cần môn — học sinh cũng tự thêm được thầy riêng của mình.',
      );
    }

    final trenLop = gv.where((g) => g.loai == LoaiBaiTap.trenLop).toList();
    final hocThem = gv.where((g) => g.loai == LoaiBaiTap.hocThem && !g.laRieng).toList();
    final rieng = gv.where((g) => g.laRieng).toList();

    Widget dau(Widget nhan) => Padding(
          padding: const EdgeInsets.only(bottom: Gap.md),
          child: Row(
            children: [
              nhan,
              const SizedBox(width: Gap.sm),
              Expanded(child: Container(height: 1, color: AppColor.dongKe)),
            ],
          ),
        );

    Widget the(GiaoVien g) {
      final phu = <String?>[
        s.tenMon(g.monId),
        if (g.loai == LoaiBaiTap.trenLop)
          s.tenTruong(g.truongId) ?? 'Mọi trường'
        else if (!g.laRieng)
          s.tenTinh(g.tinhId) ?? 'Mọi tỉnh',
        g.noiDay,
      ];
      return _The(
          o: AvatarChu(
            g.hoTen.replaceFirst(RegExp(r'^(Thầy|Cô) '), ''),
            kichThuoc: 40,
            mau: g.loai.mau,
            mauNen: g.loai.mauNen,
          ),
          ten: g.hoTen,
          phu: phu.whereType<String>().where((e) => e.isNotEmpty).join(' · '),
          phai: g.soDienThoai == null
              ? null
              : Text(
                  g.soDienThoai!,
                  style: AppType.numeric(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
                ),
          onTap: () => moSuaGiaoVien(context, giaoVien: g),
        );
    }
    Widget luoi(List<GiaoVien> ds) => LuoiThe(
          rongToiThieu: 340,
          khe: Gap.sm,
          children: [for (final g in ds) the(g)],
        );

    return LayoutBuilder(builder: (context, rang) {
      final le = BoCuc.leCanhGiua(rang.maxWidth, BoCuc.le(context));
      return ListView(
      padding: EdgeInsets.fromLTRB(le, Gap.lg, le, 96),
      children: [
        if (trenLop.isNotEmpty) ...[
          dau(const NhanLoai(LoaiBaiTap.trenLop, dayDu: true)),
          luoi(trenLop),
          const SizedBox(height: Gap.md + Gap.sm),
        ],
        if (hocThem.isNotEmpty) ...[
          dau(const NhanLoai(LoaiBaiTap.hocThem, dayDu: true)),
          luoi(hocThem),
          const SizedBox(height: Gap.md + Gap.sm),
        ],
        if (rieng.isNotEmpty) ...[
          dau(Container(
            padding: const EdgeInsets.symmetric(horizontal: Gap.sm + 2, vertical: 5),
            decoration: BoxDecoration(
              color: AppColor.sky,
              borderRadius: BorderRadius.circular(R.sm),
            ),
            child: Text(
              'Thầy riêng do học sinh tự thêm',
              style: AppType.ui(12, w: FontWeight.w600, color: AppColor.muc),
            ),
          )),
          luoi(rieng),
        ],
      ],
    );
    });
  }
}

// ----------------------------------------------------------------------- tỉnh

/// Danh sách tỉnh mở từ nút trên góc: chạm để sửa, nút dưới để thêm.
class _DsTinhSheet extends StatelessWidget {
  const _DsTinhSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .7),
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
                'Tỉnh / thành phố',
                eyebrow: s.tinh.isEmpty ? 'Chưa có tỉnh nào' : '${s.tinh.length} tỉnh',
              ),
            ),
            const SizedBox(height: Gap.md),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
                children: [
                  if (s.tinh.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Gap.md),
                      child: Text(
                        'Tỉnh chỉ để lọc trường và thầy cô cho gọn khi danh mục dài ra. Ít trường thì bỏ qua cũng được.',
                        style: AppType.ui(13, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.5),
                      ),
                    ),
                  for (final t in s.tinh)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.sm),
                      child: _The(
                        o: const Icon(Icons.location_city_rounded, size: 20, color: AppColor.mucNhat),
                        ten: t.ten,
                        phu: '${s.truongTheoTinh(t.id).length} trường',
                        onTap: () => moSuaTinh(context, tinh: t),
                      ),
                    ),
                  const SizedBox(height: Gap.sm),
                  FilledButton.icon(
                    onPressed: () => moSuaTinh(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thêm tỉnh'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ nạp mẫu

/// Project mới dựng thì danh mục trống trơn, mà không có môn học thì học sinh
/// không viết nổi báo cáo đầu tiên. Cho quản trị nạp một bộ chuẩn ngay từ
/// trong app, khỏi phải gõ tay từng môn.
class _DanhMucTrong extends StatelessWidget {
  const _DanhMucTrong();

  @override
  Widget build(BuildContext context) {
    return const TrangTrong(
      icon: Icons.library_books_outlined,
      tieuDe: 'Danh mục còn trống',
      moTa: 'Nạp bộ mẫu gồm 12 môn cấp hai, một trường và 8 thầy cô rồi sửa lại cho khớp, hoặc bấm nút Thêm ở góc để nhập tay từ đầu.',
      hanhDong: _NutNapMau(),
    );
  }
}

class _NutNapMau extends StatefulWidget {
  const _NutNapMau();

  @override
  State<_NutNapMau> createState() => _NutNapMauState();
}

class _NutNapMauState extends State<_NutNapMau> {
  bool _dangNap = false;

  Future<void> _nap() async {
    final s = context.read<AppState>();
    final repo = s.repo;
    if (repo is! SupabaseRepository) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chế độ xem thử đã có sẵn danh mục mẫu')),
      );
      return;
    }

    setState(() => _dangNap = true);
    try {
      final so = await repo.napDanhMucMau(
        tinh: Seed.tinh,
        truong: Seed.truong,
        mon: Seed.monHoc,
        // Thầy riêng của học sinh mẫu không có chủ trên dự án thật.
        gv: Seed.giaoVien.where((g) => !g.laRieng).toList(),
      );
      if (!mounted) return;
      await s.taiLaiDanhMuc();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã nạp $so mục vào danh mục')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không nạp được: $e')),
      );
    } finally {
      if (mounted) setState(() => _dangNap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _dangNap ? null : _nap,
      icon: const Icon(Icons.download_rounded, size: 18),
      label: Text(_dangNap ? 'Đang nạp…' : 'Nạp danh mục mẫu'),
    );
  }
}
