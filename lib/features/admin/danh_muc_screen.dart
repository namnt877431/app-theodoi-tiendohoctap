import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/app_state.dart';
import '../../data/mock/seed.dart';
import '../../data/models/models.dart';
import '../../data/repositories/firebase_repository.dart';

/// Danh mục dùng chung: môn học và thầy cô. Thầy cô tách hai nhóm vì báo cáo
/// học thêm phải gắn đúng người dạy thêm, không lẫn với giáo viên bộ môn.
class DanhMucScreen extends StatelessWidget {
  const DanhMucScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Môn học & thầy cô', style: AppType.display(24)),
                ),
              ),
              TabBar(
                labelStyle: AppType.ui(14, w: FontWeight.w700),
                unselectedLabelStyle: AppType.ui(14, w: FontWeight.w500),
                labelColor: AppColor.muc,
                unselectedLabelColor: AppColor.mucNhat,
                indicatorColor: AppColor.muc,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: AppColor.dongKe,
                tabs: [
                  Tab(text: 'Môn học (${s.monHoc.length})'),
                  Tab(text: 'Thầy cô (${s.giaoVien.length})'),
                ],
              ),
              Expanded(
                child: s.monHoc.isEmpty && s.giaoVien.isEmpty
                    ? const _DanhMucTrong()
                    : TabBarView(
                        children: [
                          _DsMon(mon: s.monHoc),
                          const _DsGiaoVien(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DsMon extends StatelessWidget {
  const _DsMon({required this.mon});
  final List<MonHoc> mon;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xxl),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Gap.sm,
        crossAxisSpacing: Gap.sm,
        mainAxisExtent: 68,
      ),
      itemCount: mon.length,
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: AppColor.giayTrang,
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
    );
  }
}

class _DsGiaoVien extends StatelessWidget {
  const _DsGiaoVien();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xxl),
      children: [
        for (final loai in LoaiBaiTap.values) ...[
          Row(
            children: [
              NhanLoai(loai, dayDu: true),
              const SizedBox(width: Gap.sm),
              Expanded(child: Container(height: 1, color: AppColor.dongKe)),
            ],
          ),
          const SizedBox(height: Gap.md),
          for (final g in s.gvTheoLoai(loai)) ...[
            Container(
              padding: const EdgeInsets.all(Gap.md),
              margin: const EdgeInsets.only(bottom: Gap.sm),
              decoration: BoxDecoration(
                color: AppColor.giayTrang,
                borderRadius: BorderRadius.circular(R.md),
                border: Border.all(color: AppColor.dongKe),
              ),
              child: Row(
                children: [
                  AvatarChu(
                    g.hoTen.replaceFirst(RegExp(r'^(Thầy|Cô) '), ''),
                    kichThuoc: 40,
                    mau: loai.mau,
                    mauNen: loai.mauNen,
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.hoTen, style: AppType.ui(14, w: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          [s.tenMon(g.monId), g.noiDay].where((e) => e != null).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (g.soDienThoai != null)
                    Text(
                      g.soDienThoai!,
                      style: AppType.numeric(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Gap.lg),
        ],
      ],
    );
  }
}

/// Project Firebase mới dựng thì hai bộ sưu tập danh mục còn trống, mà không
/// có môn học thì học sinh không viết nổi báo cáo đầu tiên. Cho quản trị nạp
/// một bộ chuẩn ngay từ trong app, khỏi phải gõ tay trong Console.
class _DanhMucTrong extends StatefulWidget {
  const _DanhMucTrong();

  @override
  State<_DanhMucTrong> createState() => _DanhMucTrongState();
}

class _DanhMucTrongState extends State<_DanhMucTrong> {
  bool _dangNap = false;

  Future<void> _nap() async {
    final s = context.read<AppState>();
    final repo = s.repo;
    if (repo is! FirebaseRepository) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chế độ xem thử đã có sẵn danh mục mẫu')),
      );
      return;
    }

    setState(() => _dangNap = true);
    try {
      final so = await repo.napDanhMucMau(Seed.monHoc, Seed.giaoVien);
      if (!mounted) return;
      await s.taiLai();
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
    return TrangTrong(
      icon: Icons.library_books_outlined,
      tieuDe: 'Danh mục còn trống',
      moTa: 'Chưa có môn học và thầy cô nào. Nạp bộ chuẩn gồm 12 môn cấp hai và 8 thầy cô mẫu, rồi sửa lại cho khớp trường mình.',
      hanhDong: FilledButton.icon(
        onPressed: _dangNap ? null : _nap,
        icon: const Icon(Icons.download_rounded, size: 18),
        label: Text(_dangNap ? 'Đang nạp…' : 'Nạp danh mục mẫu'),
      ),
    );
  }
}
