plugins {
    id("com.android.application")
    // Adiciona o plugin do Google Services
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.contabilidade_amiga"
    // ▼▼▼ CORREÇÃO APLICADA AQUI ▼▼▼
    compileSdk = 35

    // Garante que a versão do NDK seja compatível com os pacotes do Firebase.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.example.contabilidade_amiga"
        minSdk = 21
        targetSdk = 34 // Manter 34 aqui está correto por enquanto
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Dependências do seu projeto
}
