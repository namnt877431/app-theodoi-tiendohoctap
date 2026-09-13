#!/usr/bin/env python3
"""Đóng gói APK phát hành và kiểm tra từng file trước khi đem đi cài.

    python tools/dong_goi.py

Ra ba file trong build/app/outputs/flutter-apk/:
    app-release.apk              gộp mọi kiến trúc — gửi cho người không rõ máy gì
    app-arm64-v8a-release.apk    máy từ 2017 trở đi, nhẹ bằng một phần ba
    app-armeabi-v7a-release.apk  máy cũ 32-bit

Hai bài học đắt giá nằm trong script này:

  1. Build ba kiến trúc trong một lệnh `--split-per-abi` thì APK arm64 ra
     thiếu trọn bộ res/, AndroidManifest.xml và resources.arsc — nhưng vẫn
     được ký, nên nhìn bề ngoài không biết. Lặp lại ổn định với AGP 9.0.1.
     Build từng kiến trúc riêng thì không sao.

  2. Vì thế không tin file nào chưa mở ra đếm. Mỗi file phải đủ số mục, có
     manifest, có quyền INTERNET (khuôn mẫu Flutter chỉ khai quyền này ở bản
     debug), và ký đúng keystore phát hành chứ không phải khoá debug.
"""
import os, subprocess, sys, zipfile, glob

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

GOC = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RA  = os.path.join(GOC, 'build', 'app', 'outputs', 'flutter-apk')
ENV = os.path.join(GOC, '.env.json')

# Vân tay chứng chỉ của android/so-lien-lac.jks. Đổi keystore thì cập nhật.
VAN_TAY = 'ad918de36e1f8f63e6d40f46c02168d65c7f1dfeb085e287cd2fb7f06bad8e33'


def build_tools():
    sdk = os.environ.get('ANDROID_HOME') or os.path.expanduser('~/AppData/Local/Android/Sdk')
    ds = sorted(glob.glob(os.path.join(sdk, 'build-tools', '*')))
    if not ds:
        sys.exit('Không thấy Android build-tools trong ' + sdk)
    return ds[-1]


def chay(*args):
    print('  $ flutter', ' '.join(args))
    r = subprocess.run(['flutter', *args, '--dart-define-from-file=' + ENV],
                       cwd=GOC, shell=True, capture_output=True, text=True,
                       encoding='utf-8', errors='replace')
    if r.returncode != 0:
        print(r.stdout[-3000:], r.stderr[-3000:])
        sys.exit('Build hỏng.')
    print('   ', [l for l in r.stdout.splitlines() if 'Built' in l][-1].strip())


def kiem(ten, bt):
    p = os.path.join(RA, ten)
    loi = []
    with zipfile.ZipFile(p) as z:
        ds = z.namelist()
    if 'AndroidManifest.xml' not in ds:
        loi.append('thiếu AndroidManifest.xml (%d mục — bản cụt)' % len(ds))
    if not any(d.startswith('res/') for d in ds):
        loi.append('thiếu thư mục res/')

    q = subprocess.run([os.path.join(bt, 'aapt2.exe'), 'dump', 'permissions', p],
                       capture_output=True, text=True, encoding='utf-8', errors='replace')
    if 'android.permission.INTERNET' not in q.stdout:
        loi.append('không có quyền INTERNET')

    k = subprocess.run([os.path.join(bt, 'apksigner.bat'), 'verify', '--print-certs', p],
                       capture_output=True, text=True, shell=True,
                       encoding='utf-8', errors='replace')
    if VAN_TAY not in k.stdout.lower():
        loi.append('chữ ký không phải keystore phát hành')

    mb = os.path.getsize(p) / 1048576
    if loi:
        print('  ✗ %-28s %5.1f MB  ' % (ten, mb) + '; '.join(loi))
    else:
        print('  ✓ %-28s %5.1f MB  %d mục' % (ten, mb, len(ds)))
    return not loi


def main():
    if not os.path.exists(ENV):
        sys.exit('Thiếu .env.json — xem README, bước 5.')
    if not os.path.exists(os.path.join(GOC, 'android', 'key.properties')):
        sys.exit('Thiếu android/key.properties — APK sẽ ký bằng khoá debug. Xem README, phần 3.')

    for f in glob.glob(os.path.join(RA, '*.apk')) + glob.glob(os.path.join(RA, '*.sha1')):
        os.remove(f)

    print('Build:')
    chay('build', 'apk', '--release')
    chay('build', 'apk', '--release', '--split-per-abi', '--target-platform', 'android-arm64')
    chay('build', 'apk', '--release', '--split-per-abi', '--target-platform', 'android-arm')

    print('Kiểm:')
    bt = build_tools()
    ok = all([kiem('app-release.apk', bt),
              kiem('app-arm64-v8a-release.apk', bt),
              kiem('app-armeabi-v7a-release.apk', bt)])
    if not ok:
        sys.exit('\nCó file hỏng — đừng phát đi.')
    print('\nCả ba file đạt. Thư mục:', RA)


if __name__ == '__main__':
    main()
