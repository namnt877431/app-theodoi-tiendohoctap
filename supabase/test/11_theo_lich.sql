
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
