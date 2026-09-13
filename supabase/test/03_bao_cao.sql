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

