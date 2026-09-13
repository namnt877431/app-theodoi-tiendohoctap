-- =============================================================================
-- Sổ liên lạc — kiểm thử phân quyền
--
-- Cả bộ là MỘT câu lệnh DO. Không phải để gọn, mà vì bắt buộc: SQL Editor của
-- Supabase tách script thành từng câu lệnh rồi gửi qua connection pooler. Mở
-- `begin` tường minh thì mọi thứ chưa commit nằm lại trên một kết nối, còn câu
-- lệnh kế tiếp rơi sang kết nối khác và không nhìn thấy gì. Một câu lệnh thì
-- không tách được.
--
-- Kết thúc bằng ngoại lệ cố ý — đó là cách duy nhất để hoàn tác dữ liệu thử
-- khi không được phép dùng rollback. Thấy khung đỏ là bình thường; đọc nội
-- dung của nó mới biết đạt hay trượt.
-- =============================================================================

do $ktr$
declare
  chu    text := current_user;
  t      record;
  n      bigint;
  ok     boolean;
  ghi    text;
  bao    text := '';
  so_dat int := 0;
  so_tru int := 0;
  v_ma   ma_moi;
  v_hs   nguoi_dung;
begin

  -- ------------------------------------------------------------------- nền
  -- Tỉnh và trường phải có trước, vì trigger đăng ký tra `truong_id` ở đó.

  insert into tinh (id, ten) values ('t_thu', 'Tỉnh Thử')
    on conflict (id) do nothing;
  insert into truong (id, ten, tinh_id) values ('tr_thu', 'THCS Thử', 't_thu')
    on conflict (id) do nothing;

  -- Năm nhân vật. Hồ sơ do trigger tao_ho_so_sau_dang_ky dựng từ metadata,
  -- nên phần này kiểm luôn cả cái trigger đó: HS1 chọn trường có thật, HS2
  -- gửi lên một id trường không tồn tại.

  insert into auth.users (id, email, raw_user_meta_data) values
    ('11111111-1111-1111-1111-111111111111', 'ph1@vi.du',
     '{"ho_ten":"Phụ Huynh Một","vai_tro":"phuHuynh"}'),
    ('22222222-2222-2222-2222-222222222222', 'ph2@vi.du',
     '{"ho_ten":"Phụ Huynh Hai","vai_tro":"phuHuynh"}'),
    ('33333333-3333-3333-3333-333333333333', 'hs1@vi.du',
     '{"ho_ten":"Học Sinh Một","vai_tro":"hocSinh","lop":"9A2","truong_id":"tr_thu"}'),
    ('44444444-4444-4444-4444-444444444444', 'hs2@vi.du',
     '{"ho_ten":"Học Sinh Hai","vai_tro":"hocSinh","lop":"8A4","truong_id":"khong-co"}'),
    ('55555555-5555-5555-5555-555555555555', 'qt@vi.du',
     '{"ho_ten":"Quản Trị","vai_tro":"quanTri"}');

  if (select count(*) from nguoi_dung) <> 5 then
    raise exception 'Trigger đăng ký không dựng đủ 5 hồ sơ';
  end if;
  if (select ho_ten from nguoi_dung
       where id = '33333333-3333-3333-3333-333333333333') <> 'Học Sinh Một' then
    raise exception 'Trigger đăng ký không đọc đúng ho_ten từ metadata';
  end if;
  if (select lop from nguoi_dung
       where id = '33333333-3333-3333-3333-333333333333') <> '9A2' then
    raise exception 'Trigger đăng ký không đọc đúng lop từ metadata';
  end if;
  if (select vai_tro from nguoi_dung
       where id = '55555555-5555-5555-5555-555555555555') <> 'hocSinh' then
    raise exception 'Trigger đăng ký không kẹp vai trò quanTri gửi từ client';
  end if;
  if (select truong_id from nguoi_dung
       where id = '33333333-3333-3333-3333-333333333333') is distinct from 'tr_thu' then
    raise exception 'Trigger đăng ký không gắn truong_id từ metadata';
  end if;
  if (select truong from nguoi_dung
       where id = '33333333-3333-3333-3333-333333333333') is distinct from 'THCS Thử' then
    raise exception 'Trigger đăng ký không ghi tên trường vào cột chữ';
  end if;
  if (select truong_id from nguoi_dung
       where id = '44444444-4444-4444-4444-444444444444') is not null then
    raise exception 'Trigger đăng ký nhận cả id trường không tồn tại';
  end if;

  -- Quản trị phải phong bằng tay, đúng như hướng dẫn trong README.
  update nguoi_dung set vai_tro = 'quanTri'
   where id = '55555555-5555-5555-5555-555555555555';

  insert into lien_ket (phu_huynh_id, hoc_sinh_id)
  values ('11111111-1111-1111-1111-111111111111',
          '33333333-3333-3333-3333-333333333333');

  insert into mon_hoc (id, ten, viet_tat) values ('m_toan', 'Toán', 'Toán')
    on conflict (id) do nothing;

  -- Hai bài trong danh mục để thử chọn bài và tóm tắt.
  insert into bai_hoc (id, mon_id, lop, hoc_ki, chuong, thu_tu, ten, tom_tat, kiem_tra) values
    ('bh_thu_1', 'm_toan', 8, 1, 'Chương thử', 1, 'Bài 1 thử', 'Tóm tắt gốc', array['Hỏi 1 → đáp 1']),
    ('bh_thu_2', 'm_toan', 8, 1, 'Chương thử', 2, 'Bài 2 thử', null, '{}');

  -- Một thầy cô chung của trường, một thầy dạy thêm riêng của HS1.
  insert into giao_vien (id, ho_ten, mon_id, loai, truong_id, chu_id) values
    ('gv_chung',     'Cô Chung',   'm_toan', 'trenLop', 'tr_thu', null),
    ('gv_rieng_hs1', 'Thầy Riêng', 'm_toan', 'hocThem', null,
     '33333333-3333-3333-3333-333333333333');

  insert into bao_cao (id, hoc_sinh_id, ngay, loai, mon_id, noi_dung, trang_thai, anh)
  values
    ('aaaaaaaa-0000-0000-0000-000000000001',
     '33333333-3333-3333-3333-333333333333', current_date, 'trenLop', 'm_toan',
     'Bài 12 trang 47', 'dangLam',
     array['33333333-3333-3333-3333-333333333333/anh1.jpg']),
    ('aaaaaaaa-0000-0000-0000-000000000002',
     '44444444-4444-4444-4444-444444444444', current_date, 'trenLop', 'm_toan',
     'Bài của bạn khác', 'xong', '{}');

  insert into tiet_hoc (id, hoc_sinh_id, thu, tiet, buoi, mon_id, loai) values
    ('bbbbbbbb-0000-0000-0000-000000000001',
     '33333333-3333-3333-3333-333333333333', 2, 1, 'sang', 'm_toan', 'trenLop');

  insert into nhac_nho (id, tu_id, den_id, noi_dung) values
    ('cccccccc-0000-0000-0000-000000000001',
     '11111111-1111-1111-1111-111111111111',
     '33333333-3333-3333-3333-333333333333', 'Làm nốt bài nhé');

  insert into storage.buckets (id, name, public)
  values ('bai-lam', 'bai-lam', false) on conflict (id) do nothing;
  insert into storage.objects (bucket_id, name) values
    ('bai-lam', '33333333-3333-3333-3333-333333333333/anh1.jpg'),
    ('bai-lam', '44444444-4444-4444-4444-444444444444/anh2.jpg');

  -- --------------------------------------------------------------- phép thử
  -- Mỗi dòng: tên, đóng vai ai (null là khách chưa đăng nhập), loại phép thử,
  -- câu lệnh, và số hàng mong thấy.
  --
  --   thay — truy vấn phải trả về đúng `so` hàng
  --   duoc — câu lệnh phải chạy trót lọt
  --   chan — câu lệnh phải bị chặn. Ghi 0 hàng cũng tính là bị chặn: RLS lọc
  --          hàng ra khỏi tầm nhìn thì UPDATE và DELETE không báo lỗi, chúng
  --          chỉ lặng lẽ không đụng tới gì.
  --
  -- Thứ tự các dòng có ý nghĩa — vài phép thử dựa vào thay đổi của phép trước.

  for t in select * from (values
