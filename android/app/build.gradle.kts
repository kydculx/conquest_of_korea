import java.io.File
import java.util.Properties
import java.util.regex.Pattern

fun getVersionConfig(): Pair<String, Int> {
    val configFile = File(projectDir.parentFile.parentFile, "lib/core/constants/version_config.dart")
    if (!configFile.exists()) {
        return Pair("1.0.0", 1)
    }
    var version = "1.0.0"
    var buildNumber = 1
    
    configFile.forEachLine { line ->
        if (line.contains("static const String version")) {
            val matcher = Pattern.compile("version\\s*=\\s*['\"]([^'\"]+)['\"]").matcher(line)
            if (matcher.find()) {
                version = matcher.group(1)
            }
        }
        if (line.contains("static const int buildNumber")) {
            val matcher = Pattern.compile("buildNumber\\s*=\\s*(\\d+)").matcher(line)
            if (matcher.find()) {
                buildNumber = matcher.group(1).toInt()
            }
        }
    }
    return Pair(version, buildNumber)
}

val (vName, vCode) = getVersionConfig()

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.watercherry.conquestofkorea"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { path -> file(path) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.watercherry.conquestofkorea"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // health 패키지 요구사항에 따라 26으로 상향 조정
        targetSdk = flutter.targetSdkVersion
        versionCode = vCode
        versionName = vName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
