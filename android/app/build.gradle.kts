import java.util.Properties

// Khóa ký bản phát hành. File này không nằm trong repo — mỗi người tự tạo theo
// hướng dẫn ở README. Không có nó thì vẫn build được, chỉ là ký bằng khóa debug
// để `flutter run --release` chạy được ngay.
val khoaKy = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val coKhoaKy = khoaKy.getProperty("storeFile") != null

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Thông báo đẩy qua FCM cần google-services.json (tải từ Firebase Console,
// xem README). Plugin google-services làm build hỏng khi thiếu file, nên chỉ
// áp dụng khi file có mặt — không có thì app vẫn build, chỉ không có thông
// báo đẩy.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.warn("Không thấy android/app/google-services.json — build không có thông báo đẩy.")
}

android {
    namespace = "vn.hoctap.theodoi_hoctap"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "vn.hoctap.theodoi_hoctap"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (coKhoaKy) {
            create("phat_hanh") {
                storeFile = file(khoaKy.getProperty("storeFile"))
                storePassword = khoaKy.getProperty("storePassword")
                keyAlias = khoaKy.getProperty("keyAlias")
                keyPassword = khoaKy.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (coKhoaKy) {
                signingConfigs.getByName("phat_hanh")
            } else {
                signingConfigs.getByName("debug")
            }
            // Không rút gọn mã. Với app Flutter thì phần lớn dung lượng nằm ở
            // bản dịch Dart và engine .so — R8 không đụng tới được, nó chỉ gọt
            // lớp Java/Kotlin, đâu đó một hai MB trên tổng hai mươi mấy. Đổi
            // lại là R8 gãy ngay ở các lớp Play Core mà Flutter tham chiếu cho
            // tính năng tải mô-đun theo yêu cầu — thứ app này không dùng, vì
            // không phát hành qua Play Store. Không đáng.
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
