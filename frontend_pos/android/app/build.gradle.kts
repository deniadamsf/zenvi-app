import java.util.Properties
import java.io.StringReader

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
    // Dibaca sebagai teks lalu BOM-nya dibuang: kalau file disimpan sebagai UTF-8 with BOM,
    // Properties.load(InputStream) akan membaca key pertama sebagai "\uFEFFstorePassword"
    // sehingga getProperty("storePassword") mengembalikan null.
    keystoreProperties.load(StringReader(keyFile.readText(Charsets.UTF_8).removePrefix("\uFEFF")))
    println("Loaded keystore properties from: " + keyFile.absolutePath)
} else {
    println("INFO: key.properties tidak ditemukan (hanya diperlukan untuk build release)")
}

// PENTING: file ini di-track git, jadi JANGAN PERNAH menaruh password/alias signing
// sebagai nilai fallback hardcoded di sini. Semua kredensial signing hanya boleh
// datang dari key.properties (file itu wajib tetap gitignored).
val isReleaseBuild = gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }

fun missingSigningConfig(detail: String): Nothing = throw GradleException(
    "Release signing gagal: " + detail + "\n" +
    "Buat file frontend_pos/android/key.properties (JANGAN di-commit) dengan isi:\n" +
    "  storePassword=<password keystore>\n" +
    "  keyPassword=<password key>\n" +
    "  keyAlias=<alias key>\n" +
    "  storeFile=<path ke file .jks>\n" +
    "Lokasi key.properties yang dicari:\n  " +
    possibleKeyFiles.joinToString("\n  ") { it.absolutePath }
)

fun requireSigningProperty(name: String): String {
    val value = keystoreProperties.getProperty(name)
    if (value.isNullOrBlank()) {
        missingSigningConfig("properti '" + name + "' tidak ada / kosong di key.properties.")
    }
    return value
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
            // Hanya divalidasi saat build release. Build debug tidak butuh kredensial signing,
            // jadi jangan sampai ikut gagal kalau key.properties belum ada.
            if (isReleaseBuild) {
                if (keyFile == null) {
                    missingSigningConfig("file key.properties tidak ditemukan.")
                }

                keyAlias = requireSigningProperty("keyAlias")
                keyPassword = requireSigningProperty("keyPassword")
                storePassword = requireSigningProperty("storePassword")

                val storeFileVal = keystoreProperties.getProperty("storeFile") ?: "zenvi-upload-keystore.jks"

                val possibleKeystores = listOf(
                    File(projectDir, storeFileVal),
                    File(projectDir, "zenvi-upload-keystore.jks"),
                    File(rootDir, storeFileVal),
                    File(rootDir, "app/zenvi-upload-keystore.jks"),
                    File("d:/zenvi/frontend_pos/android/app/zenvi-upload-keystore.jks"),
                    File("d:/zenvi/frontend_pos/android/zenvi-upload-keystore.jks")
                )

                storeFile = possibleKeystores.firstOrNull { it.exists() }
                    ?: missingSigningConfig(
                        "file keystore tidak ditemukan. Lokasi yang dicari:\n  " +
                        possibleKeystores.joinToString("\n  ") { it.absolutePath }
                    )

                println("Release Signing Config: alias=" + keyAlias + " storeFile=" + storeFile?.absolutePath)
            }
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
