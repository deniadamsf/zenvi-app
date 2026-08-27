import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.io.File

val keystoreProperties = Properties()
val possibleKeyFiles = listOf(
    File(projectDir, "key.properties"),
    File(projectDir, "../key.properties"),
    File(rootDir, "key.properties"),
    File(rootDir, "app/key.properties"),
    File("d:/zenvi/frontend_pos/android/key.properties"),
    File("d:/zenvi/frontend_pos/android/app/key.properties")
)

val keyFile = possibleKeyFiles.firstOrNull { it.exists() }
if (keyFile != null) {
    keystoreProperties.load(FileInputStream(keyFile))
    println("Loaded keystore properties from: " + keyFile.absolutePath)
} else {
    println("WARNING: key.properties not found, using release defaults")
}

android {
    namespace = "com.cellanoma.zenvi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            val keyAliasVal = keystoreProperties.getProperty("keyAlias") ?: "zenvi_upload"
            val keyPasswordVal = keystoreProperties.getProperty("keyPassword") ?: "ZenviRelease2026!"
            val storePasswordVal = keystoreProperties.getProperty("storePassword") ?: "ZenviRelease2026!"
            val storeFileVal = keystoreProperties.getProperty("storeFile") ?: "app/zenvi-upload-keystore.jks"
            
            val possibleKeystores = listOf(
                File(projectDir, storeFileVal),
                File(projectDir, "zenvi-upload-keystore.jks"),
                File(rootDir, storeFileVal),
                File(rootDir, "app/zenvi-upload-keystore.jks"),
                File("d:/zenvi/frontend_pos/android/app/zenvi-upload-keystore.jks"),
                File("d:/zenvi/frontend_pos/android/zenvi-upload-keystore.jks")
            )
            
            val resolvedKeystore = possibleKeystores.firstOrNull { it.exists() }
            
            keyAlias = keyAliasVal
            keyPassword = keyPasswordVal
            storePassword = storePasswordVal
            storeFile = resolvedKeystore
            
            println("Release Signing Config: alias=" + keyAlias + " storeFile=" + storeFile?.absolutePath + " (exists=" + storeFile?.exists() + ")")
        }
    }

    defaultConfig {
        applicationId = "com.cellanoma.zenvi"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
