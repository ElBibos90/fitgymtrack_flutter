import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fitgymtracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // 🔧 STRIPE FIX: Application ID consistente
        applicationId = "com.fitgymtracker"
        
        // 💳 STRIPE FIX: minSdk 21 richiesto da Stripe
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // 🔧 FIX: MultiDex per evitare errori metodi
        multiDexEnabled = true
        
        // 🔧 FIX: Test runner
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            // Gestione sicura delle proprietà del keystore
            if (keystoreProperties.containsKey("storeFile")) {
                storeFile = file(keystoreProperties["storeFile"] as String)
            }
            if (keystoreProperties.containsKey("storePassword")) {
                storePassword = keystoreProperties["storePassword"] as String
            }
            if (keystoreProperties.containsKey("keyAlias")) {
                keyAlias = keystoreProperties["keyAlias"] as String
            }
            if (keystoreProperties.containsKey("keyPassword")) {
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
        
        release {
            // 🔧 FIX: Configurazione release con ProGuard/R8
            isMinifyEnabled = true
            isShrinkResources = true
            
            // 🔧 FIX: ProGuard rules file
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // 🔧 FIX: Usa debug signing per ora (come originale)
            signingConfig = signingConfigs.getByName("release")
        }
    }

    // 🔧 FIX: Build features
    buildFeatures {
        buildConfig = true
        viewBinding = true
    }

    // 🔧 FIX: Packaging options per evitare conflitti
    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module"
            )
        }
        jniLibs {
            pickFirsts += setOf(
                "**/libc++_shared.so",
                "**/libjsc.so"
            )
        }
    }

    // 🔧 FIX: Lint configuration
    lint {
        checkReleaseBuilds = false
        abortOnError = false
        disable += setOf("InvalidPackage")
    }

    // 🔧 FIX: Compile options per Stripe
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 💳 STRIPE FIX: Dipendenze AppCompat necessarie per flutter_stripe
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.core:core-ktx:1.12.0")

    // 💳 STRIPE: Dipendenze aggiuntive per gestione pagamenti
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")
    
    // 🔧 FIX: MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")
    
    // 🔧 FIX: Core library desugaring per Java 8+ API su Android API < 26
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // 💳 STRIPE: Dipendenze per WebView (usato da Payment Sheet)
    implementation("androidx.webkit:webkit:1.8.0")
    
    // 💳 STRIPE: Security per certificati
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    
    // 🔧 FIX: ConstraintLayout per UI Stripe
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    
    // Test dependencies
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}