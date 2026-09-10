# Kiểm thử luật bảo mật

Chứng minh bằng hành vi rằng [firestore.rules](../firestore.rules) thật sự chặn
đúng chỗ: phụ huynh lạ không đọc được báo cáo của con nhà khác, không ai tự
phong mình làm quản trị, và không nối được tài khoản nếu không cầm mã mời hợp lệ.

## Chạy

Cần **Node 18+**, **JDK 21+** và Firebase CLI (`npm i -g firebase-tools`).

```bash
cd test_rules
npm install
npm test
```

Emulator tự khởi động, chạy hết bộ test rồi tắt. Không cần tài khoản Firebase —
`demo-solienlac` là project ảo chạy hoàn toàn cục bộ.

## Vì sao chạy tuần tự

`--test-concurrency=1` là bắt buộc, không phải cho chậm lại. Cả ba file dùng
chung một emulator và mỗi test đều gọi `clearFirestore()`, nên chạy song song
thì chúng xóa dữ liệu của nhau giữa chừng và báo lỗi giả.

## JDK

Firebase CLI cần JDK 21 trở lên. Máy đã cài Android Studio thì có sẵn:

```bash
export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"
export PATH="$JAVA_HOME/bin:$PATH"
```
