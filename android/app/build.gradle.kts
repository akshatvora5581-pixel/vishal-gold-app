import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing config from key.properties
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.vishalgoldapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        if (keyPropertiesFile.exists()) {
            val alias = keyProperties.getProperty("keyAlias")
            val keyPass = keyProperties.getProperty("keyPassword")
            val storeFileStr = keyProperties.getProperty("storeFile")
            val storePass = keyProperties.getProperty("storePassword")
            
            if (alias != null && keyPass != null && storeFileStr != null && storePass != null) {
                create("release") {
                    keyAlias = alias
                    keyPassword = keyPass
                    storeFile = file(storeFileStr)
                    storePassword = storePass
                }
            }
        }
    }

    defaultConfig {
        applicationId = "com.vishalgoldapp"
        minSdk = flutter.minSdkVersion  // Firebase requires minimum SDK 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Removed restrictive abiFilters to ensure compatibility across all architectures

    }

    buildTypes {
        release {
            val releaseConfig = signingConfigs.findByName("release")
            if (releaseConfig != null) {
                signingConfig = releaseConfig
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Apply Google Services plugin for Firebase
apply(plugin = "com.google.gms.google-services")

