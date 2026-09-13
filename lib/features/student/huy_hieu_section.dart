import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/huy_hieu/huy_hieu.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/con_dau.dart';
import '../../data/app_state.dart';

/// Kệ con dấu trên trang chủ: đã đạt xếp trước, rồi tới cái gần đạt nhất —
/// để thứ đầu tiên đập vào mắt là thành quả, thứ thứ hai là mục tiêu gần.
class KeHuyHieu extends StatelessWidget {
  const KeHuyHieu({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ds = s.huyHieu;
    final daDat = ds.where((t) => t.dat).toList();
    final chuaDat = ds.where((t) => !t.dat).toList()
      ..sort((a, b) => b.tiLe.compareTo(a.tiLe));
    final hien = [...daDat, ...chuaDat.take(daDat.isEmpty ? 4 : 3)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TieuDeMuc(
          'Con dấu khen',
          eyebrow: daDat.isEmpty
              ? 'Chưa có con dấu nào'
              : '${daDat.length}/${ds.length} con dấu',
          hanhDong: TextButton(
            onPressed: () => moTatCaHuyHieu(context),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: const Text('Xem tất cả'),
          ),
        ),
        const SizedBox(height: Gap.md),
        Container(
          padding: const EdgeInsets.symmetric(vertical: Gap.md),
          decoration: BoxDecoration(
            color: AppColor.giayTrang,
            borderRadius: BorderRadius.circular(R.lg),
            border: Border.all(color: AppColor.dongKe),
          ),
          child: SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Gap.md),
              itemCount: hien.length,
              separatorBuilder: (_, _) => const SizedBox(width: Gap.xs),
              itemBuilder: (_, i) => ConDau(
                hien[i],
                kichThuoc: 66,
                coTienDo: true,
                onTap: () => moTatCaHuyHieu(context, chon: hien[i].huyHieu),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Toàn bộ con dấu theo nhóm. Chạm một cái để đọc cần làm gì.
Future<void> moTatCaHuyHieu(BuildContext context, {HuyHieu? chon}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppState>(),
      child: _TatCaHuyHieu(chonBanDau: chon),
    ),
  );
}

class _TatCaHuyHieu extends StatefulWidget {
  const _TatCaHuyHieu({this.chonBanDau});
  final HuyHieu? chonBanDau;

  @override
  State<_TatCaHuyHieu> createState() => _TatCaHuyHieuState();
}

class _TatCaHuyHieuState extends State<_TatCaHuyHieu> {
  late HuyHieu? _chon = widget.chonBanDau;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ds = s.huyHieu;
    final daDat = ds.where((t) => t.dat).length;
    final tienDoChon = _chon == null
        ? null
        : ds.firstWhere((t) => t.huyHieu.id == _chon!.id);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
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
              child: TieuDeMuc('Con dấu khen', eyebrow: '$daDat/${ds.length} đã đạt'),
            ),
            const SizedBox(height: Gap.md),
            // Ô giải thích con dấu đang chọn — nằm cố định phía trên lưới để
            // chạm cái nào cũng đọc được ngay, không phải cuộn.
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: tienDoChon == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
                      child: _GiaiThich(tienDoChon),
                    ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xl),
                children: [
                  for (final nhom in NhomHuyHieu.values) ...[
                    Eyebrow(nhom.ten),
                    const SizedBox(height: 2),
                    Text(
                      nhom.moTa,
                      style: AppType.ui(12, color: AppColor.mucNhat, w: FontWeight.w400),
                    ),
                    const SizedBox(height: Gap.md),
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.md,
                      children: [
                        for (final t in ds.where((t) => t.huyHieu.nhom == nhom))
                          ConDau(
                            t,
                            kichThuoc: 68,
                            coTienDo: true,
                            onTap: () => setState(() => _chon = t.huyHieu),
                          ),
                      ],
                    ),
                    const SizedBox(height: Gap.xl),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiaiThich extends StatelessWidget {
  const _GiaiThich(this.t);
  final TienDoHuyHieu t;

  @override
  Widget build(BuildContext context) {
    final mau = ConDau.mauCua(t.huyHieu);
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: t.dat ? ConDau.nenCua(t.huyHieu) : AppColor.skySoft,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: t.dat ? mau.withValues(alpha: .3) : AppColor.dongKe),
      ),
      child: Row(
        children: [
          Icon(t.huyHieu.icon, size: 22, color: t.dat ? mau : AppColor.mucNhat),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.huyHieu.ten,
                    style: AppType.ui(14, w: FontWeight.w700, color: t.dat ? mau : AppColor.ink)),
                const SizedBox(height: 2),
                Text(
                  t.dat ? 'Đã đạt — ${t.huyHieu.moTa.toLowerCase()}.' : '${t.huyHieu.moTa}. Đang ở ${t.nhanTienDo}.',
                  style: AppType.ui(12.5, color: AppColor.mucNhat, w: FontWeight.w400, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
