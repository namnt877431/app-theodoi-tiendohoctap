
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
