import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/app_state.dart';
import '../shared/ho_so_screen.dart';
import '../shared/thoi_khoa_bieu_screen.dart';
import 'bao_cao_ph_screen.dart';
import 'trang_chu_ph_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final chuaDoc = context.select<AppState, int>((s) => s.soNhacNhoChuaDoc);

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          TrangChuPhScreen(),
          ThoiKhoaBieuScreen(),
          BaoCaoPhScreen(),
          HoSoScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColor.dongKe)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today_rounded),
              label: 'Hôm nay',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Thời khóa biểu',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: chuaDoc > 0,
                backgroundColor: AppColor.butDo,
                child: const Icon(Icons.article_outlined),
              ),
              selectedIcon: const Icon(Icons.article_rounded),
              label: 'Báo cáo',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
