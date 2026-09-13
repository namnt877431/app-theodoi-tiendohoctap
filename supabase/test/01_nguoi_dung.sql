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

