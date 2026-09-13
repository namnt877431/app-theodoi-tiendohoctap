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
    -- ------------------------------------------------------------ hồ sơ
    -- PH1 111… là bố mẹ của HS1 333…   PH2 222… không liên quan tới ai
    -- HS1 333…   HS2 444…   QT 555…

    ('HS đọc được hồ sơ của chính mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from nguoi_dung where id = '33333333-3333-3333-3333-333333333333'$q$, 1),

    ('HS không đọc được hồ sơ bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from nguoi_dung where id = '44444444-4444-4444-4444-444444444444'$q$, 0),

    ('HS không đọc được hồ sơ phụ huynh nhà khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from nguoi_dung where id = '22222222-2222-2222-2222-222222222222'$q$, 0),

    ('HS sửa được họ tên của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$update nguoi_dung set ho_ten = 'Học Sinh Một B'
         where id = '33333333-3333-3333-3333-333333333333'$q$, 0),

    ('HS không tự phong mình làm quản trị',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update nguoi_dung set vai_tro = 'quanTri'
         where id = '33333333-3333-3333-3333-333333333333'$q$, 0),

    ('HS không tự đổi mình thành phụ huynh',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update nguoi_dung set vai_tro = 'phuHuynh'
         where id = '33333333-3333-3333-3333-333333333333'$q$, 0),

    ('HS không tự khóa hay mở khóa tài khoản',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update nguoi_dung set hoat_dong = false
         where id = '33333333-3333-3333-3333-333333333333'$q$, 0),

    ('HS không sửa được hồ sơ bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update nguoi_dung set ho_ten = 'Bị đổi tên'
         where id = '44444444-4444-4444-4444-444444444444'$q$, 0),

    ('HS không xóa được hồ sơ người khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$delete from nguoi_dung where id = '44444444-4444-4444-4444-444444444444'$q$, 0),

    ('HS không tự chèn hồ sơ cho người khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into nguoi_dung (id, ho_ten, vai_tro)
        values ('99999999-9999-9999-9999-999999999999', 'Ma', 'hocSinh')$q$, 0),

    ('PH đọc được hồ sơ con mình',
     '11111111-1111-1111-1111-111111111111'::uuid, 'thay',
     $q$select 1 from nguoi_dung where id = '33333333-3333-3333-3333-333333333333'$q$, 1),

    ('PH chỉ thấy mình và con, không thấy ai khác',
     '11111111-1111-1111-1111-111111111111'::uuid, 'thay',
     $q$select 1 from nguoi_dung$q$, 2),

    ('PH không sửa được hồ sơ con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$update nguoi_dung set ho_ten = 'Bố đặt lại tên'
         where id = '33333333-3333-3333-3333-333333333333'$q$, 0),

    ('PH lạ không đọc được hồ sơ trẻ không phải con mình',
     '22222222-2222-2222-2222-222222222222'::uuid, 'thay',
     $q$select 1 from nguoi_dung where id = '33333333-3333-3333-3333-333333333333'$q$, 0),

    ('QT đọc được toàn bộ hồ sơ',
     '55555555-5555-5555-5555-555555555555'::uuid, 'thay',
     $q$select 1 from nguoi_dung$q$, 5),

    ('QT đổi được vai trò của người khác',
     '55555555-5555-5555-5555-555555555555'::uuid, 'duoc',
     $q$update nguoi_dung set vai_tro = 'phuHuynh'
         where id = '44444444-4444-4444-4444-444444444444'$q$, 0),

    ('QT khóa được tài khoản',
     '55555555-5555-5555-5555-555555555555'::uuid, 'duoc',
     $q$update nguoi_dung set hoat_dong = false
         where id = '44444444-4444-4444-4444-444444444444'$q$, 0),

    ('QT mở khóa lại được tài khoản',
     '55555555-5555-5555-5555-555555555555'::uuid, 'duoc',
     $q$update nguoi_dung set vai_tro = 'hocSinh', hoat_dong = true
         where id = '44444444-4444-4444-4444-444444444444'$q$, 0),

    -- Trigger cho qua khi auth.uid() là null, vì đó là dấu hiệu lệnh đến từ
    -- phía máy chủ. Khách chưa đăng nhập cũng có auth.uid() null — nên phải
    -- chắc họ không bao giờ tới được chỗ đó. Chặn nằm ở quyền trên bảng, thu
    -- hồi khỏi vai trò anon ở file 01_bang.sql.

    ('Khách chưa đăng nhập không đọc được hồ sơ nào',
     null::uuid, 'chan', $q$select 1 from nguoi_dung$q$, 0),

    ('Khách chưa đăng nhập không đọc được báo cáo',
     null::uuid, 'chan', $q$select 1 from bao_cao$q$, 0),

    ('Khách chưa đăng nhập không phong quản trị cho ai',
     null::uuid, 'chan',
     $q$update nguoi_dung set vai_tro = 'quanTri'
         where id = '33333333-3333-3333-3333-333333333333'$q$, 0),

    ('Khách chưa đăng nhập không nối mình vào đứa trẻ nào',
     null::uuid, 'chan',
     $q$insert into lien_ket (phu_huynh_id, hoc_sinh_id)
        values ('22222222-2222-2222-2222-222222222222',
                '33333333-3333-3333-3333-333333333333')$q$, 0),

    -- ---------------------------------------------------------- liên kết
    -- Bảng quan trọng nhất trong lược đồ: ai chèn được một dòng vào đây là
    -- người đó đọc được toàn bộ nhật ký học tập của một đứa trẻ.

    ('PH thấy liên kết của chính mình',
     '11111111-1111-1111-1111-111111111111'::uuid, 'thay',
     $q$select 1 from lien_ket$q$, 1),

    ('PH không tự nối thêm một đứa trẻ khác vào mình',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$insert into lien_ket (phu_huynh_id, hoc_sinh_id)
        values ('11111111-1111-1111-1111-111111111111',
                '44444444-4444-4444-4444-444444444444')$q$, 0),

    ('PH lạ không thấy liên kết của nhà khác',
     '22222222-2222-2222-2222-222222222222'::uuid, 'thay',
     $q$select 1 from lien_ket$q$, 0),

    ('PH lạ không tự nối mình vào một học sinh bất kỳ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'chan',
     $q$insert into lien_ket (phu_huynh_id, hoc_sinh_id)
        values ('22222222-2222-2222-2222-222222222222',
                '33333333-3333-3333-3333-333333333333')$q$, 0),

    ('PH lạ không xóa được liên kết của nhà khác',
     '22222222-2222-2222-2222-222222222222'::uuid, 'chan',
     $q$delete from lien_ket
         where phu_huynh_id = '11111111-1111-1111-1111-111111111111'$q$, 0),

    ('HS thấy được mình đang nối với ai',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from lien_ket$q$, 1),

    ('HS không tự nối một người lạ vào làm phụ huynh của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into lien_ket (phu_huynh_id, hoc_sinh_id)
        values ('22222222-2222-2222-2222-222222222222',
                '33333333-3333-3333-3333-333333333333')$q$, 0),

    ('HS không tự gỡ liên kết với bố mẹ',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$delete from lien_ket
         where hoc_sinh_id = '33333333-3333-3333-3333-333333333333'$q$, 0),

    ('QT gán tay được liên kết',
     '55555555-5555-5555-5555-555555555555'::uuid, 'duoc',
     $q$insert into lien_ket (phu_huynh_id, hoc_sinh_id)
        values ('22222222-2222-2222-2222-222222222222',
                '44444444-4444-4444-4444-444444444444')$q$, 0),

    ('QT gỡ được liên kết',
     '55555555-5555-5555-5555-555555555555'::uuid, 'duoc',
     $q$delete from lien_ket
         where phu_huynh_id = '22222222-2222-2222-2222-222222222222'$q$, 0),

    -- Gỡ rồi nối lại, để các phép thử sau vẫn có một gia đình hoàn chỉnh.
    ('PH tự gỡ được liên kết của chính mình',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$delete from lien_ket
         where phu_huynh_id = '11111111-1111-1111-1111-111111111111'$q$, 0),

    ('QT nối lại được',
     '55555555-5555-5555-5555-555555555555'::uuid, 'duoc',
     $q$insert into lien_ket (phu_huynh_id, hoc_sinh_id)
        values ('11111111-1111-1111-1111-111111111111',
                '33333333-3333-3333-3333-333333333333')$q$, 0),

    -- ----------------------------------------------------------- báo cáo
    -- Báo cáo là lời của học sinh. Bố mẹ đọc được và ghi được lời nhận xét
    -- vào cuối trang, nhưng không sửa được bài.

    ('HS đọc được báo cáo của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from bao_cao
         where hoc_sinh_id = '33333333-3333-3333-3333-333333333333'$q$, 1),

    ('HS không đọc được báo cáo của bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from bao_cao
         where hoc_sinh_id = '44444444-4444-4444-4444-444444444444'$q$, 0),

    ('HS viết được báo cáo cho mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$insert into bao_cao (id, hoc_sinh_id, ngay, loai, mon_id, noi_dung, trang_thai)
        values ('aaaaaaaa-0000-0000-0000-000000000011',
                '33333333-3333-3333-3333-333333333333',
                current_date, 'hocThem', 'm_toan', 'Ôn đề số 3', 'chuaLam')$q$, 0),

    ('HS không viết báo cáo hộ bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into bao_cao (id, hoc_sinh_id, ngay, loai, noi_dung, trang_thai)
        values ('aaaaaaaa-0000-0000-0000-000000000012',
                '44444444-4444-4444-4444-444444444444',
                current_date, 'trenLop', 'Bài giả', 'xong')$q$, 0),

    -- Đặt về chuaLam để phép thử "PH không đánh dấu xong" bên dưới thật sự là
    -- một thay đổi — trigger chỉ nổ khi giá trị mới khác giá trị cũ.
    ('HS sửa được nội dung báo cáo của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$update bao_cao set noi_dung = 'Bài 12 và 13 trang 47', trang_thai = 'chuaLam'
         where id = 'aaaaaaaa-0000-0000-0000-000000000001'$q$, 0),

    ('HS không sửa được báo cáo của bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update bao_cao set trang_thai = 'chuaLam'
         where id = 'aaaaaaaa-0000-0000-0000-000000000002'$q$, 0),

    ('HS không xóa được báo cáo của bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$delete from bao_cao where id = 'aaaaaaaa-0000-0000-0000-000000000002'$q$, 0),

    ('HS xóa được báo cáo của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$delete from bao_cao where id = 'aaaaaaaa-0000-0000-0000-000000000011'$q$, 0),

    ('PH đọc được báo cáo của con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'thay',
     $q$select 1 from bao_cao
         where hoc_sinh_id = '33333333-3333-3333-3333-333333333333'$q$, 1),

    ('PH viết được lời nhận xét',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$update bao_cao set nhan_xet_phu_huynh = 'Con làm tốt lắm',
                          phu_huynh_da_xem   = true
         where id = 'aaaaaaaa-0000-0000-0000-000000000001'$q$, 0),

    ('PH không sửa được nội dung bài của con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$update bao_cao set noi_dung = 'Bố sửa thành bài khác'
         where id = 'aaaaaaaa-0000-0000-0000-000000000001'$q$, 0),

    ('PH không tự đánh dấu bài con là đã xong',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$update bao_cao set trang_thai = 'xong'
         where id = 'aaaaaaaa-0000-0000-0000-000000000001'$q$, 0),

    ('PH không gỡ ảnh bài làm của con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$update bao_cao set anh = '{}'::text[]
         where id = 'aaaaaaaa-0000-0000-0000-000000000001'$q$, 0),

    ('PH không đổi số phút con đã học',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$update bao_cao set so_phut = 240
         where id = 'aaaaaaaa-0000-0000-0000-000000000001'$q$, 0),

    ('PH không chuyển báo cáo sang tên đứa trẻ khác',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$update bao_cao set hoc_sinh_id = '44444444-4444-4444-4444-444444444444'
         where id = 'aaaaaaaa-0000-0000-0000-000000000001'$q$, 0),

    ('PH không viết báo cáo thay con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$insert into bao_cao (id, hoc_sinh_id, ngay, loai, noi_dung, trang_thai)
        values ('aaaaaaaa-0000-0000-0000-000000000013',
                '33333333-3333-3333-3333-333333333333',
                current_date, 'trenLop', 'Bố viết hộ', 'xong')$q$, 0),

    ('PH không xóa được báo cáo của con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$delete from bao_cao where id = 'aaaaaaaa-0000-0000-0000-000000000001'$q$, 0),

    ('PH lạ không đọc được báo cáo của trẻ không phải con mình',
     '22222222-2222-2222-2222-222222222222'::uuid, 'thay',
     $q$select 1 from bao_cao$q$, 0),

    ('PH lạ không ghi được gì vào báo cáo của trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'chan',
     $q$update bao_cao set nhan_xet_phu_huynh = 'Người lạ ghi vào'
         where id = 'aaaaaaaa-0000-0000-0000-000000000001'$q$, 0),

    -- ------------------------------------------- thời khóa biểu, nhắc nhở

    ('HS xếp được tiết cho mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$insert into tiet_hoc (hoc_sinh_id, thu, tiet, buoi, mon_id, loai)
        values ('33333333-3333-3333-3333-333333333333',
                3, 2, 'sang', 'm_toan', 'trenLop')$q$, 0),

    ('HS không xếp tiết vào thời khóa biểu bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into tiet_hoc (hoc_sinh_id, thu, tiet, buoi, loai)
        values ('44444444-4444-4444-4444-444444444444',
                3, 2, 'sang', 'trenLop')$q$, 0),

    ('HS chỉ thấy thời khóa biểu của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from tiet_hoc$q$, 2),

    -- Bố mẹ khai hộ thời khóa biểu đầu năm là chuyện bình thường, nên cho phép.
    ('PH xếp hộ được tiết cho con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$insert into tiet_hoc (hoc_sinh_id, thu, tiet, buoi, mon_id, loai)
        values ('33333333-3333-3333-3333-333333333333',
                4, 1, 'chieu', 'm_toan', 'hocThem')$q$, 0),

    ('PH xóa được tiết của con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$delete from tiet_hoc
         where hoc_sinh_id = '33333333-3333-3333-3333-333333333333' and thu = 4$q$, 0),

    ('PH lạ không thấy thời khóa biểu của trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'thay',
     $q$select 1 from tiet_hoc$q$, 0),

    ('PH lạ không xếp tiết vào thời khóa biểu trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'chan',
     $q$insert into tiet_hoc (hoc_sinh_id, thu, tiet, buoi, loai)
        values ('33333333-3333-3333-3333-333333333333',
                5, 1, 'toi', 'hocThem')$q$, 0),

    ('PH lạ không gửi được lời nhắc cho trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'chan',
     $q$insert into nhac_nho (tu_id, den_id, noi_dung)
        values ('22222222-2222-2222-2222-222222222222',
                '33333333-3333-3333-3333-333333333333', 'Lời nhắc của người lạ')$q$, 0),

    ('PH gửi được lời nhắc cho con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$insert into nhac_nho (id, tu_id, den_id, noi_dung)
        values ('cccccccc-0000-0000-0000-000000000011',
                '11111111-1111-1111-1111-111111111111',
                '33333333-3333-3333-3333-333333333333', 'Nhớ học bài')$q$, 0),

    ('PH không mạo danh người khác để gửi lời nhắc',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$insert into nhac_nho (tu_id, den_id, noi_dung)
        values ('55555555-5555-5555-5555-555555555555',
                '33333333-3333-3333-3333-333333333333', 'Giả danh quản trị')$q$, 0),

    ('PH không tạo sẵn lời nhắc đã đánh dấu đã đọc',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$insert into nhac_nho (tu_id, den_id, noi_dung, da_doc)
        values ('11111111-1111-1111-1111-111111111111',
                '33333333-3333-3333-3333-333333333333', 'Đánh dấu sẵn', true)$q$, 0),

    ('PH không tự đánh dấu hộ con là đã đọc',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$update nhac_nho set da_doc = true
         where id = 'cccccccc-0000-0000-0000-000000000001'$q$, 0),

    ('PH thu hồi được lời nhắc mình đã gửi',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$delete from nhac_nho where id = 'cccccccc-0000-0000-0000-000000000011'$q$, 0),

    ('HS đọc được lời nhắc gửi cho mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from nhac_nho$q$, 1),

    ('HS đánh dấu đã đọc',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$update nhac_nho set da_doc = true
         where id = 'cccccccc-0000-0000-0000-000000000001'$q$, 0),

    ('HS không sửa lại nội dung lời bố mẹ nhắc',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update nhac_nho set noi_dung = 'Không phải làm gì cả'
         where id = 'cccccccc-0000-0000-0000-000000000001'$q$, 0),

    ('HS không dời hạn lời nhắc',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update nhac_nho set han_luc = now() + interval '30 days'
         where id = 'cccccccc-0000-0000-0000-000000000001'$q$, 0),

    ('HS không xóa lời nhắc của bố mẹ',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$delete from nhac_nho where id = 'cccccccc-0000-0000-0000-000000000001'$q$, 0),

    ('HS khác không đọc trộm được lời nhắc',
     '44444444-4444-4444-4444-444444444444'::uuid, 'thay',
     $q$select 1 from nhac_nho$q$, 0),

    -- --------------------------------------------------------- kho ảnh
    -- Đường dẫn là {hoc_sinh_id}/{tên tệp}. Thư mục đầu tiên chính là id học
    -- sinh, nên policy dùng lại đúng hàm xem_duoc() với phần dữ liệu còn lại.
    --
    -- Đọc trước, tải lên sau — để phép đếm không bị chính ảnh mình vừa tải lên
    -- làm sai lệch.
    --
    -- Không có phép thử nào cho việc XÓA ảnh. Supabase chặn DELETE thẳng vào
    -- storage.objects bằng trigger, nổ trước cả RLS ("Direct deletion from
    -- storage tables is not allowed"). Nên từ SQL không phân biệt nổi "bị
    -- policy chặn" với "bị nền tảng chặn", và một phép thử đạt vì lý do sai
    -- còn tệ hơn không có phép thử. Policy xóa ở 04_storage.sql vẫn đúng và
    -- vẫn có tác dụng — app xóa qua Storage API, đường đó có đi qua RLS.

    ('HS xem được ảnh bài làm của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from storage.objects
         where name like '33333333-3333-3333-3333-333333333333/%'$q$, 1),

    ('HS không xem được ảnh bài làm của bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from storage.objects
         where name like '44444444-4444-4444-4444-444444444444/%'$q$, 0),

    ('PH xem được ảnh bài làm của con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'thay',
     $q$select 1 from storage.objects
         where name like '33333333-3333-3333-3333-333333333333/%'$q$, 1),

    ('PH lạ không xem được ảnh bài làm của trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'thay',
     $q$select 1 from storage.objects$q$, 0),

    ('Khách chưa đăng nhập không xem được ảnh nào',
     null::uuid, 'chan', $q$select 1 from storage.objects$q$, 0),

    ('HS tải được ảnh vào thư mục của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$insert into storage.objects (bucket_id, name)
        values ('bai-lam', '33333333-3333-3333-3333-333333333333/moi.jpg')$q$, 0),

    ('HS không tải ảnh vào thư mục bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into storage.objects (bucket_id, name)
        values ('bai-lam', '44444444-4444-4444-4444-444444444444/chen.jpg')$q$, 0),

    ('PH không tải ảnh thay con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$insert into storage.objects (bucket_id, name)
        values ('bai-lam', '33333333-3333-3333-3333-333333333333/bo-tai.jpg')$q$, 0),


    -- ------------------------------------------------ tỉnh, trường, thầy cô

    -- Tỉnh và trường là danh sách công khai: khách chưa đăng nhập đọc được
    -- (màn đăng ký cần), nhưng chỉ quản trị mới sửa.
    ('Khách đọc được danh sách tỉnh',
     null::uuid, 'thay',
     $q$select 1 from tinh where id = 't_thu'$q$, 1),

    ('Khách đọc được danh sách trường',
     null::uuid, 'thay',
     $q$select 1 from truong where id = 'tr_thu'$q$, 1),

    ('Khách không thêm được trường',
     null::uuid, 'chan',
     $q$insert into truong (id, ten) values ('tr_lau', 'Trường lậu')$q$, 0),

    ('HS không thêm được trường',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into truong (id, ten) values ('tr_lau', 'Trường lậu')$q$, 0),

    ('HS không sửa được tên trường',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update truong set ten = 'Đổi bậy' where id = 'tr_thu'$q$, 0),

    ('PH không thêm được tỉnh',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$insert into tinh (id, ten) values ('t_lau', 'Tỉnh lậu')$q$, 0),

    ('QT thêm được tỉnh',
     '55555555-5555-5555-5555-555555555555'::uuid, 'duoc',
     $q$insert into tinh (id, ten) values ('t_moi', 'Tỉnh mới')$q$, 0),

    ('QT thêm được trường',
     '55555555-5555-5555-5555-555555555555'::uuid, 'duoc',
     $q$insert into truong (id, ten, tinh_id) values ('tr_moi', 'Trường mới', 't_moi')$q$, 0),

    ('QT xóa được trường vừa thêm',
     '55555555-5555-5555-5555-555555555555'::uuid, 'duoc',
     $q$delete from truong where id = 'tr_moi'$q$, 0),

    -- Học sinh đổi được trường của chính mình (chuyển trường, hoặc tài khoản
    -- đăng ký từ hồi chưa có danh mục).
    ('HS đổi được trường của mình',
     '44444444-4444-4444-4444-444444444444'::uuid, 'duoc',
     $q$update nguoi_dung set truong_id = 'tr_thu'
         where id = '44444444-4444-4444-4444-444444444444'$q$, 0),

    -- Thầy cô chung: ai cũng thấy. Thầy riêng: chỉ nhà em đó và quản trị.
    ('HS thấy thầy cô chung',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from giao_vien where id = 'gv_chung'$q$, 1),

    ('HS thấy thầy riêng của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from giao_vien where id = 'gv_rieng_hs1'$q$, 1),

    ('HS khác không thấy thầy riêng của bạn',
     '44444444-4444-4444-4444-444444444444'::uuid, 'thay',
     $q$select 1 from giao_vien where id = 'gv_rieng_hs1'$q$, 0),

    ('PH thấy thầy riêng của con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'thay',
     $q$select 1 from giao_vien where id = 'gv_rieng_hs1'$q$, 1),

    ('PH lạ không thấy thầy riêng của trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'thay',
     $q$select 1 from giao_vien where id = 'gv_rieng_hs1'$q$, 0),

    ('QT thấy thầy riêng của học sinh',
     '55555555-5555-5555-5555-555555555555'::uuid, 'thay',
     $q$select 1 from giao_vien where id = 'gv_rieng_hs1'$q$, 1),

    -- Học sinh tự thêm thầy dạy thêm của nhà mình, nhưng chỉ đúng kiểu đó:
    -- phải ghi mình là chủ, phải là hocThem, và không gán cho bạn khác.
    ('HS thêm được thầy dạy thêm riêng',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$insert into giao_vien (id, ho_ten, mon_id, loai, chu_id)
        values ('gv_rieng_moi', 'Cô Mới', 'm_toan', 'hocThem',
                '33333333-3333-3333-3333-333333333333')$q$, 0),

    ('HS không thêm được thầy vào danh mục chung',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into giao_vien (id, ho_ten, mon_id, loai)
        values ('gv_lau', 'Thầy Lậu', 'm_toan', 'hocThem')$q$, 0),

    ('HS không thêm được thầy trên lớp dù ghi chủ là mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into giao_vien (id, ho_ten, mon_id, loai, truong_id, chu_id)
        values ('gv_lau', 'Thầy Lậu', 'm_toan', 'trenLop', 'tr_thu',
                '33333333-3333-3333-3333-333333333333')$q$, 0),

    ('HS không gán thầy riêng cho bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into giao_vien (id, ho_ten, mon_id, loai, chu_id)
        values ('gv_lau', 'Thầy Lậu', 'm_toan', 'hocThem',
                '44444444-4444-4444-4444-444444444444')$q$, 0),

    ('HS không biến thầy riêng thành thầy chung',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update giao_vien set chu_id = null where id = 'gv_rieng_hs1'$q$, 0),

    ('HS không sửa được thầy cô chung',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update giao_vien set ho_ten = 'Đổi bậy' where id = 'gv_chung'$q$, 0),

    ('HS sửa được thầy riêng của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$update giao_vien set ho_ten = 'Thầy Riêng Sửa' where id = 'gv_rieng_hs1'$q$, 0),

    -- Bố mẹ khai hộ là chuyện bình thường, nên cho phép — nhưng chỉ cho con mình.
    ('PH thêm hộ được thầy riêng cho con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$insert into giao_vien (id, ho_ten, mon_id, loai, chu_id)
        values ('gv_rieng_ph', 'Thầy Bố Thêm', 'm_toan', 'hocThem',
                '33333333-3333-3333-3333-333333333333')$q$, 0),

    ('PH lạ không thêm được thầy riêng cho trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'chan',
     $q$insert into giao_vien (id, ho_ten, mon_id, loai, chu_id)
        values ('gv_lau', 'Thầy Lậu', 'm_toan', 'hocThem',
                '33333333-3333-3333-3333-333333333333')$q$, 0),

    ('HS xóa được thầy riêng của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$delete from giao_vien where id = 'gv_rieng_moi'$q$, 0),

    ('HS không xóa được thầy cô chung',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$delete from giao_vien where id = 'gv_chung'$q$, 0),

    ('QT sửa được thầy cô chung',
     '55555555-5555-5555-5555-555555555555'::uuid, 'duoc',
     $q$update giao_vien set noi_day = 'Lớp 9A1' where id = 'gv_chung'$q$, 0),

    -- ---------------------------------------------------------- bài học

    -- Danh mục bài học đọc chung, chỉ quản trị sửa. Khách không thấy gì.
    ('HS đọc được danh mục bài học',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from bai_hoc where chuong = 'Chương thử'$q$, 2),

    ('PH đọc được danh mục bài học',
     '11111111-1111-1111-1111-111111111111'::uuid, 'thay',
     $q$select 1 from bai_hoc where id = 'bh_thu_1'$q$, 1),

    ('Khách không đọc được danh mục bài học',
     null::uuid, 'chan',
     $q$select 1 from bai_hoc$q$, 0),

    ('HS không sửa được tóm tắt bài học',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update bai_hoc set tom_tat = 'Đổi bậy' where id = 'bh_thu_1'$q$, 0),

    ('QT sửa được tóm tắt, và bài được đánh dấu sửa tay',
     '55555555-5555-5555-5555-555555555555'::uuid, 'duoc',
     $q$update bai_hoc set tom_tat = 'Tóm tắt quản trị sửa' where id = 'bh_thu_1'$q$, 0),

    ('Bài quản trị vừa sửa mang cờ sua_tay',
     '55555555-5555-5555-5555-555555555555'::uuid, 'thay',
     $q$select 1 from bai_hoc where id = 'bh_thu_1' and sua_tay$q$, 1),

    ('Bài chưa ai sửa thì không mang cờ sua_tay',
     '55555555-5555-5555-5555-555555555555'::uuid, 'thay',
     $q$select 1 from bai_hoc where id = 'bh_thu_2' and not sua_tay$q$, 1),

    ('HS gắn được báo cáo của mình vào một bài trong danh mục',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$update bao_cao set bai_hoc_id = 'bh_thu_1'
        where id = 'aaaaaaaa-0000-0000-0000-000000000001'$q$, 0),

    ('Không gắn được vào bài không có trong danh mục',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update bao_cao set bai_hoc_id = 'bh_khong_co'
        where id = 'aaaaaaaa-0000-0000-0000-000000000001'$q$, 0),

    -- Bài học nằm trong phần "lời của học sinh", bố mẹ không đổi được.
    ('PH không đổi được bài học của báo cáo',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$update bao_cao set bai_hoc_id = 'bh_thu_2'
        where id = 'aaaaaaaa-0000-0000-0000-000000000001'$q$, 0),


    -- ---------------------------------------------------- thông báo đẩy

    -- Máy nhận: của ai người đó đăng ký. Đăng ký hộ được là nhận trộm được
    -- thông báo (kèm nội dung báo cáo) của nhà khác.
    ('HS đăng ký được máy của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$insert into thiet_bi (token, nguoi_dung_id)
        values ('tok-hs1', '33333333-3333-3333-3333-333333333333')$q$, 0),

    ('HS không đăng ký máy dưới tên người khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into thiet_bi (token, nguoi_dung_id)
        values ('tok-lau', '11111111-1111-1111-1111-111111111111')$q$, 0),

    ('HS khác không thấy máy của bạn',
     '44444444-4444-4444-4444-444444444444'::uuid, 'thay',
     $q$select 1 from thiet_bi where token = 'tok-hs1'$q$, 0),

    ('HS không đổi chủ máy của bạn sang mình',
     '44444444-4444-4444-4444-444444444444'::uuid, 'chan',
     $q$update thiet_bi set nguoi_dung_id = '44444444-4444-4444-4444-444444444444'
         where token = 'tok-hs1'$q$, 0),

    ('Khách không đọc được bảng máy',
     null::uuid, 'chan',
     $q$select 1 from thiet_bi$q$, 0),

    -- Hàng đợi: chỉ trigger ghi, người dùng đọc phần của mình.
    ('Khách không đọc được hàng đợi thông báo',
     null::uuid, 'chan',
     $q$select 1 from thong_bao$q$, 0),

    ('HS không tự chèn thông báo cho ai',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into thong_bao (den_id, tieu_de, noi_dung)
        values ('44444444-4444-4444-4444-444444444444', 'Giả', 'mạo')$q$, 0),

    ('HS không xóa được thông báo',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$delete from thong_bao$q$, 0),

    -- HS gửi báo cáo → mỗi PH đã nối được một hàng; PH lạ không.
    ('HS gửi báo cáo mới',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$insert into bao_cao (id, hoc_sinh_id, ngay, loai, mon_id, noi_dung, trang_thai)
        values ('aaaaaaaa-0000-0000-0000-000000000009',
                '33333333-3333-3333-3333-333333333333',
                current_date, 'trenLop', 'm_toan', 'Bài để thử thông báo', 'xong')$q$, 0),

    ('PH được báo khi con gửi báo cáo',
     '11111111-1111-1111-1111-111111111111'::uuid, 'thay',
     $q$select 1 from thong_bao
         where du_lieu ->> 'loai' = 'bao_cao'
           and du_lieu ->> 'bao_cao_id' = 'aaaaaaaa-0000-0000-0000-000000000009'$q$, 1),

    ('Tiêu đề thông báo có tên con, nội dung có tên môn',
     '11111111-1111-1111-1111-111111111111'::uuid, 'thay',
     $q$select 1 from thong_bao
         where du_lieu ->> 'bao_cao_id' = 'aaaaaaaa-0000-0000-0000-000000000009'
           and tieu_de like 'Học Sinh Một%' and noi_dung like 'Toán%'$q$, 1),

    ('PH lạ không được báo về báo cáo của trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'thay',
     $q$select 1 from thong_bao
         where du_lieu ->> 'bao_cao_id' = 'aaaaaaaa-0000-0000-0000-000000000009'$q$, 0),

    ('HS không đọc được thông báo gửi cho bố mẹ',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from thong_bao
         where du_lieu ->> 'bao_cao_id' = 'aaaaaaaa-0000-0000-0000-000000000009'$q$, 0),

    -- PH ghi nhận xét → HS được báo; ghi lại y hệt hay HS tự sửa bài thì không.
    ('PH ghi nhận xét vào báo cáo của con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$update bao_cao set nhan_xet_phu_huynh = 'Tốt lắm con'
         where id = 'aaaaaaaa-0000-0000-0000-000000000009'$q$, 0),

    ('HS được báo khi bố mẹ nhận xét',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from thong_bao
         where du_lieu ->> 'loai' = 'nhan_xet'
           and du_lieu ->> 'bao_cao_id' = 'aaaaaaaa-0000-0000-0000-000000000009'
           and noi_dung = 'Tốt lắm con'$q$, 1),

    ('PH lưu lại nhận xét y hệt',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$update bao_cao set phu_huynh_da_xem = true
         where id = 'aaaaaaaa-0000-0000-0000-000000000009'$q$, 0),

    ('HS tự sửa bài của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$update bao_cao set noi_dung = 'Bài đã sửa'
         where id = 'aaaaaaaa-0000-0000-0000-000000000009'$q$, 0),

    ('Nhận xét không đổi thì không báo thêm lần nào',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from thong_bao
         where du_lieu ->> 'loai' = 'nhan_xet'
           and du_lieu ->> 'bao_cao_id' = 'aaaaaaaa-0000-0000-0000-000000000009'$q$, 1),

    -- PH gửi lời nhắc → HS được báo.
    ('PH gửi lời nhắc cho con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$insert into nhac_nho (id, tu_id, den_id, noi_dung)
        values ('cccccccc-0000-0000-0000-000000000009',
                '11111111-1111-1111-1111-111111111111',
                '33333333-3333-3333-3333-333333333333', 'Ngủ sớm nhé')$q$, 0),

    ('HS được báo khi bố mẹ nhắc',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from thong_bao
         where du_lieu ->> 'loai' = 'nhac_nho'
           and du_lieu ->> 'nhac_nho_id' = 'cccccccc-0000-0000-0000-000000000009'
           and tieu_de like 'Phụ Huynh Một%' and noi_dung = 'Ngủ sớm nhé'$q$, 1),

    ('QT thấy toàn bộ hàng đợi',
     '55555555-5555-5555-5555-555555555555'::uuid, 'thay',
     $q$select 1 from thong_bao
         where du_lieu ->> 'nhac_nho_id' = 'cccccccc-0000-0000-0000-000000000009'$q$, 1),

    -- Đợt nhắc tối là việc của máy chủ; không ai kích được qua API.
    ('HS không tự kích được đợt nhắc tối cả trường',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$select nhac_toi_chua_viet_bao_cao()$q$, 0),

    ('QT cũng không kích được đợt nhắc tối qua API',
     '55555555-5555-5555-5555-555555555555'::uuid, 'chan',
     $q$select nhac_toi_chua_viet_bao_cao()$q$, 0),

    -- Dọn bài thử để phần mã mời phía sau đếm báo cáo của HS1 vẫn đúng.
    -- Thông báo đã xếp vẫn còn — hàng đợi không xóa theo báo cáo.
    ('HS xóa bài đã dùng để thử thông báo',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$delete from bao_cao where id = 'aaaaaaaa-0000-0000-0000-000000000009'$q$, 0),

    ('HS không tự kích được tổng kết tuần',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$select tong_ket_tuan()$q$, 0),

    -- ------------------------------------------------------- phần thưởng
    --
    -- Quà là chuyện của bố mẹ với con: bố mẹ treo dưới tên mình, trao, treo
    -- lại, xóa. Con chỉ nhìn — không tự treo, không tự đánh dấu đã trao.

    ('PH treo được phần thưởng cho con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$insert into phan_thuong (id, hoc_sinh_id, tao_boi, moc, ten)
        values ('dddddddd-0000-0000-0000-000000000001',
                '33333333-3333-3333-3333-333333333333',
                '11111111-1111-1111-1111-111111111111', 7, 'Đi ăn kem')$q$, 0),

    ('PH không treo dưới tên người khác',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$insert into phan_thuong (hoc_sinh_id, tao_boi, moc, ten)
        values ('33333333-3333-3333-3333-333333333333',
                '22222222-2222-2222-2222-222222222222', 7, 'Giả danh')$q$, 0),

    ('PH lạ không treo được cho trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'chan',
     $q$insert into phan_thuong (hoc_sinh_id, tao_boi, moc, ten)
        values ('33333333-3333-3333-3333-333333333333',
                '22222222-2222-2222-2222-222222222222', 7, 'Của người lạ')$q$, 0),

    ('PH lạ không thấy phần thưởng của trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'thay',
     $q$select 1 from phan_thuong$q$, 0),

    ('HS thấy phần thưởng treo cho mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from phan_thuong$q$, 1),

    ('HS không tự đánh dấu đã trao',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$update phan_thuong set trao_luc = now()
         where id = 'dddddddd-0000-0000-0000-000000000001'$q$, 0),

    ('HS không tự treo thưởng cho mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into phan_thuong (hoc_sinh_id, tao_boi, moc, ten)
        values ('33333333-3333-3333-3333-333333333333',
                '33333333-3333-3333-3333-333333333333', 1, 'Tự thưởng')$q$, 0),

    ('HS không xóa được phần thưởng',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$delete from phan_thuong
         where id = 'dddddddd-0000-0000-0000-000000000001'$q$, 0),

    ('PH đánh dấu đã trao và treo lại được',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$update phan_thuong set so_lan_trao = 1, trao_luc = now(), tu_ngay = current_date
         where id = 'dddddddd-0000-0000-0000-000000000001'$q$, 0),

    ('PH xóa được phần thưởng mình treo',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$delete from phan_thuong
         where id = 'dddddddd-0000-0000-0000-000000000001'$q$, 0),

    ('PH treo được thưởng điểm thi: giữa kì Toán từ 8',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$insert into phan_thuong (hoc_sinh_id, tao_boi, loai, moc, ten, mon_id, ki_thi, diem_toi_thieu)
        values ('33333333-3333-3333-3333-333333333333',
                '11111111-1111-1111-1111-111111111111', 'diem', 1, 'Đi xem phim',
                'm_toan', 'giuaKi', 8)$q$, 0),

    ('Thưởng điểm với kì thi lạ bị chặn',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$insert into phan_thuong (hoc_sinh_id, tao_boi, loai, moc, ten, ki_thi, diem_toi_thieu)
        values ('33333333-3333-3333-3333-333333333333',
                '11111111-1111-1111-1111-111111111111', 'diem', 1, 'Sai kì', 'thuongXuyen', 8)$q$, 0),

    -- ----------------------------------------------------------- sổ điểm
    --
    -- Điểm là của nhà: con ghi được, bố mẹ ghi được và sửa được; người lạ
    -- không thấy, không ghi.

    ('HS ghi được điểm của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$insert into diem_thi (id, hoc_sinh_id, mon_id, loai, hoc_ki, diem, tao_boi)
        values ('eeeeeeee-0000-0000-0000-000000000001',
                '33333333-3333-3333-3333-333333333333', 'm_toan', 'giuaKi', 1, 8.5,
                '33333333-3333-3333-3333-333333333333')$q$, 0),

    ('HS không ghi điểm dưới tên người khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into diem_thi (hoc_sinh_id, mon_id, loai, hoc_ki, diem, tao_boi)
        values ('33333333-3333-3333-3333-333333333333', 'm_toan', 'cuoiKi', 1, 9,
                '11111111-1111-1111-1111-111111111111')$q$, 0),

    ('HS không ghi điểm cho bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into diem_thi (hoc_sinh_id, mon_id, loai, hoc_ki, diem)
        values ('44444444-4444-4444-4444-444444444444', 'm_toan', 'giuaKi', 1, 10)$q$, 0),

    ('Điểm ngoài thang 10 bị chặn',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into diem_thi (hoc_sinh_id, mon_id, loai, hoc_ki, diem)
        values ('33333333-3333-3333-3333-333333333333', 'm_toan', 'giuaKi', 1, 11)$q$, 0),

    ('PH ghi được điểm cho con và sửa điểm con ghi',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$update diem_thi set diem = 9, ghi_chu = 'Cô trả bài, được 9'
         where id = 'eeeeeeee-0000-0000-0000-000000000001'$q$, 0),

    ('PH lạ không thấy điểm của trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'thay',
     $q$select 1 from diem_thi$q$, 0),

    ('PH lạ không ghi điểm cho trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'chan',
     $q$insert into diem_thi (hoc_sinh_id, mon_id, loai, hoc_ki, diem, tao_boi)
        values ('33333333-3333-3333-3333-333333333333', 'm_toan', 'giuaKi', 1, 10,
                '22222222-2222-2222-2222-222222222222')$q$, 0),

    ('HS xóa được điểm của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$delete from diem_thi where id = 'eeeeeeee-0000-0000-0000-000000000001'$q$, 0)

  ) as v(ten, vai, kieu, cau, so)
  loop
    if t.vai is null then
      perform set_config('request.jwt.claims', '', true);
      perform set_config('role', 'anon', true);
    else
      perform set_config('request.jwt.claims',
        json_build_object('sub', t.vai::text, 'role', 'authenticated')::text, true);
      perform set_config('role', 'authenticated', true);
    end if;

    ghi := null;
    begin
      if t.kieu = 'thay' then
        execute 'select count(*) from (' || t.cau || ') x' into n;
        ok := (n = t.so);
        if not ok then ghi := 'mong thấy ' || t.so || ' hàng, thực tế ' || n; end if;
      elsif t.kieu = 'duoc' then
        execute t.cau;
        ok := true;
      else
        execute t.cau;
        get diagnostics n = row_count;
        ok := (n = 0);
        if not ok then ghi := 'lẽ ra bị chặn, nhưng đã đụng tới ' || n || ' hàng'; end if;
      end if;
    exception when others then
      -- Bị chặn thì đây là kết quả đúng; còn lại là hỏng thật.
      ok  := (t.kieu = 'chan');
      ghi := case when ok then null else sqlerrm end;
    end;

    perform set_config('role', chu, true);

    if ok then
      so_dat := so_dat + 1;
    else
      so_tru := so_tru + 1;
      bao := bao || E'\n  ✗ ' || t.ten || coalesce(' — ' || ghi, '');
    end if;
  end loop;

  perform set_config('request.jwt.claims', '', true);
  perform set_config('role', chu, true);

  -- ------------------------------------------------------------- mã mời
  --
  -- Đây là chỗ duy nhất một người lạ được phép trở thành phụ huynh của một đứa
  -- trẻ. Không xếp vào bảng phép thử ở trên được, vì phải bắt lấy mã vừa sinh
  -- rồi mang đi dùng lại.

  perform set_config('request.jwt.claims',
    json_build_object('sub', '33333333-3333-3333-3333-333333333333', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    v_ma := tao_ma_moi();
    ok  := v_ma.ma ~ '^[0-9]{6}$'
       and v_ma.hoc_sinh_id = '33333333-3333-3333-3333-333333333333'
       and v_ma.het_han > now()
       and not v_ma.da_dung;
    ghi := case when ok then null else 'mã trả về không hợp lệ: ' || v_ma::text end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ HS sinh được mã mời sáu số, còn hạn, chưa dùng' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '11111111-1111-1111-1111-111111111111', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform tao_ma_moi();
    ok := false; ghi := 'lẽ ra bị chặn vì sai vai trò';
  exception when others then ok := true;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ PH không sinh được mã mời' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    select count(*) into n from ma_moi;
    ok := (n = 0); ghi := case when ok then null else 'thấy ' || n || ' hàng' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ PH không đọc trộm được bảng mã mời' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '44444444-4444-4444-4444-444444444444', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    select count(*) into n from ma_moi;
    ok := (n = 0); ghi := case when ok then null else 'thấy ' || n || ' hàng' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ HS khác không đọc trộm được mã mời của bạn' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '33333333-3333-3333-3333-333333333333', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    select count(*) into n from ma_moi;
    ok := (n = 1); ghi := case when ok then null else 'thấy ' || n || ' hàng' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ HS đọc được mã mời của chính mình' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '44444444-4444-4444-4444-444444444444', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform dung_ma_moi(v_ma.ma);
    ok := false; ghi := 'lẽ ra bị chặn vì sai vai trò';
  exception when others then ok := true;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ HS không dùng được mã mời' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform dung_ma_moi('12ab34');
    ok := false; ghi := 'lẽ ra bị chặn vì không phải sáu chữ số';
  exception when others then ok := true;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Mã sai định dạng bị từ chối' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform dung_ma_moi(lpad(((v_ma.ma::int + 1) % 1000000)::text, 6, '0'));
    ok := false; ghi := 'lẽ ra bị chặn vì không có mã đó';
  exception when others then ok := true;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Mã không tồn tại bị từ chối' || coalesce(' — ' || ghi, '');
  end if;

  -- Mã hết hạn: chèn bằng quyền chủ rồi thử nhập.
  insert into ma_moi (ma, hoc_sinh_id, het_han)
  values ('000001', '33333333-3333-3333-3333-333333333333', now() - interval '1 minute');

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform dung_ma_moi('000001');
    ok := false; ghi := 'lẽ ra bị chặn vì đã quá mười lăm phút';
  exception when others then ok := true;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Mã hết hạn bị từ chối' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    v_hs := dung_ma_moi(v_ma.ma);
    ok  := (v_hs.id = '33333333-3333-3333-3333-333333333333');
    ghi := case when ok then null else 'nối nhầm sang học sinh khác' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ PH nhập mã đúng thì nối được với con' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    select count(*) into n from bao_cao where hoc_sinh_id = '33333333-3333-3333-3333-333333333333';
    ok := (n = 1); ghi := case when ok then null else 'thấy ' || n || ' báo cáo' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Nối xong thì PH đọc được báo cáo của con' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform dung_ma_moi(v_ma.ma);
    ok := false; ghi := 'lẽ ra bị chặn vì mã chỉ dùng một lần';
  exception when others then ok := true;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Mã đã dùng thì không dùng lại được' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', '33333333-3333-3333-3333-333333333333', 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
  begin
    perform tao_ma_moi();
    perform tao_ma_moi();
    perform set_config('role', chu, true);
    select count(*) into n from ma_moi where hoc_sinh_id = '33333333-3333-3333-3333-333333333333' and not da_dung;
    ok  := (n = 1);
    ghi := case when ok then null else 'còn ' || n || ' mã đang sống' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  perform set_config('role', chu, true);
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Sinh mã mới thì mọi mã cũ hết hiệu lực' || coalesce(' — ' || ghi, '');
  end if;

  perform set_config('request.jwt.claims', '', true);
  perform set_config('role', chu, true);


  -- ------------------------------------------------------------ nhắc tối
  --
  -- Đợt nhắc 20:00 do pg_cron gọi với vai máy chủ, nên kiểm ở đây với chính
  -- vai đó chứ không qua bảng phép thử. HS1 có bài hôm nay, HS2 chưa — chỉ
  -- HS2 được nhắc, và chỉ khi HS2 đã cài app (có máy đăng ký).

  perform set_config('request.jwt.claims', '', true);
  perform set_config('role', chu, true);

  -- Đưa ngày về theo giờ Việt Nam đúng như hàm nhắc dùng. Không thì chạy lúc
  -- 0–7 giờ sáng VN (17–24 giờ UTC) "hôm nay" của hai bên lệch nhau một ngày.
  update bao_cao set ngay = (now() at time zone 'Asia/Ho_Chi_Minh')::date
   where hoc_sinh_id = '33333333-3333-3333-3333-333333333333';
  update bao_cao set ngay = (now() at time zone 'Asia/Ho_Chi_Minh')::date - 1
   where hoc_sinh_id = '44444444-4444-4444-4444-444444444444';

  begin
    n := nhac_toi_chua_viet_bao_cao();
    ok := (n = 0);
    ghi := case when ok then null else 'HS2 chưa cài app mà vẫn nhắc ' || n || ' em' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Không nhắc học sinh chưa cài app' || coalesce(' — ' || ghi, '');
  end if;

  insert into thiet_bi (token, nguoi_dung_id)
  values ('tok-hs2', '44444444-4444-4444-4444-444444444444');

  begin
    n := nhac_toi_chua_viet_bao_cao();
    ok := (n = 1)
      and exists (select 1 from thong_bao
                   where den_id = '44444444-4444-4444-4444-444444444444'
                     and du_lieu ->> 'loai' = 'nhac_toi')
      and not exists (select 1 from thong_bao
                       where den_id = '33333333-3333-3333-3333-333333333333'
                         and du_lieu ->> 'loai' = 'nhac_toi');
    ghi := case when ok then null else 'nhắc ' || n || ' em, không đúng người' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Nhắc tối chỉ tới em có máy và chưa viết bài hôm nay' || coalesce(' — ' || ghi, '');
  end if;

  -- ------------------------------------------------------- tổng kết tuần
  --
  -- PH1 có máy và có con là HS1 (1 bài trong tuần, chưa xong). PH2 cũng đã
  -- nối HS1 qua mã mời ở phần trên nhưng không có máy → không gửi. HS1 bị
  -- phần 01 đổi tên thành "Học Sinh Một B", nên tên gọi là "B".

  insert into thiet_bi (token, nguoi_dung_id)
  values ('tok-ph1', '11111111-1111-1111-1111-111111111111');

  begin
    n := tong_ket_tuan();
    ok := (n = 1)
      and exists (select 1 from thong_bao
                   where den_id = '11111111-1111-1111-1111-111111111111'
                     and du_lieu ->> 'loai' = 'tong_ket_tuan'
                     and du_lieu ->> 'hoc_sinh_id' = '33333333-3333-3333-3333-333333333333'
                     and tieu_de = 'Tuần này của B'
                     and noi_dung like 'Xong 0/1 bài · có báo cáo 1/7 ngày%')
      and not exists (select 1 from thong_bao
                       where den_id = '22222222-2222-2222-2222-222222222222'
                         and du_lieu ->> 'loai' = 'tong_ket_tuan');
    ghi := case when ok then null else 'xếp ' || n || ' dòng: ' ||
      coalesce((select tieu_de || ' / ' || noi_dung from thong_bao
                 where du_lieu ->> 'loai' = 'tong_ket_tuan' limit 1), 'không có') end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Tổng kết tuần tới đúng bố mẹ có máy, đếm đúng bài' || coalesce(' — ' || ghi, '');
  end if;

  -- Con không có bài nào cả tuần thì vẫn báo, bằng câu khác.
  delete from bao_cao where hoc_sinh_id = '33333333-3333-3333-3333-333333333333';
  begin
    n := tong_ket_tuan();
    ok := (n = 1)
      and exists (select 1 from thong_bao
                   where den_id = '11111111-1111-1111-1111-111111111111'
                     and du_lieu ->> 'loai' = 'tong_ket_tuan'
                     and noi_dung like 'Chưa có báo cáo nào tuần này%');
    ghi := case when ok then null else 'xếp ' || n || ' dòng' end;
  exception when others then ok := false; ghi := sqlerrm;
  end;
  if ok then so_dat := so_dat + 1;
  else so_tru := so_tru + 1;
       bao := bao || E'
  ✗ Cả tuần không có bài thì tổng kết vẫn nói cho bố mẹ biết' || coalesce(' — ' || ghi, '');
  end if;
  -- ------------------------------------------------------------- tổng kết
  --
  -- Ngoại lệ dưới đây là CỐ Ý. Không mở được giao dịch tường minh (lý do ở đầu
  -- file), nên ném ngoại lệ là cách duy nhất hoàn tác sạch dữ liệu thử. Đọc
  -- nội dung thông báo, đừng nhìn màu của khung.

  if so_tru > 0 then
    raise exception E'KIỂM THỬ PHÂN QUYỀN — % đạt, % TRƯỢT trên tổng %.\n%\n\nDữ liệu thử đã được hoàn tác.',
      so_dat, so_tru, so_dat + so_tru, bao;
  else
    raise exception E'KIỂM THỬ PHÂN QUYỀN — tất cả % phép thử đều ĐẠT.\n\nKhông có gì hỏng. Ngoại lệ này là cố ý: nó hoàn tác toàn bộ dữ liệu thử.',
      so_dat;
  end if;
end
$ktr$;
