-- =============================================================================
-- 34 tỉnh, thành phố — theo Nghị quyết 202/2025/QH15, hiệu lực 1/7/2025.
--
-- 6 thành phố trực thuộc trung ương và 28 tỉnh. Id giữ dạng chữ để mở bảng
-- ra vẫn đọc được; `t_hn` trùng với id trong 05_danh_muc.sql nên dữ liệu đã
-- gắn Hà Nội không phải đổi gì.
--
-- Chạy được nhiều lần: có rồi thì chỉ cập nhật tên.
-- =============================================================================

insert into tinh (id, ten) values
  -- Thành phố trực thuộc trung ương
  ('t_hn',           'Hà Nội'),
  ('t_hai_phong',    'Hải Phòng'),
  ('t_hue',          'Huế'),
  ('t_da_nang',      'Đà Nẵng'),
  ('t_hcm',          'TP. Hồ Chí Minh'),
  ('t_can_tho',      'Cần Thơ'),
  -- Tỉnh
  ('t_an_giang',     'An Giang'),
  ('t_bac_ninh',     'Bắc Ninh'),
  ('t_ca_mau',       'Cà Mau'),
  ('t_cao_bang',     'Cao Bằng'),
  ('t_dak_lak',      'Đắk Lắk'),
  ('t_dien_bien',    'Điện Biên'),
  ('t_dong_nai',     'Đồng Nai'),
  ('t_dong_thap',    'Đồng Tháp'),
  ('t_gia_lai',      'Gia Lai'),
  ('t_ha_tinh',      'Hà Tĩnh'),
  ('t_hung_yen',     'Hưng Yên'),
  ('t_khanh_hoa',    'Khánh Hòa'),
  ('t_lai_chau',     'Lai Châu'),
  ('t_lam_dong',     'Lâm Đồng'),
  ('t_lang_son',     'Lạng Sơn'),
  ('t_lao_cai',      'Lào Cai'),
  ('t_nghe_an',      'Nghệ An'),
  ('t_ninh_binh',    'Ninh Bình'),
  ('t_phu_tho',      'Phú Thọ'),
  ('t_quang_ngai',   'Quảng Ngãi'),
  ('t_quang_ninh',   'Quảng Ninh'),
  ('t_quang_tri',    'Quảng Trị'),
  ('t_son_la',       'Sơn La'),
  ('t_tay_ninh',     'Tây Ninh'),
  ('t_thai_nguyen',  'Thái Nguyên'),
  ('t_thanh_hoa',    'Thanh Hóa'),
  ('t_tuyen_quang',  'Tuyên Quang'),
  ('t_vinh_long',    'Vĩnh Long')
on conflict (id) do update set ten = excluded.ten;
