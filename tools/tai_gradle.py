#!/usr/bin/env python3
"""Tải gói phân phối Gradle bằng nhiều kết nối song song.

Cần tới vì đường từ đây ra các máy chủ Gradle bóp băng thông trên từng kết nối
— một luồng chỉ được chừng 15 KB/s, tám luồng thì nhanh gấp bội. Bộ tải sẵn có
của Gradle chỉ mở một kết nối, và có lần đứng hẳn.

Tải xong thì đặt tệp vào đúng chỗ Gradle tìm, giải nén sẵn và ghi dấu .ok, nên
lần build sau Gradle dùng luôn mà không tải lại.

    python tools/tai_gradle.py
"""
import concurrent.futures as cf
import glob, hashlib, io, os, sys, urllib.request, zipfile

# Console Windows mặc định không phải UTF-8; không đặt lại thì mọi dòng in ra
# có dấu tiếng Việt đều làm script chết giữa chừng.
sys.stdout.reconfigure(encoding='utf-8', errors='replace')
sys.stderr.reconfigure(encoding='utf-8', errors='replace')

URL  = 'https://mirror.nju.edu.cn/gradle/gradle-9.1.0-bin.zip'
SHA  = 'a17ddd85a26b6a7f5ddb71ff8b05fc5104c0202c6e64782429790c933686c806'
TEN  = 'gradle-9.1.0-bin.zip'
LUONG = 8


def do_lon():
    r = urllib.request.Request(URL, method='HEAD')
    with urllib.request.urlopen(r, timeout=30) as p:
        return int(p.headers['Content-Length'])


def mot_doan(so, dau, cuoi, dem):
    r = urllib.request.Request(URL, headers={'Range': 'bytes=%d-%d' % (dau, cuoi)})
    for lan in range(5):
        try:
            with urllib.request.urlopen(r, timeout=120) as p:
                d = io.BytesIO()
                while True:
                    k = p.read(262144)
                    if not k:
                        break
                    d.write(k)
                    dem[so] = d.tell()
            return so, d.getvalue()
        except Exception as e:
            if lan == 4:
                raise
            dem[so] = 0
            print('  đoạn %d lỗi (%s), thử lại' % (so, e), file=sys.stderr)


def main():
    n = do_lon()
    print('Kích thước: %.1f MB, tải bằng %d kết nối' % (n / 1048576, LUONG))

    buoc = (n + LUONG - 1) // LUONG
    dem = [0] * LUONG
    phan = [None] * LUONG
    with cf.ThreadPoolExecutor(LUONG) as bom:
        viec = [bom.submit(mot_doan, i, i * buoc, min((i + 1) * buoc, n) - 1, dem)
                for i in range(LUONG)]
        for v in cf.as_completed(viec):
            i, d = v.result()
            phan[i] = d
            print('  xong đoạn %d/%d — tổng %.0f%%'
                  % (i + 1, LUONG, sum(dem) * 100 / n))

    du_lieu = b''.join(phan)
    if len(du_lieu) != n:
        sys.exit('Tải thiếu: %d / %d byte' % (len(du_lieu), n))

    bam = hashlib.sha256(du_lieu).hexdigest()
    if bam != SHA:
        sys.exit('Mã băm không khớp — tệp hỏng hoặc bị đánh tráo.\n  nhận  %s\n  cần   %s'
                 % (bam, SHA))
    print('Mã băm khớp với công bố của gradle.org.')

    # Thư mục Gradle đặt tên theo mã băm của URL, nên không đoán được — phải
    # lấy cái Gradle đã tự tạo ở lần chạy trước.
    goc = os.path.expanduser('~/.gradle/wrapper/dists/gradle-9.1.0-bin')
    thu_muc = sorted(glob.glob(os.path.join(goc, '*', '')))
    if not thu_muc:
        sys.exit('Chưa có thư mục đích. Chạy "flutter build apk" một lần cho Gradle '
                 'tự tạo rồi dừng lại, sau đó chạy lại script này.')
    d = thu_muc[0]

    for rac in glob.glob(os.path.join(d, '*.part')) + glob.glob(os.path.join(d, '*.lck')):
        os.remove(rac)

    dich = os.path.join(d, TEN)
    with open(dich, 'wb') as f:
        f.write(du_lieu)

    with zipfile.ZipFile(dich) as z:
        z.extractall(d)
    print('Đã giải nén vào %s' % d)

    # Gradle thấy dấu này thì bỏ qua bước tải.
    open(dich + '.ok', 'w').close()
    print('Xong. Lần build tới Gradle dùng luôn bản này.')


if __name__ == '__main__':
    main()
