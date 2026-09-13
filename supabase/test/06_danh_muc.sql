
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

