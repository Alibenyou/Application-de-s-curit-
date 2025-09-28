// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // Assurez-vous que ce plugin est bien là
    id("dev.flutter.flutter-gradle-plugin") // Le plugin Flutter
}

android {
    namespace = "com.example.ma_surveillance_app" // Assurez-vous que cela correspond à votre package
    compileSdk = 35 // Ciblez la dernière version stable d'Android SDK

    defaultConfig {
        applicationId = "com.example.ma_surveillance_app" // Assurez-vous que cela correspond à votre package
        minSdk = 21 // Nécessaire pour DevicePolicyManager et Camera
        targetSdk = 35 // Mettez à jour à la dernière version stable
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Utilisez la configuration de débogage pour le release en dev
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8" // Utilisez des guillemets doubles pour les chaînes de caractères
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Les dépendances standard pour Android. Ne les modifiez pas à moins que ce ne soit nécessaire.
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.8.0")) // Assurez-vous de la version de Kotlin BOM
    // Ajoutez d'autres dépendances si nécessaires, par exemple pour JUnit
    // testImplementation("junit:junit:4.13.2")
    // androidTestImplementation("androidx.test.ext:junit:1.1.5")
    // androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}