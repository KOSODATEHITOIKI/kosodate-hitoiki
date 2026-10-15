import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 本番署名鍵はコミットせず、android/key.properties(.gitignore対象)があれば使う。
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
            // key.properties未設定時はdebug鍵へフォールバック(prod releaseは下で別途失敗させる)。
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

// prod releaseのdebug鍵フォールバック配布を防ぐ。assemble等の集約タスクも拾えるよう解決済みタスクグラフで判定する。
val prodReleaseOutputTasks = setOf(
    "assembleProdRelease",
    "bundleProdRelease",
    "packageProdRelease",
    "validateSigningProdRelease",
)
gradle.taskGraph.whenReady {
    val buildsProdRelease = allTasks.any {
        it.path.substringAfterLast(":") in prodReleaseOutputTasks
    }
    if (buildsProdRelease && !hasReleaseSigning) {
        throw GradleException(
            "本番配布(prod release)には android/key.properties による署名設定が必須です。" +
                "keyAlias・keyPassword・storeFile・storePasswordを用意してください。"
        )
    }
}

flutter {
    source = "../.."
}
