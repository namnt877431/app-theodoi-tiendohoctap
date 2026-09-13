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

