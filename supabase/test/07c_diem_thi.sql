
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
     $q$delete from diem_thi where id = 'eeeeeeee-0000-0000-0000-000000000001'$q$, 0),
