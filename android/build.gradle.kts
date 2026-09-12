group = "app.onesygnal.sdk.flutter"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.2.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // The native OneSygnal AAR isn't published to Maven Central yet — see
        // apps/android-sdk/onesygnal/build.gradle.kts's own local.properties note. This bridge
        // resolves it from the local Maven cache for local dev; sync-flutter-sdk.yml's "Apply
        // production transforms" step swaps this for the real published repo (and the dependency
        // version below for the real native release) when publishing to pub.dev.
        maven { url = uri("https://repo.1sygnal.app") }
    }
}

plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "app.onesygnal.sdk.flutter"

    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        // Matches apps/android-sdk/onesygnal's own minSdk — this plugin can't support a lower
        // Android version than the native SDK it bridges to.
        minSdk = 21
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()
                it.outputs.upToDateWhen { false }
                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

dependencies {
    // 0.1.0 matches :onesygnal's own local-publish default (see its build.gradle.kts) — a plain
    // `./gradlew :onesygnal:publishToMavenLocal` with no -PonesygnalVersion override publishes
    // under this same version, so local dev resolves correctly against the local Maven cache
    // repository above. sync-flutter-sdk.yml substitutes this for the real native_sdk_version
    // input when publishing.
    implementation("app.onesygnal:onesygnal-sdk:1.0.2")

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
