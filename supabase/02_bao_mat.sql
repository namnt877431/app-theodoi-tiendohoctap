-- =============================================================================
-- Phân quyền
--
-- Nguyên tắc: dữ liệu học tập là dữ liệu của trẻ con, nên mặc định là cấm.
-- Một người chỉ chạm được vào dữ liệu của học sinh X khi họ chính là X, là phụ
-- huynh đã được nối với X, hoặc là quản trị.
-- =============================================================================

-- Ba hàm trợ giúp. Đều là `security definer` để tự chúng đọc bảng mà không bị
-- chính RLS chặn lại — nếu không sẽ đệ quy vô hạn khi policy trên nguoi_dung
-- lại phải đọc nguoi_dung.
create or replace function la_quan_tri() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from nguoi_dung
     where id = auth.uid() and vai_tro = 'quanTri' and hoat_dong
  );
$$;

-- Không có ai đăng nhập cả: lệnh đến từ SQL Editor, từ psql, hoặc từ khóa
-- service_role. Ba đường đó đều nằm phía máy chủ và đều đáng tin.
--
-- Cần hàm này vì trigger chạy với MỌI kết nối — `postgres` được miễn RLS nhưng
-- không được miễn trigger. Thiếu nó thì chính người quản trị cũng không phong
-- nổi quản trị đầu tiên, vì chưa có ai là quản trị để `la_quan_tri()` đúng.
--
-- Không nới lỏng gì: người chưa đăng nhập đi qua API cũng có auth.uid() null,
-- nhưng vai trò `anon` đã bị thu hồi sạch quyền ghi trên mọi bảng ở file 01
-- (chỉ còn đọc được tỉnh và trường, mà đọc thì không làm trigger nổ), nên họ
-- không bao giờ chạm tới được câu lệnh làm trigger nổ.
create or replace function la_phia_may_chu() returns boolean
language sql stable as $$ select auth.uid() is null; $$;

create or replace function la_phu_huynh_cua(p_hoc_sinh uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from lien_ket
     where phu_huynh_id = auth.uid() and hoc_sinh_id = p_hoc_sinh
  );
$$;

create or replace function xem_duoc(p_hoc_sinh uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select p_hoc_sinh = auth.uid()
      or la_phu_huynh_cua(p_hoc_sinh)
      or la_quan_tri();
$$;

alter table nguoi_dung enable row level security;
alter table lien_ket   enable row level security;
alter table mon_hoc    enable row level security;
alter table bai_hoc    enable row level security;
alter table giao_vien  enable row level security;
alter table tinh       enable row level security;
alter table truong     enable row level security;
alter table tiet_hoc   enable row level security;
alter table bao_cao    enable row level security;
alter table nhac_nho   enable row level security;
alter table ma_moi     enable row level security;

-- ----------------------------------------------------------------- người dùng

drop policy if exists nd_doc on nguoi_dung;
create policy nd_doc on nguoi_dung for select to authenticated
  using (id = auth.uid() or la_phu_huynh_cua(id) or la_quan_tri());

-- Đăng ký: tự tạo hồ sơ cho chính mình, không tự phong quản trị.
drop policy if exists nd_tao on nguoi_dung;
create policy nd_tao on nguoi_dung for insert to authenticated
  with check (id = auth.uid() and vai_tro in ('phuHuynh', 'hocSinh') and hoat_dong);

drop policy if exists nd_sua on nguoi_dung;
create policy nd_sua on nguoi_dung for update to authenticated
  using (id = auth.uid() or la_quan_tri())
  with check (id = auth.uid() or la_quan_tri());

drop policy if exists nd_xoa on nguoi_dung;
create policy nd_xoa on nguoi_dung for delete to authenticated
  using (la_quan_tri());

-- RLS so được hàng cũ ở `using` và hàng mới ở `with check`, nhưng không so
-- được hai bên với nhau trong cùng một biểu thức. Việc "không được tự đổi vai
-- trò" cần đúng phép so đó, nên giao cho trigger.
create or replace function chan_tu_nang_quyen() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if la_phia_may_chu() or la_quan_tri() then
    return new;
  end if;
  if new.vai_tro is distinct from old.vai_tro then
    raise exception 'Không được tự đổi vai trò';
  end if;
  if new.hoat_dong is distinct from old.hoat_dong then
    raise exception 'Không được tự khóa hay mở khóa tài khoản';
  end if;
  return new;
end $$;

drop trigger if exists nguoi_dung_chan_tu_nang_quyen on nguoi_dung;
create trigger nguoi_dung_chan_tu_nang_quyen
  before update on nguoi_dung
  for each row execute function chan_tu_nang_quyen();

-- -------------------------------------------------------------------- liên kết

drop policy if exists lk_doc on lien_ket;
create policy lk_doc on lien_ket for select to authenticated
  using (phu_huynh_id = auth.uid() or hoc_sinh_id = auth.uid() or la_quan_tri());

-- Không ai tự chèn một dòng liên kết. Đường duy nhất là hàm dung_ma_moi() bên
-- dưới, hoặc quản trị gán tay.
drop policy if exists lk_tao on lien_ket;
create policy lk_tao on lien_ket for insert to authenticated
  with check (la_quan_tri());

drop policy if exists lk_xoa on lien_ket;
create policy lk_xoa on lien_ket for delete to authenticated
  using (phu_huynh_id = auth.uid() or la_quan_tri());

-- --------------------------------------------------------- danh mục dùng chung

drop policy if exists mh_doc on mon_hoc;
create policy mh_doc on mon_hoc for select to authenticated using (true);
drop policy if exists mh_ghi on mon_hoc;
create policy mh_ghi on mon_hoc for all to authenticated
  using (la_quan_tri()) with check (la_quan_tri());

-- Bài học: ai đăng nhập cũng đọc, chỉ quản trị sửa (tóm tắt, câu hỏi).
drop policy if exists bh_doc on bai_hoc;
create policy bh_doc on bai_hoc for select to authenticated using (true);
drop policy if exists bh_ghi on bai_hoc;
create policy bh_ghi on bai_hoc for all to authenticated
  using (la_quan_tri()) with check (la_quan_tri());

-- Quản trị sửa tóm tắt hay câu hỏi trong app thì đánh dấu sua_tay, để lần chạy
-- lại file dữ liệu 09_bai_hoc_lop*.sql (chạy từ SQL Editor, không có auth.uid)
-- không ghi đè công sức đó.
create or replace function danh_dau_bai_hoc_sua_tay() returns trigger
language plpgsql as $$
begin
  if not la_phia_may_chu()
     and (new.tom_tat is distinct from old.tom_tat
          or new.kiem_tra is distinct from old.kiem_tra) then
    new.sua_tay := true;
  end if;
  new.cap_nhat_luc := now();
  return new;
end $$;

drop trigger if exists bai_hoc_sua_tay on bai_hoc;
create trigger bai_hoc_sua_tay
  before update on bai_hoc
  for each row execute function danh_dau_bai_hoc_sua_tay();

-- Tỉnh và trường: ai cũng đọc được, kể cả khách chưa đăng nhập — màn đăng ký
-- cần danh sách trường trước khi có tài khoản. Chỉ quản trị sửa.
drop policy if exists tinh_doc on tinh;
create policy tinh_doc on tinh for select to anon, authenticated using (true);
drop policy if exists tinh_ghi on tinh;
create policy tinh_ghi on tinh for all to authenticated
  using (la_quan_tri()) with check (la_quan_tri());

drop policy if exists tr_doc on truong;
create policy tr_doc on truong for select to anon, authenticated using (true);
drop policy if exists tr_ghi on truong;
create policy tr_ghi on truong for all to authenticated
  using (la_quan_tri()) with check (la_quan_tri());

-- Thầy cô: hàng có `chu_id` null là danh mục chung, ai cũng thấy. Hàng có
-- `chu_id` là thầy dạy thêm riêng của một học sinh — chỉ em đó, bố mẹ em đó và
-- quản trị thấy, giống mọi dữ liệu khác của em.
drop policy if exists gv_doc on giao_vien;
create policy gv_doc on giao_vien for select to authenticated
  using (chu_id is null or xem_duoc(chu_id));

-- Quản trị ghi được tất cả. Học sinh (và bố mẹ khai hộ) chỉ thêm/sửa/xóa
-- được thầy dạy thêm của chính nhà mình: `chu_id` phải có, và phải là người
-- mình xem được. Không có đường nào để tự biến thầy riêng thành thầy chung.
drop policy if exists gv_ghi on giao_vien;
create policy gv_ghi on giao_vien for all to authenticated
  using (la_quan_tri()
         or (chu_id is not null and loai = 'hocThem' and xem_duoc(chu_id)))
  with check (la_quan_tri()
              or (chu_id is not null and loai = 'hocThem' and xem_duoc(chu_id)));

-- --------------------------------------------------------------- thời khóa biểu

-- Cả học sinh lẫn phụ huynh đều xếp được tiết, vì nhiều nhà bố mẹ là người
-- ngồi khai hộ đầu năm.
drop policy if exists th_moi on tiet_hoc;
create policy th_moi on tiet_hoc for all to authenticated
  using (xem_duoc(hoc_sinh_id)) with check (xem_duoc(hoc_sinh_id));

-- ------------------------------------------------------------------- báo cáo

drop policy if exists bc_doc on bao_cao;
create policy bc_doc on bao_cao for select to authenticated
  using (xem_duoc(hoc_sinh_id));

-- Báo cáo là lời của học sinh. Chỉ chính em ấy viết và xóa.
drop policy if exists bc_tao on bao_cao;
create policy bc_tao on bao_cao for insert to authenticated
  with check (hoc_sinh_id = auth.uid());

drop policy if exists bc_xoa on bao_cao;
create policy bc_xoa on bao_cao for delete to authenticated
  using (hoc_sinh_id = auth.uid() or la_quan_tri());

-- Phụ huynh qua được cửa này, nhưng trigger bên dưới giới hạn họ chỉ chạm
-- được vào lời nhận xét và dấu đã xem.
drop policy if exists bc_sua on bao_cao;
create policy bc_sua on bao_cao for update to authenticated
  using (xem_duoc(hoc_sinh_id)) with check (xem_duoc(hoc_sinh_id));

create or replace function chan_phu_huynh_sua_bao_cao() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if la_phia_may_chu() or new.hoc_sinh_id = auth.uid() or la_quan_tri() then
    return new;
  end if;
  -- Còn lại là phụ huynh: chỉ được viết nhận xét, đúng như dòng chữ đỏ thầy cô
  -- ghi cuối trang vở — không sửa được bài của học trò.
  if new.noi_dung     is distinct from old.noi_dung
  or new.trang_thai   is distinct from old.trang_thai
  or new.ngay         is distinct from old.ngay
  or new.loai         is distinct from old.loai
  or new.mon_id       is distinct from old.mon_id
  or new.giao_vien_id is distinct from old.giao_vien_id
  or new.bai_hoc_id   is distinct from old.bai_hoc_id
  or new.anh          is distinct from old.anh
  or new.so_phut      is distinct from old.so_phut
  or new.hoc_sinh_id  is distinct from old.hoc_sinh_id then
    raise exception 'Phụ huynh chỉ được viết nhận xét, không sửa nội dung báo cáo';
  end if;
  return new;
end $$;

drop trigger if exists bao_cao_chan_phu_huynh on bao_cao;
create trigger bao_cao_chan_phu_huynh
  before update on bao_cao
  for each row execute function chan_phu_huynh_sua_bao_cao();

-- ------------------------------------------------------------------ nhắc nhở

drop policy if exists nn_doc on nhac_nho;
create policy nn_doc on nhac_nho for select to authenticated
  using (xem_duoc(den_id));

drop policy if exists nn_tao on nhac_nho;
create policy nn_tao on nhac_nho for insert to authenticated
  with check (la_phu_huynh_cua(den_id) and tu_id = auth.uid() and not da_doc);

-- Chỉ học sinh đánh dấu đã đọc. Phụ huynh không đánh dấu hộ, nếu không cái dấu
-- "con đã đọc" chẳng còn nghĩa gì.
drop policy if exists nn_sua on nhac_nho;
create policy nn_sua on nhac_nho for update to authenticated
  using (den_id = auth.uid() or la_quan_tri())
  with check (den_id = auth.uid() or la_quan_tri());

create or replace function chan_sua_noi_dung_nhac_nho() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if la_phia_may_chu() or la_quan_tri() then
    return new;
  end if;
  if new.noi_dung is distinct from old.noi_dung
  or new.tu_id    is distinct from old.tu_id
  or new.den_id   is distinct from old.den_id
  or new.han_luc  is distinct from old.han_luc then
    raise exception 'Chỉ được đánh dấu đã đọc, không sửa nội dung lời nhắc';
  end if;
  return new;
end $$;

drop trigger if exists nhac_nho_chan_sua on nhac_nho;
create trigger nhac_nho_chan_sua
  before update on nhac_nho
  for each row execute function chan_sua_noi_dung_nhac_nho();

drop policy if exists nn_xoa on nhac_nho;
create policy nn_xoa on nhac_nho for delete to authenticated
  using (tu_id = auth.uid() or la_quan_tri());

-- -------------------------------------------------------------------- mã mời

-- Phụ huynh không đọc bảng này. Họ chỉ gọi hàm dung_ma_moi() và hàm đó tự tra.
-- Nhờ vậy không ai dò được mã của người khác.
drop policy if exists mm_doc on ma_moi;
create policy mm_doc on ma_moi for select to authenticated
  using (hoc_sinh_id = auth.uid() or la_quan_tri());

drop policy if exists mm_tao on ma_moi;
create policy mm_tao on ma_moi for insert to authenticated
  with check (hoc_sinh_id = auth.uid() and not da_dung);

drop policy if exists mm_sua on ma_moi;
create policy mm_sua on ma_moi for update to authenticated
  using (hoc_sinh_id = auth.uid() or la_quan_tri())
  with check (hoc_sinh_id = auth.uid() or la_quan_tri());

drop policy if exists mm_xoa on ma_moi;
create policy mm_xoa on ma_moi for delete to authenticated
  using (hoc_sinh_id = auth.uid() or la_quan_tri());

-- ------------------------------------------------------------------- đăng ký

-- Hồ sơ được tạo bởi trigger trên auth.users chứ không để client tự chèn.
--
-- Hai cái lợi: người dùng có hồ sơ ngay cả khi bật xác thực email (lúc đó
-- signUp chưa trả về phiên nên client không ghi được gì), và vai trò bị kẹp
-- lại ở đây — client gửi lên 'quanTri' thì cũng thành 'hocSinh'.
create or replace function tao_ho_so_sau_dang_ky() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_truong public.truong;
begin
  -- Trường tra trong danh mục; client gửi id lạ thì coi như chưa chọn, không
  -- để lỗi khóa ngoại làm hỏng cả lượt đăng ký. Tên trường ghi kèm vào cột
  -- chữ `truong` để mở bảng ra vẫn đọc được.
  select * into v_truong from public.truong
   where id = new.raw_user_meta_data ->> 'truong_id';

  insert into public.nguoi_dung
    (id, ho_ten, vai_tro, email, so_dien_thoai, lop, truong, truong_id)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'ho_ten'), ''), 'Người dùng mới'),
    case
      when new.raw_user_meta_data ->> 'vai_tro' in ('phuHuynh', 'hocSinh')
      then new.raw_user_meta_data ->> 'vai_tro'
      else 'hocSinh'
    end,
    new.email,
    nullif(trim(new.raw_user_meta_data ->> 'so_dien_thoai'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'lop'), ''),
    coalesce(v_truong.ten, nullif(trim(new.raw_user_meta_data ->> 'truong'), '')),
    v_truong.id
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function tao_ho_so_sau_dang_ky();
