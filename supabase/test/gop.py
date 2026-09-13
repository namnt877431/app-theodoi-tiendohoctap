#!/usr/bin/env python3
"""Nối các file nguồn thành KIEM_THU.sql — một câu lệnh DO duy nhất.

Cả bộ test phải là một câu lệnh vì SQL Editor của Supabase tách script rồi gửi
qua connection pooler; chi tiết ở đầu 00_dau.sql.
"""
import io, os, sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

o = os.path.dirname(os.path.abspath(__file__))
doc = lambda t: io.open(os.path.join(o, t), encoding='utf-8').read()

DAU   = '00_dau.sql'
BANG  = ['01_nguoi_dung.sql', '02_lien_ket.sql', '03_bao_cao.sql',
         '04_tkb_nhac_nho.sql', '05_kho_anh.sql', '06_danh_muc.sql',
         '07_thong_bao.sql', '07b_phan_thuong.sql', '07c_diem_thi.sql']
DUOI  = ['08_chay.sql', '10_ma_moi.sql', '11_theo_lich.sql', '12_cuoi.sql']

# Bảng phép thử là một danh sách VALUES: dòng cuối không được có dấu phẩy.
bang = ''.join(doc(t) for t in BANG).rstrip()
if bang.endswith(','):
    bang = bang[:-1]

ra = doc(DAU) + bang + '\n\n' + ''.join(doc(t) for t in DUOI)

dich = os.path.join(o, 'KIEM_THU.sql')
io.open(dich, 'w', encoding='utf-8', newline='\n').write(ra)

so = ra.count("::uuid, '") + ra.count('  if ok then so_dat := so_dat + 1;')
print('Đã sinh KIEM_THU.sql — %d dòng, %d phép thử' % (ra.count('\n') + 1, so))
