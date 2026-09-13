    -- --------------------------------------------------------- kho ảnh
    -- Đường dẫn là {hoc_sinh_id}/{tên tệp}. Thư mục đầu tiên chính là id học
    -- sinh, nên policy dùng lại đúng hàm xem_duoc() với phần dữ liệu còn lại.
    --
    -- Đọc trước, tải lên sau — để phép đếm không bị chính ảnh mình vừa tải lên
    -- làm sai lệch.
    --
    -- Không có phép thử nào cho việc XÓA ảnh. Supabase chặn DELETE thẳng vào
    -- storage.objects bằng trigger, nổ trước cả RLS ("Direct deletion from
    -- storage tables is not allowed"). Nên từ SQL không phân biệt nổi "bị
    -- policy chặn" với "bị nền tảng chặn", và một phép thử đạt vì lý do sai
    -- còn tệ hơn không có phép thử. Policy xóa ở 04_storage.sql vẫn đúng và
    -- vẫn có tác dụng — app xóa qua Storage API, đường đó có đi qua RLS.

    ('HS xem được ảnh bài làm của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from storage.objects
         where name like '33333333-3333-3333-3333-333333333333/%'$q$, 1),

    ('HS không xem được ảnh bài làm của bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'thay',
     $q$select 1 from storage.objects
         where name like '44444444-4444-4444-4444-444444444444/%'$q$, 0),

    ('PH xem được ảnh bài làm của con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'thay',
     $q$select 1 from storage.objects
         where name like '33333333-3333-3333-3333-333333333333/%'$q$, 1),

    ('PH lạ không xem được ảnh bài làm của trẻ lạ',
     '22222222-2222-2222-2222-222222222222'::uuid, 'thay',
     $q$select 1 from storage.objects$q$, 0),

    ('Khách chưa đăng nhập không xem được ảnh nào',
     null::uuid, 'chan', $q$select 1 from storage.objects$q$, 0),

    ('HS tải được ảnh vào thư mục của mình',
     '33333333-3333-3333-3333-333333333333'::uuid, 'duoc',
     $q$insert into storage.objects (bucket_id, name)
        values ('bai-lam', '33333333-3333-3333-3333-333333333333/moi.jpg')$q$, 0),

    ('HS không tải ảnh vào thư mục bạn khác',
     '33333333-3333-3333-3333-333333333333'::uuid, 'chan',
     $q$insert into storage.objects (bucket_id, name)
        values ('bai-lam', '44444444-4444-4444-4444-444444444444/chen.jpg')$q$, 0),

    ('PH không tải ảnh thay con',
     '11111111-1111-1111-1111-111111111111'::uuid, 'chan',
     $q$insert into storage.objects (bucket_id, name)
        values ('bai-lam', '33333333-3333-3333-3333-333333333333/bo-tai.jpg')$q$, 0),

