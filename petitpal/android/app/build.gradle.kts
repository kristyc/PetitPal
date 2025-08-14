plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Use the values provided by Flutter where appropriate
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // Required by AGP 8+: should match your package id
    namespace = "com.petitpal.app"

    defaultConfig {
        // Your final app id — MUST be consistent with AndroidManifest and MainActivity package path
        applicationId = "com.petitpal.app"

        // Keep these from Flutter unless you want to hardcode; here we hardcode to avoid version-downgrade errors
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 5
        versionName = "0.5.0"
    }

    // Java/Kotlin toolchains (use 17)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // Sign with debug keys so `flutter run --release` works until you add a real keystore
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            // (optional) keep empty
        }
    }
}

flutter {
    source = "../.."
}
