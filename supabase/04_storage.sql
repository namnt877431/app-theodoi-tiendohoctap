-- =============================================================================
-- Kho ảnh bài làm
--
-- Ảnh nằm ở bucket `bai-lam`, đường dẫn `{hoc_sinh_id}/{tên tệp}.jpg`.
-- Bucket để riêng tư; app lấy ảnh bằng URL ký có hạn, không phát tán link công
-- khai — đây là ảnh vở của trẻ con.
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('bai-lam', 'bai-lam', false, 8388608,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public             = false,
      file_size_limit    = 8388608,
      allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

-- Thư mục đầu tiên trong đường dẫn chính là id học sinh, nên phép kiểm tra
-- quyền dùng chung đúng hàm xem_duoc() với phần dữ liệu còn lại.
drop policy if exists anh_doc on storage.objects;
create policy anh_doc on storage.objects for select to authenticated
  using (
    bucket_id = 'bai-lam'
    and xem_duoc(((storage.foldername(name))[1])::uuid)
  );

-- Chỉ học sinh tự đưa ảnh bài của mình lên.
drop policy if exists anh_tai_len on storage.objects;
create policy anh_tai_len on storage.objects for insert to authenticated
  with check (
    bucket_id = 'bai-lam'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Xóa đi qua Storage API chứ không phải DELETE thẳng vào bảng — Supabase chặn
-- đường đó bằng trigger riêng. Policy này vẫn là thứ quyết định ai xóa được gì,
-- chỉ là bộ kiểm thử SQL không với tới được; xem supabase/test/05_kho_anh.sql.
drop policy if exists anh_xoa on storage.objects;
create policy anh_xoa on storage.objects for delete to authenticated
  using (
    bucket_id = 'bai-lam'
    and ((storage.foldername(name))[1] = auth.uid()::text or la_quan_tri())
  );
