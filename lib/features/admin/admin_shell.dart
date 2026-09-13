import 'package:flutter/material.dart';

import '../../core/layout/khung_dieu_huong.dart';
import '../shared/ho_so_screen.dart';
import 'danh_muc_screen.dart';
import 'nguoi_dung_screen.dart';
import 'tong_quan_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return KhungDieuHuong(
      tab: _tab,
      onChon: (i) => setState(() => _tab = i),
      diemDen: const [
        DiemDen(icon: Icons.insights_outlined, iconChon: Icons.insights_rounded, nhan: 'Tổng quan'),
        DiemDen(icon: Icons.group_outlined, iconChon: Icons.group_rounded, nhan: 'Người dùng'),
        DiemDen(icon: Icons.menu_book_outlined, iconChon: Icons.menu_book_rounded, nhan: 'Danh mục'),
        DiemDen(icon: Icons.person_outline_rounded, iconChon: Icons.person_rounded, nhan: 'Tài khoản'),
      ],
      man: const [
        TongQuanScreen(),
        NguoiDungScreen(),
        DanhMucScreen(),
        HoSoScreen(),
      ],
    );
  }
}
