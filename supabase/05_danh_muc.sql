-- =============================================================================
-- Danh mục mẫu: 1 tỉnh, 1 trường, 12 môn cấp hai và 8 thầy cô.
--
-- Không có môn nào thì học sinh không viết nổi báo cáo đầu tiên, nên nạp bộ này
-- rồi sửa lại cho khớp trường mình. Trong app cũng có nút "Nạp danh mục mẫu"
-- ở màn Danh mục làm đúng việc này.
--
-- Chạy được nhiều lần, không nhân bản dữ liệu.
-- =============================================================================

insert into tinh (id, ten) values ('t_hn', 'Hà Nội')
on conflict (id) do update set ten = excluded.ten;

insert into truong (id, ten, tinh_id) values ('tr_nguyen_trai', 'THCS Nguyễn Trãi', 't_hn')
on conflict (id) do update set ten = excluded.ten, tinh_id = excluded.tinh_id;

insert into mon_hoc (id, ten, viet_tat) values
  ('m_toan', 'Toán',                  'Toán'),
  ('m_van',  'Ngữ văn',               'Văn'),
  ('m_anh',  'Tiếng Anh',             'Anh'),
  ('m_ly',   'Vật lí',                'Lí'),
  ('m_hoa',  'Hóa học',               'Hóa'),
  ('m_sinh', 'Sinh học',              'Sinh'),
  ('m_su',   'Lịch sử',               'Sử'),
  ('m_dia',  'Địa lí',                'Địa'),
  ('m_gdcd', 'Giáo dục công dân',     'GDCD'),
  ('m_tin',  'Tin học',               'Tin'),
  ('m_td',   'Thể dục',               'TD'),
  ('m_cn',   'Công nghệ',             'CN')
on conflict (id) do update set ten = excluded.ten, viet_tat = excluded.viet_tat;

insert into giao_vien (id, ho_ten, mon_id, loai, noi_day, so_dien_thoai, truong_id, tinh_id) values
  ('gv_lan',     'Cô Nguyễn Thị Lan',  'm_toan', 'trenLop', 'Lớp 9A2', null, 'tr_nguyen_trai', null),
  ('gv_hoa',     'Cô Trần Thanh Hòa',  'm_van',  'trenLop', 'Lớp 9A2', null, 'tr_nguyen_trai', null),
  ('gv_minh',    'Thầy Lê Quang Minh', 'm_anh',  'trenLop', 'Lớp 9A2', null, 'tr_nguyen_trai', null),
  ('gv_tuan',    'Thầy Phạm Anh Tuấn', 'm_ly',   'trenLop', 'Lớp 9A2', null, 'tr_nguyen_trai', null),
  ('gv_thuy',    'Cô Đỗ Bích Thủy',    'm_hoa',  'trenLop', 'Lớp 9A2', null, 'tr_nguyen_trai', null),
  ('gv_ht_son',  'Thầy Vũ Ngọc Sơn',   'm_toan', 'hocThem', 'Trung tâm Trí Đức',        '0912 334 556', null, 't_hn'),
  ('gv_ht_mai',  'Cô Hoàng Thị Mai',   'm_anh',  'hocThem', 'Nhà cô — ngõ 128 Kim Giang', '0983 771 202', null, 't_hn'),
  ('gv_ht_dung', 'Thầy Bùi Tiến Dũng', 'm_ly',   'hocThem', 'Trung tâm Trí Đức',        '0977 240 118', null, 't_hn')
on conflict (id) do update
  set ho_ten = excluded.ho_ten,
      mon_id = excluded.mon_id,
      loai   = excluded.loai,
      noi_day = excluded.noi_day,
      so_dien_thoai = excluded.so_dien_thoai,
      truong_id = excluded.truong_id,
      tinh_id = excluded.tinh_id;
