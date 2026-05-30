import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.phobes.mobile"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // DÜZELTİLDİ: Java 21 desteği eklendi
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        // DÜZELTİLDİ: JVM Target 21 olarak güncellendi
        jvmTarget = "21"
    }

    defaultConfig {
        applicationId = "app.phobes.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug") {
            // Debug config remains default
        }
        create("release") {
            val props = Properties()
            val keyPropsFile = rootProject.file("key.properties")
            if (keyPropsFile.exists()) {
                keyPropsFile.inputStream().use { props.load(it) }
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
                val storeFilePath = props.getProperty("storeFile")
                storeFile = if (storeFilePath.startsWith("app/")) {
                    file(storeFilePath.substring(4))
                } else {
                    file(storeFilePath)
                }
                storePassword = props.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            val keyPropsFile = rootProject.file("key.properties")
            signingConfig = if (keyPropsFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.add("-Xlint:-options")
}

dependencies {
    // DÜZELTİLDİ:
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // home_widget 0.9.0 transitive olarak glance-appwidget 1.3.0-alpha01 çekiyor
    // ve bu compileSdk 37 + AGP 9.1.0 talep ediyor. Stable sürüme sabitle.
    constraints {
        implementation("androidx.glance:glance-appwidget:1.1.1") {
            because("1.3.0-alpha01 requires compileSdk 37 and AGP 9.1.0+")
        }
        implementation("androidx.glance:glance:1.1.1") {
            because("Keep glance core aligned with glance-appwidget 1.1.1")
        }
    }
}

configurations.configureEach {
    resolutionStrategy {
        // androidx.compose.remote stable yok, aktif olarak bu projede kullanılmıyor.
        // glance-appwidget downgrade'i sonrası transitive olarak çekilmemeli.
        force("androidx.glance:glance-appwidget:1.1.1")
        force("androidx.glance:glance:1.1.1")
    }
}
