#!/usr/bin/env python3
"""Sinh supabase/09_bai_hoc_lop<N>.sql từ các file tools/bai_hoc/lop<N>/*.txt.

Mỗi file .txt là mục lục một cuốn sách (hoặc một phân môn), viết tay theo
dạng dễ soạn hơn JSON:

    mon: m_toan          # môn của những mục phía dưới (đổi được giữa chừng)
    lop: 8
    hk: 1                # học kì của các chương phía dưới (đổi được)
    # Chương 1: Đa thức  # bắt đầu một chương / chủ đề / unit
    - Bài 1: Đơn thức    # một mục học sinh chọn được
    > tóm tắt cho phụ huynh, nhiều dòng '>' nối lại bằng dấu cách
    ? câu hỏi để bố mẹ hỏi con → đáp án ngắn (phần sau mũi tên không bắt buộc)
    - Unit 1: Leisure time [unit]   # sách tiếng Anh: nở ra 8 tiết của unit
    ! grammar của unit               # chỉ dùng cho [unit]

Id của mỗi mục là chữ không dấu ghép từ lớp, môn và tên: `l8_toan_bai_1_don_thuc`.
Đổi tên mục thì id đổi theo và báo cáo cũ mất liên kết — muốn sửa chính tả
tên bài thì sửa trong Supabase (cột `ten`) chứ đừng sửa ở đây.

Chạy: python tools/bai_hoc/tao_sql.py
"""
import glob
import io
import os
import re
import sys
import unicodedata

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

GOC = os.path.dirname(os.path.abspath(__file__))
DICH = os.path.join(GOC, '..', '..', 'supabase')

# Tám tiết của một unit Tiếng Anh (Global Success) và việc của từng tiết.
TIET_UNIT = [
    ('Getting Started', 'Hội thoại mở đầu, làm quen từ vựng và ngữ pháp của unit'),
    ('A Closer Look 1', 'Từ vựng và phát âm'),
    ('A Closer Look 2', 'Ngữ pháp'),
    ('Communication', 'Giao tiếp: mẫu câu thường dùng theo chủ đề'),
    ('Skills 1', 'Đọc hiểu và nói'),
    ('Skills 2', 'Nghe và viết'),
    ('Looking Back', 'Ôn tập từ vựng, ngữ pháp cả unit'),
    ('Project', 'Dự án nhóm về chủ đề của unit'),
]


def khong_dau(s):
    s = s.replace('đ', 'd').replace('Đ', 'D')
    s = unicodedata.normalize('NFD', s)
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    s = re.sub(r'[^a-z0-9]+', '_', s.lower())
    return s[:80].strip('_')


def doc_file(duong_dan):
    """Trả về danh sách mục (dict) theo đúng thứ tự trong file."""
    mon = lop = None
    hk = 1
    chuong = None
    ds = []
    muc = None

    def chot():
        nonlocal muc
        if muc is None:
            return
        if muc.pop('unit', False):
            ten = muc['ten']
            tom_tat = muc['tom_tat']
            grammar = muc.pop('grammar', '')
            for tiet, viec in TIET_UNIT:
                mo_ta = viec
                if tiet == 'A Closer Look 2' and grammar:
                    mo_ta = 'Ngữ pháp: ' + grammar
                ds.append(dict(
                    mon=mon, lop=lop, hk=hk, chuong=ten,
                    ten=f'{tiet} ({ten})',
                    tom_tat=f'{mo_ta}. {tom_tat}'.strip(),
                    hoi=list(muc['hoi']),
                ))
        else:
            muc.pop('grammar', None)
            ds.append(muc)
        muc = None

    for so_dong, dong in enumerate(io.open(duong_dan, encoding='utf-8'), 1):
        dong = dong.rstrip('\n')
        if not dong.strip():
            continue
        m = re.match(r'^(mon|lop|hk):\s*(\S+)', dong)
        if m:
            chot()
            k, v = m.groups()
            if k == 'mon':
                mon = v
            elif k == 'lop':
                lop = int(v)
            else:
                hk = int(v)
            continue
        if dong.startswith('# '):
            chot()
            chuong = dong[2:].strip()
            continue
        if dong.startswith('- '):
            chot()
            ten = dong[2:].strip()
            unit = ten.endswith('[unit]')
            if unit:
                ten = ten[:-6].strip()
            if mon is None or lop is None:
                raise SystemExit(f'{duong_dan}:{so_dong}: thiếu mon:/lop: ở đầu file')
            muc = dict(mon=mon, lop=lop, hk=hk, chuong=chuong, ten=ten,
                       tom_tat='', hoi=[], unit=unit, grammar='')
            continue
        if muc is None:
            raise SystemExit(f'{duong_dan}:{so_dong}: dòng lạc ngoài mục: {dong!r}')
        if dong.startswith('> '):
            muc['tom_tat'] = (muc['tom_tat'] + ' ' + dong[2:].strip()).strip()
        elif dong.startswith('? '):
            muc['hoi'].append(dong[2:].strip())
        elif dong.startswith('! '):
            muc['grammar'] = dong[2:].strip()
        else:
            raise SystemExit(f'{duong_dan}:{so_dong}: không hiểu dòng: {dong!r}')
    chot()
    return ds


def gan_id(ds):
    """Id theo lớp + môn + tên; trùng thì thêm _2, _3 theo thứ tự xuất hiện."""
    dem = {}
    for m in ds:
        goc = f"l{m['lop']}_{m['mon'].removeprefix('m_')}_{khong_dau(m['ten'])}"
        n = dem.get(goc, 0) + 1
        dem[goc] = n
        m['id'] = goc if n == 1 else f'{goc}_{n}'


def thu_tu(ds):
    dem = {}
    for m in ds:
        k = (m['lop'], m['mon'])
        dem[k] = dem.get(k, 0) + 1
        m['thu_tu'] = dem[k]


def sql_chuoi(s):
    return 'null' if s is None else "'" + s.replace("'", "''") + "'"


def sql_mang(ds):
    if not ds:
        return "'{}'"
    return 'array[' + ', '.join(sql_chuoi(x) for x in ds) + ']::text[]'


def sinh(lop, ds):
    dong = []
    for m in ds:
        dong.append('  (%s, %s, %d, %d, %s, %d, %s, %s, %s)' % (
            sql_chuoi(m['id']), sql_chuoi(m['mon']), m['lop'], m['hk'],
            sql_chuoi(m['chuong']), m['thu_tu'], sql_chuoi(m['ten']),
            sql_chuoi(m['tom_tat'] or None), sql_mang(m['hoi'])))
    theo_mon = {}
    for m in ds:
        theo_mon[m['mon']] = theo_mon.get(m['mon'], 0) + 1
    tom_tat = ', '.join(f'{k} {v}' for k, v in sorted(theo_mon.items()))
    ids = ', '.join(sql_chuoi(m['id']) for m in ds)
    gia_tri = ',\n'.join(dong)
    return f"""-- Danh mục bài học lớp {lop} — bộ "Kết nối tri thức với cuộc sống".
-- FILE SINH TỰ ĐỘNG từ tools/bai_hoc/lop{lop}/*.txt bằng tools/bai_hoc/tao_sql.py,
-- đừng sửa tay ở đây. Chạy sau 01_bang.sql và 05_danh_muc.sql (cần các môn m_*).
-- Chạy lại được nhiều lần: mục đã có thì cập nhật tên, chương, thứ tự; tóm tắt
-- và câu hỏi chỉ cập nhật khi quản trị chưa sửa tay trong app (sua_tay = false).
--
-- {len(ds)} mục: {tom_tat}.

insert into bai_hoc (id, mon_id, lop, hoc_ki, chuong, thu_tu, ten, tom_tat, kiem_tra) values
{gia_tri}
on conflict (id) do update set
  mon_id   = excluded.mon_id,
  hoc_ki   = excluded.hoc_ki,
  chuong   = excluded.chuong,
  thu_tu   = excluded.thu_tu,
  ten      = excluded.ten,
  tom_tat  = case when bai_hoc.sua_tay then bai_hoc.tom_tat  else excluded.tom_tat  end,
  kiem_tra = case when bai_hoc.sua_tay then bai_hoc.kiem_tra else excluded.kiem_tra end;

-- Mục không còn trong danh mục (đổi tên, bỏ bớt) thì xóa; báo cáo đã gắn
-- vào mục đó chỉ mất liên kết (on delete set null), không mất bài.
delete from bai_hoc where lop = {lop} and id not in ({ids});
"""


def main():
    thu_muc = sorted(glob.glob(os.path.join(GOC, 'lop*')))
    if not thu_muc:
        raise SystemExit('Không thấy thư mục tools/bai_hoc/lop<N>')
    for tm in thu_muc:
        lop = int(os.path.basename(tm)[3:])
        ds = []
        for f in sorted(glob.glob(os.path.join(tm, '*.txt'))):
            ds.extend(doc_file(f))
        if not ds:
            continue
        for m in ds:
            if m['lop'] != lop:
                raise SystemExit(f"{m['ten']!r}: lop: {m['lop']} không khớp thư mục lop{lop}")
        thu_tu(ds)
        gan_id(ds)
        thieu = [m['ten'] for m in ds if not m['tom_tat']]
        dich = os.path.join(DICH, f'09_bai_hoc_lop{lop}.sql')
        io.open(dich, 'w', encoding='utf-8', newline='\n').write(sinh(lop, ds))
        print(f'Lớp {lop}: {len(ds)} mục → {os.path.relpath(dich)}'
              + (f' — {len(thieu)} mục chưa có tóm tắt' if thieu else ''))
        for t in thieu[:10]:
            print('   thiếu tóm tắt:', t)


if __name__ == '__main__':
    main()
