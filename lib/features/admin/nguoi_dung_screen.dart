import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/models/models.dart';
import 'lien_ket_sheet.dart';

/// Quản lý tài khoản: lọc theo vai trò, khóa/mở, và liên kết phụ huynh với con.
class NguoiDungScreen extends StatefulWidget {
  const NguoiDungScreen({super.key});

  @override
  State<NguoiDungScreen> createState() => _NguoiDungScreenState();
}

class _NguoiDungScreenState extends State<NguoiDungScreen> {
  List<NguoiDung> _ds = const [];
  VaiTro? _loc;
  String _timKiem = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tai());
  }

  Future<void> _tai() async {
    final ds = await context.read<AppState>().repo.danhSachNguoiDung();
    if (mounted) setState(() => _ds = ds);
  }

  Future<void> _doiKhoa(NguoiDung nd) async {
    await context.read<AppState>().repo.luuNguoiDung(nd.copyWith(hoatDong: !nd.hoatDong));
    await _tai();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(nd.hoatDong ? 'Đã khóa ${nd.hoTen}' : 'Đã mở khóa ${nd.hoTen}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    var ds = _ds.where((n) => _loc == null || n.vaiTro == _loc);
    if (_timKiem.isNotEmpty) {
      final q = _timKiem.toLowerCase();
      ds = ds.where((n) =>
          n.hoTen.toLowerCase().contains(q) ||
          (n.email ?? '').toLowerCase().contains(q) ||
          (n.lop ?? '').toLowerCase().contains(q));
    }
    final ketQua = ds.toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Người dùng', style: AppType.display(24)),
                  const SizedBox(height: Gap.md),
                  TextField(
                    onChanged: (v) => setState(() => _timKiem = v),
                    style: AppType.ui(14.5, w: FontWeight.w400),
                    decoration: const InputDecoration(
                      hintText: 'Tìm theo tên, email hoặc lớp',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: Gap.md),
                  Row(
                    children: [
                      _LocChip(
                        nhan: 'Tất cả',
                        chon: _loc == null,
                        onTap: () => setState(() => _loc = null),
                      ),
                      for (final v in VaiTro.values)
                        _LocChip(
                          nhan: v.nhan,
                          chon: _loc == v,
                          onTap: () => setState(() => _loc = v),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ketQua.isEmpty
                  ? const TrangTrong(
                      icon: Icons.person_search_rounded,
                      tieuDe: 'Không tìm thấy tài khoản nào',
                      moTa: 'Thử đổi từ khóa hoặc bỏ bộ lọc vai trò.',
                    )
                  : RefreshIndicator(
                      color: AppColor.muc,
                      onRefresh: _tai,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xxl),
                        itemCount: ketQua.length,
                        separatorBuilder: (_, _) => const SizedBox(height: Gap.sm + 2),
                        itemBuilder: (_, i) => _TheNguoiDung(
                          nd: ketQua[i],
                          tatCa: _ds,
                          onKhoa: () => _doiKhoa(ketQua[i]),
                          onLienKet: () async {
                            await moLienKet(context, ketQua[i]);
                            await _tai();
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocChip extends StatelessWidget {
  const _LocChip({required this.nhan, required this.chon, required this.onTap});
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

class _TheNguoiDung extends StatelessWidget {
  const _TheNguoiDung({
    required this.nd,
    required this.tatCa,
    required this.onKhoa,
    required this.onLienKet,
  });

  final NguoiDung nd;
  final List<NguoiDung> tatCa;
  final VoidCallback onKhoa;
  final VoidCallback onLienKet;

  @override
  Widget build(BuildContext context) {
    final phuHuynhCua = nd.vaiTro == VaiTro.hocSinh
        ? tatCa.where((n) => n.conIds.contains(nd.id)).toList()
        : const <NguoiDung>[];

    final phu = switch (nd.vaiTro) {
      VaiTro.hocSinh => 'Lớp ${nd.lop} · ${nd.truong}',
      VaiTro.phuHuynh => '${nd.conIds.length} con đang theo dõi',
      VaiTro.quanTri => nd.email ?? 'Quản trị viên',
    };

    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColor.giayTrang,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: AppColor.dongKe),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Opacity(
                opacity: nd.hoatDong ? 1 : .45,
                child: AvatarChu(nd.hoTen, kichThuoc: 44),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nd.hoTen,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.ui(14.5, w: FontWeight.w700),
                          ),
                        ),
                        if (!nd.hoatDong) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock_rounded, size: 13, color: AppColor.butDo),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phu,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.ui(12, color: AppColor.mucNhat, w: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColor.sky,
                  borderRadius: BorderRadius.circular(R.sm),
                ),
                child: Text(nd.vaiTro.nhan,
                    style: AppType.ui(10.5, w: FontWeight.w700, color: AppColor.muc)),
              ),
            ],
          ),
          if (nd.vaiTro == VaiTro.hocSinh && phuHuynhCua.isNotEmpty) ...[
            const SizedBox(height: Gap.sm + 2),
            Row(
              children: [
                const SizedBox(width: 2),
                const Icon(Icons.link_rounded, size: 13, color: AppColor.mucNhat),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    phuHuynhCua.map((p) => p.hoTen).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Gap.sm + 2),
            child: Divider(),
          ),
          Row(
            children: [
              if (nd.vaiTro == VaiTro.phuHuynh)
                Expanded(
                  child: TextButton.icon(
                    onPressed: onLienKet,
                    icon: const Icon(Icons.link_rounded, size: 17),
                    label: const Text('Liên kết con'),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                )
              else
                const Spacer(),
              TextButton.icon(
                onPressed: onKhoa,
                icon: Icon(
                  nd.hoatDong ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                  size: 17,
                ),
                label: Text(nd.hoatDong ? 'Khóa' : 'Mở khóa'),
                style: TextButton.styleFrom(
                  foregroundColor: nd.hoatDong ? AppColor.butDo : AppColor.xong,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
