#!/usr/bin/env python3
"""Build bản web rồi đẩy thẳng lên nhánh gh-pages của repo — không cần GitHub Actions.

    python tools/dua_len_web.py

Cần `.env.json` (địa chỉ và khóa Supabase) cạnh pubspec.yaml, và remote `origin`
đã trỏ về GitHub. Trang lên tại https://<tài-khoản>.github.io/<tên-repo>/ sau
một hai phút, với điều kiện Settings → Pages của repo chọn nguồn là nhánh
`gh-pages` (script tự đặt bằng `gh` nếu có).

Nhánh gh-pages chỉ chứa sản phẩm build, mỗi lần đẩy là một commit mới đè lên
lịch sử cũ — không ai sửa tay trên đó nên không mất gì.
"""
import io
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

GOC = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(GOC, 'build', 'web')


def chay(lenh, cwd=GOC, im=False, env=None):
    if not im:
        print('  $', ' '.join(lenh))
    r = subprocess.run(lenh, cwd=cwd, env=env, capture_output=True, text=True,
                       encoding='utf-8', errors='replace', shell=os.name == 'nt')
    if r.returncode != 0:
        print(r.stdout[-2000:])
        print(r.stderr[-2000:])
        raise SystemExit(f'Lệnh hỏng (mã {r.returncode}): {" ".join(lenh)}')
    return r.stdout.strip()


def main():
    remote = chay(['git', 'remote', 'get-url', 'origin'], im=True)
    m = re.search(r'github\.com[:/]([^/]+)/([^/.]+)', remote)
    if not m:
        raise SystemExit(f'Remote origin không phải GitHub: {remote}')
    chu, repo = m.groups()
    base = f'/{repo}/'

    env = os.path.join(GOC, '.env.json')
    dinh_nghia = []
    if os.path.exists(env):
        dinh_nghia = ['--dart-define-from-file=.env.json']
    else:
        print('Không thấy .env.json — bản web sẽ chạy bằng dữ liệu mẫu.')

    print(f'Build web, base-href {base}')
    if os.path.isdir(WEB):
        shutil.rmtree(WEB)
    # --no-wasm-dry-run: khỏi biên dịch thử wasm, tiết kiệm nửa thời gian build.
    chay(['flutter', 'build', 'web', '--release', '--no-wasm-dry-run', '--base-href', base, *dinh_nghia])

    # Pages mặc định chạy Jekyll, sẽ bỏ qua thư mục bắt đầu bằng dấu gạch dưới
    # — Flutter không có, nhưng tắt hẳn cho chắc.
    io.open(os.path.join(WEB, '.nojekyll'), 'w').close()

    print('Đẩy lên nhánh gh-pages')
    # Không tạo repo lồng trong build/web (Windows hay giữ file, xóa .git dở
    # dang rồi git lại trèo lên repo mẹ). Thay vào đó ghi thẳng một commit mồ
    # côi vào repo chính bằng một index tạm: cây = nội dung build/web.
    index_tam = os.path.join(GOC, '.git', 'index.ghpages')
    if os.path.exists(index_tam):
        os.remove(index_tam)
    moi_truong = dict(os.environ, GIT_INDEX_FILE=index_tam)
    try:
        chay(['git', '--work-tree=build/web', 'add', '-A', '-f', '.'], env=moi_truong, im=True)
        cay = chay(['git', 'write-tree'], env=moi_truong, im=True)
        commit = chay(['git', 'commit-tree', cay, '-m', f'Web {datetime.now():%Y-%m-%d %H:%M}'],
                      env=moi_truong, im=True)
    finally:
        if os.path.exists(index_tam):
            os.remove(index_tam)
    chay(['git', 'update-ref', 'refs/heads/gh-pages', commit], im=True)
    chay(['git', 'push', '-f', 'origin', 'gh-pages'])

    # Trỏ Pages vào nhánh này nếu có gh; không có thì chỉ nhắc.
    if shutil.which('gh'):
        truong = ['-f', 'build_type=legacy', '-f', 'source[branch]=gh-pages', '-f', 'source[path]=/']
        # PUT sửa cấu hình đã có; repo chưa bật Pages thì phải POST để tạo.
        for pp in ('PUT', 'POST'):
            r = subprocess.run(['gh', 'api', '-X', pp, f'repos/{chu}/{repo}/pages', *truong],
                               capture_output=True, text=True, shell=os.name == 'nt')
            if r.returncode == 0:
                break
        else:
            print('Không tự đặt được nguồn Pages — vào Settings → Pages chọn nhánh gh-pages.')
    else:
        print('Vào Settings → Pages của repo, chọn Source = Deploy from a branch, nhánh gh-pages.')

    print(f'\nXong. Một hai phút nữa xem tại https://{chu}.github.io{base}')


if __name__ == '__main__':
    main()
