import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../widgets/common.dart';
import 'bo_cuc.dart';

/// Một mục trên thanh điều hướng.
class DiemDen {
  const DiemDen({
    required this.icon,
    required this.iconChon,
    required this.nhan,
    this.huyHieu = 0,
  });

  final IconData icon;
  final IconData iconChon;
  final String nhan;

  /// Số chưa đọc; 0 là không hiện chấm.
  final int huyHieu;
}

/// Nút hành động chính của vai trò (học sinh: viết báo cáo).
class HanhDongChinh {
  const HanhDongChinh({required this.icon, required this.nhan, required this.onTap});
  final IconData icon;
  final String nhan;
  final VoidCallback onTap;
}

/// Khung của ba vai trò: các màn xếp chồng, đổi bằng thanh điều hướng.
///
/// Điện thoại: thanh nằm dưới, hành động chính là nút nổi. Màn rộng: thanh
/// đứng bên trái — chỉ biểu tượng khi cửa sổ vừa, đủ chữ và tên người dùng
/// khi cửa sổ rộng — hành động chính thành nút to đầu thanh, nội dung dùng
/// hết phần còn lại.
class KhungDieuHuong extends StatelessWidget {
  const KhungDieuHuong({
    super.key,
    required this.tab,
    required this.onChon,
    required this.diemDen,
    required this.man,
    this.hanhDong,
    this.hienHanhDongO = const {},
  });

  final int tab;
  final ValueChanged<int> onChon;
  final List<DiemDen> diemDen;
  final List<Widget> man;
  final HanhDongChinh? hanhDong;

  /// Trên điện thoại nút nổi chỉ hiện ở những tab này (rỗng: mọi tab).
  final Set<int> hienHanhDongO;

  @override
  Widget build(BuildContext context) {
    final coMan = BoCuc.coMan(context);
    final than = IndexedStack(index: tab, children: man);

    if (coMan == CoMan.hep) {
      final hd = hanhDong;
      final hien = hd != null && (hienHanhDongO.isEmpty || hienHanhDongO.contains(tab));
      return Scaffold(
        body: than,
        floatingActionButton: hien
            ? FloatingActionButton.extended(
                onPressed: hd.onTap,
                backgroundColor: AppColor.muc,
                foregroundColor: Colors.white,
                elevation: 2,
                icon: Icon(hd.icon, size: 19),
                label: Text(hd.nhan),
              )
            : null,
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColor.dongKe)),
          ),
          child: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: onChon,
            destinations: [
              for (final d in diemDen)
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: d.huyHieu > 0,
                    label: Text('${d.huyHieu}'),
                    backgroundColor: AppColor.butDo,
                    child: Icon(d.icon),
                  ),
                  selectedIcon: Icon(d.iconChon),
                  label: d.nhan,
                ),
            ],
          ),
        ),
      );
    }

    final dayDu = MediaQuery.sizeOf(context).width >= BoCuc.thanhBenDayDu;
    return Scaffold(
      body: Row(
        children: [
          _ThanhBen(
            tab: tab,
            onChon: onChon,
            diemDen: diemDen,
            hanhDong: hanhDong,
            dayDu: dayDu,
          ),
          Expanded(child: than),
        ],
      ),
    );
  }
}

class _ThanhBen extends StatelessWidget {
  const _ThanhBen({
    required this.tab,
    required this.onChon,
    required this.diemDen,
    required this.hanhDong,
    required this.dayDu,
  });

  final int tab;
  final ValueChanged<int> onChon;
  final List<DiemDen> diemDen;
  final HanhDongChinh? hanhDong;
  final bool dayDu;

  @override
  Widget build(BuildContext context) {
    final nd = context.select<AppState, ({String ten, String vai})?>(
      (s) => s.nguoiDung == null ? null : (ten: s.nguoiDung!.hoTen, vai: s.nguoiDung!.vaiTro.nhan),
    );
    final hd = hanhDong;

    return Container(
      width: dayDu ? 236 : 84,
      decoration: const BoxDecoration(
        color: AppColor.giayTrang,
        border: Border(right: BorderSide(color: AppColor.dongKe)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(dayDu ? Gap.xl : 0, Gap.xl, dayDu ? Gap.xl : 0, Gap.lg),
              child: dayDu
                  ? Text('Sổ liên lạc', style: AppType.display(22, color: AppColor.ink))
                  : const Center(
                      child: Icon(Icons.auto_stories_rounded, color: AppColor.muc, size: 26),
                    ),
            ),
            if (nd != null)
              Padding(
                padding: EdgeInsets.fromLTRB(dayDu ? Gap.xl : 0, 0, dayDu ? Gap.xl : 0, Gap.lg),
                child: dayDu
                    ? Row(
                        children: [
                          AvatarChu(nd.ten, kichThuoc: 36),
                          const SizedBox(width: Gap.sm + 2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nd.ten,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.ui(13.5, w: FontWeight.w700),
                                ),
                                Text(
                                  nd.vai,
                                  style: AppType.ui(11.5, color: AppColor.mucNhat, w: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Center(child: AvatarChu(nd.ten, kichThuoc: 36)),
              ),
            if (hd != null)
              Padding(
                padding: EdgeInsets.fromLTRB(dayDu ? Gap.lg : Gap.md, 0, dayDu ? Gap.lg : Gap.md, Gap.md),
                child: dayDu
                    ? FilledButton.icon(
                        onPressed: hd.onTap,
                        icon: Icon(hd.icon, size: 18),
                        label: Text(hd.nhan),
                      )
                    : Tooltip(
                        message: hd.nhan,
                        child: FilledButton(
                          onPressed: hd.onTap,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: Gap.md),
                          ),
                          child: Icon(hd.icon, size: 20),
                        ),
                      ),
              ),
            const SizedBox(height: Gap.xs),
            for (var i = 0; i < diemDen.length; i++)
              _MucThanhBen(
                d: diemDen[i],
                chon: i == tab,
                dayDu: dayDu,
                onTap: () => onChon(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _MucThanhBen extends StatelessWidget {
  const _MucThanhBen({
    required this.d,
    required this.chon,
    required this.dayDu,
    required this.onTap,
  });

  final DiemDen d;
  final bool chon;
  final bool dayDu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mau = chon ? AppColor.muc : AppColor.mucNhat;
    final icon = Badge(
      isLabelVisible: d.huyHieu > 0,
      label: Text('${d.huyHieu}'),
      backgroundColor: AppColor.butDo,
      child: Icon(chon ? d.iconChon : d.icon, size: 22, color: mau),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dayDu ? Gap.md : Gap.sm, vertical: 2),
      child: Material(
        color: chon ? AppColor.sky : Colors.transparent,
        borderRadius: BorderRadius.circular(R.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(R.md),
          onTap: onTap,
          child: dayDu
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm + 3),
                  child: Row(
                    children: [
                      icon,
                      const SizedBox(width: Gap.md),
                      Expanded(
                        child: Text(
                          d.nhan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.ui(14, w: chon ? FontWeight.w700 : FontWeight.w500, color: mau),
                        ),
                      ),
                    ],
                  ),
                )
              : Tooltip(
                  message: d.nhan,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Gap.sm + 2),
                    child: Column(
                      children: [
                        icon,
                        const SizedBox(height: 3),
                        Text(
                          d.nhan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppType.ui(10, w: chon ? FontWeight.w700 : FontWeight.w500, color: mau),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
