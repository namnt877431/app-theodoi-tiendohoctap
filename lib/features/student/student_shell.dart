import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tokens.dart';
import '../../data/app_state.dart';
import '../parent/nhac_nho_screen.dart';
import '../shared/ho_so_screen.dart';
import '../shared/soan_bao_cao_screen.dart';
import '../shared/thoi_khoa_bieu_screen.dart';
import 'lich_su_bao_cao_screen.dart';
import 'trang_chu_hs_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final chuaDoc = context.select<AppState, int>((s) => s.soNhacNhoChuaDoc);

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          TrangChuHsScreen(),
          ThoiKhoaBieuScreen(),
          LichSuBaoCaoScreen(),
          NhacNhoScreen(),
          HoSoScreen(),
        ],
      ),
      floatingActionButton: _tab == 0 || _tab == 2
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SoanBaoCaoScreen()),
              ),
              backgroundColor: AppColor.muc,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.edit_rounded, size: 19),
              label: const Text('Viết báo cáo'),
            )
          : null,
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
            const NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article_rounded),
              label: 'Báo cáo',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: chuaDoc > 0,
                label: Text('$chuaDoc'),
                backgroundColor: AppColor.butDo,
                child: const Icon(Icons.campaign_outlined),
              ),
              selectedIcon: const Icon(Icons.campaign_rounded),
              label: 'Nhắc nhở',
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
