import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 本番署名鍵はリポジトリに含めない。android/key.properties(.gitignore対象)に
// keyAlias・keyPassword・storeFile・storePasswordを用意した場合のみ本番鍵で署名し、
// 未用意の場合は従来どおりdebug鍵にフォールバックして`flutter run --release`を保つ。
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.kosodatehitoiki.kosodate_hitoiki"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kosodatehitoiki.kosodate_hitoiki"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "ひと息(dev)")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "ひと息")
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // android/key.properties が用意されていれば本番鍵で署名する。
            // 未用意の間はdebug鍵のままとし、`flutter run --release` を壊さない。
            // 本番配布用(prodReleaseVariant)はこのフォールバックを許さず、
            // 下のapplicationVariants.allでビルド自体を失敗させる。
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

}

// 本番配布(prodフレーバーのrelease)は、debug鍵へのフォールバックに気づかず
// 配布してしまう事故を防ぐため、key.properties未設定ならビルド自体を
// 失敗させる。dev/profileはこの対象外(開発用途のためdebug鍵フォールバックを
// 許容する)。applicationVariants.all{}は対象外のタスク実行時にも全variantを
// 評価してしまうため、実際にprodReleaseが要求されたタスクかどうかを
// startParameterで確認してから失敗させる。
afterEvaluate {
    val requestedProdRelease = gradle.startParameter.taskNames.any { taskName ->
        val normalized = taskName.substringAfterLast(":")
        normalized.contains("ProdRelease") || normalized == "assembleRelease"
    }
    if (requestedProdRelease && !hasReleaseSigning) {
        throw GradleException(
            "本番配布(prod release)には android/key.properties による署名設定が必須です。" +
                "keyAlias・keyPassword・storeFile・storePasswordを用意してください。"
        )
    }
}

flutter {
    source = "../.."
}
