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

