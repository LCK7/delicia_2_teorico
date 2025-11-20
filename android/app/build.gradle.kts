plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.delicia_1"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.delicia_1"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            storeFile = file("delicia.keystore")
            storePassword = "YaamtCHlcksnk39$"
            keyAlias = "delicia"
            keyPassword = "YaamtCHlcksnk39$"
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
        }
    }

    applicationVariants.all {
        outputs.all {
            if (buildType.name == "release") {
                val appName = "DeliciaPanaderia"
                val version = versionName
                val code = versionCode
                (this as com.android.build.gradle.internal.api.BaseVariantOutputImpl).outputFileName =
                    "${appName}_v${version}_(${code}).apk"
            }
        }
    }
}

flutter {
    source = "../.."
}
