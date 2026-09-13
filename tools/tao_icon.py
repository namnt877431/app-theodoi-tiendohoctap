#!/usr/bin/env python3
"""Sinh icon ứng dụng.

Hình là một quyển vở đóng, nhìn thẳng: gáy đỏ bên trái, trang giấy trắng, mấy
dòng kẻ xanh. Không phải quyển sách mở như phần lớn icon giáo dục — trang vở có
gáy là đúng thứ app này vẽ ở mọi màn hình (xem lib/core/widgets/trang_vo.dart),
và ở cỡ 48dp thì một khối đứng có dải màu chạy dọc một cạnh đọc ra "quyển sách"
nhanh hơn hẳn hình sách mở.

Màu lấy nguyên từ lib/core/theme/tokens.dart.

    python tools/tao_icon.py

Ghi đè thẳng vào android/app/src/main/res/mipmap-*/.
"""
import os
from PIL import Image, ImageDraw

GOC = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(GOC, 'android', 'app', 'src', 'main', 'res')

INK      = (0x0E, 0x2E, 0x52)
MUC      = (0x1D, 0x5F, 0xA8)
MUC_NHAT = (0x5B, 0x7C, 0xA3)
GIAY     = (0xFB, 0xFC, 0xFE)
DONG_KE  = (0xDD, 0xE7, 0xF2)
BUT_DO   = (0xD6, 0x45, 0x45)

# Vẽ to gấp bốn rồi thu nhỏ — cạnh xiên và góc bo mới mịn.
PHONG = 4

# Mật độ màn hình Android. Icon thường 48dp, icon thích ứng 108dp.
MAT_DO = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}


def nen(canh, bo_goc):
    """Nền chuyển sắc từ mực sang mực đậm, tối dần xuống dưới."""
    anh = Image.new('RGBA', (canh, canh), (0, 0, 0, 0))
    ve = ImageDraw.Draw(anh)
    for y in range(canh):
        p = y / max(canh - 1, 1)
        ve.line([(0, y), (canh, y)],
                fill=tuple(round(MUC[i] + (INK[i] - MUC[i]) * p) for i in range(3)) + (255,))
    if bo_goc:
        mat = Image.new('L', (canh, canh), 0)
        ImageDraw.Draw(mat).rounded_rectangle(
            [0, 0, canh - 1, canh - 1], radius=round(canh * 0.22), fill=255)
        anh.putalpha(mat)
    return anh


def quyen_vo(anh, tam, rong):
    """Vẽ quyển vở vào giữa ảnh, bề ngang chiếm `rong` phần khung."""
    ve = ImageDraw.Draw(anh)
    canh = anh.size[0]
    w = canh * rong
    h = w * 1.28                      # dáng đứng, tỉ lệ gần một quyển vở thật
    x0, y0 = tam[0] - w / 2, tam[1] - h / 2
    x1, y1 = x0 + w, y0 + h
    r = w * 0.06

    # Mép các trang bên trong, lộ ra một dải mỏng bên phải.
    ve.rounded_rectangle([x0 + w * 0.05, y0 + h * 0.025, x1 + w * 0.04, y1 - h * 0.025],
                         radius=r, fill=DONG_KE + (255,))

    # Bìa và trang.
    ve.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=GIAY + (255,))

    # Gáy: vừa là gáy sách, vừa là đường kẻ lề đỏ của trang vở.
    gay = x0 + w * 0.155
    ve.rounded_rectangle([x0, y0, gay, y1], radius=r, fill=BUT_DO + (255,))
    ve.rectangle([gay - r, y0, gay, y1], fill=BUT_DO + (255,))

    # Dòng kẻ. Dòng cuối ngắn lại, cho ra cảm giác một đoạn viết dở.
    day = h * 0.045
    tu  = gay + w * 0.13
    for i, den in enumerate([0.80, 0.80, 0.55]):
        y = y0 + h * (0.34 + i * 0.17)
        ve.rounded_rectangle([tu, y, x0 + w * den, y + day],
                             radius=day / 2, fill=MUC_NHAT + (255,))


def dung(canh, bo_goc=True, rong=0.50, co_nen=True):
    lon = canh * PHONG
    anh = nen(lon, bo_goc) if co_nen else Image.new('RGBA', (lon, lon), (0, 0, 0, 0))
    quyen_vo(anh, (lon / 2, lon / 2), rong)
    return anh.resize((canh, canh), Image.LANCZOS)


def tron(canh):
    anh = dung(canh, bo_goc=False)
    mat = Image.new('L', (canh * PHONG, canh * PHONG), 0)
    ImageDraw.Draw(mat).ellipse([0, 0, canh * PHONG - 1, canh * PHONG - 1], fill=255)
    anh.putalpha(mat.resize((canh, canh), Image.LANCZOS))
    return anh


def ghi(anh, thu_muc, ten):
    d = os.path.join(RES, thu_muc)
    os.makedirs(d, exist_ok=True)
    anh.save(os.path.join(d, ten + '.png'))
    return '%s/%s.png %dx%d' % (thu_muc, ten, anh.size[0], anh.size[1])


def main():
    ra = []
    for ten_md, he_so in MAT_DO.items():
        tm = 'mipmap-' + ten_md

        ra.append(ghi(dung(round(48 * he_so)), tm, 'ic_launcher'))
        ra.append(ghi(tron(round(48 * he_so)), tm, 'ic_launcher_round'))

        # Icon thích ứng: khung 108dp nhưng chỉ 72dp ở giữa chắc chắn không bị
        # mặt nạ của launcher cắt mất, nên hình phải co lại nằm gọn trong đó.
        c = round(108 * he_so)
        ra.append(ghi(nen(c * PHONG, False).resize((c, c), Image.LANCZOS),
                      tm, 'ic_launcher_background'))
        ra.append(ghi(dung(c, bo_goc=False, rong=0.32, co_nen=False),
                      tm, 'ic_launcher_foreground'))

    xml = ('<?xml version="1.0" encoding="utf-8"?>\n'
           '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
           '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
           '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
           '</adaptive-icon>\n')
    d = os.path.join(RES, 'mipmap-anydpi-v26')
    os.makedirs(d, exist_ok=True)
    for ten in ('ic_launcher.xml', 'ic_launcher_round.xml'):
        with open(os.path.join(d, ten), 'w', encoding='utf-8', newline='\n') as f:
            f.write(xml)
        ra.append('mipmap-anydpi-v26/' + ten)

    # Bản to để xem thử cho rõ.
    xem = os.path.join(GOC, 'tools', 'icon_xem_thu.png')
    dung(512).save(xem)
    ra.append('tools/icon_xem_thu.png 512x512')

    # Icon bản web (PWA): thường và maskable — maskable thì hình co lại giữa
    # nền, như icon thích ứng của Android.
    web = os.path.join(GOC, 'web', 'icons')
    for c in (192, 512):
        ra.append(ghi(dung(c, bo_goc=False), web, 'Icon-%d' % c))
        ra.append(ghi(dung(c, bo_goc=False, rong=0.36), web, 'Icon-maskable-%d' % c))
    ra.append(ghi(dung(64), os.path.join(GOC, 'web'), 'favicon'))

    print('\n'.join(ra))


if __name__ == '__main__':
    main()
