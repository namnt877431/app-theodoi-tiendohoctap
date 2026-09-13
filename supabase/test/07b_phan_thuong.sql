
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
     $q$update phan_thuong set trao_luc = now(), tu_ngay = current_date
         where id = 'dddddddd-0000-0000-0000-000000000001'$q$, 0),

    ('PH xóa được phần thưởng mình treo',
     '11111111-1111-1111-1111-111111111111'::uuid, 'duoc',
     $q$delete from phan_thuong
         where id = 'dddddddd-0000-0000-0000-000000000001'$q$, 0),
