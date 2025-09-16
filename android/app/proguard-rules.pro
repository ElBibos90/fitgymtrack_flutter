# ============================================================================
# FITGYMTRACK PROGUARD/R8 RULES
# ============================================================================

# 🔧 FIX: Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ============================================================================
# 💳 STRIPE RULES - FIX PER ERRORE PUSH PROVISIONING
# ============================================================================

# 🔧 FIX: STRIPE CORE - Keep essential classes
-keep class com.stripe.android.** { *; }
-keep class com.stripe.** { *; }

# 🔧 FIX: IGNORE missing push provisioning classes (not needed for subscriptions)
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**

# 🔧 FIX: Keep Stripe classes but ignore missing ones
-keep class com.stripe.android.PaymentConfiguration { *; }
-keep class com.stripe.android.Stripe { *; }
-keep class com.stripe.android.model.** { *; }
-keep class com.stripe.android.view.** { *; }

# 🔧 FIX: Ignore specific missing push provisioning classes from error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# 🔧 FIX: React Native Stripe SDK warnings (flutter_stripe uses some RN code)
-dontwarn com.reactnativestripesdk.**

# 🔧 FIX: BouncyCastle missing classes (used by Stripe for cryptography)
-dontwarn org.bouncycastle.**
-keep class org.bouncycastle.** { *; }

# 🔧 FIX: Specific BouncyCastle classes missing from R8 error
-dontwarn org.bouncycastle.asn1.ASN1Encodable
-dontwarn org.bouncycastle.asn1.pkcs.PrivateKeyInfo
-dontwarn org.bouncycastle.asn1.x509.AlgorithmIdentifier
-dontwarn org.bouncycastle.asn1.x509.SubjectPublicKeyInfo
-dontwarn org.bouncycastle.cert.X509CertificateHolder
-dontwarn org.bouncycastle.cert.jcajce.JcaX509CertificateHolder
-dontwarn org.bouncycastle.openssl.PEMKeyPair
-dontwarn org.bouncycastle.openssl.PEMParser
-dontwarn org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter

# 🔧 FIX: NimbusDS JOSE classes that use BouncyCastle
-dontwarn com.nimbusds.jose.jwk.**

# ============================================================================
# FLUTTER SPECIFIC RULES
# ============================================================================

# 🔧 Keep Flutter method channels
-keep class ** implements io.flutter.plugin.common.MethodCall { *; }
-keep class ** implements io.flutter.plugin.common.MethodChannel { *; }
-keep class ** implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }

# 🔧 Keep Flutter registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# ============================================================================
# NETWORK & JSON RULES
# ============================================================================

# 🔧 Dio/Retrofit rules
-keepattributes Signature
-keepattributes *Annotation*
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn retrofit2.**
-dontwarn okhttp3.**
-dontwarn okio.**

# 🔧 JSON serialization
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# ============================================================================
# APP SPECIFIC MODEL CLASSES
# ============================================================================

# 🔧 Keep all model classes (adjust paths as needed)
-keep class com.fitgymtracker.models.** { *; }
-keep class ** implements java.io.Serializable { *; }

# 🔧 Keep classes with @JsonSerializable annotation
-keep @com.google.gson.annotations.SerializedName class * { *; }
-keep class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ============================================================================
# ANDROID & KOTLIN RULES
# ============================================================================

# 🔧 Kotlin rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# 🔧 AndroidX rules
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# 🔧 Support library rules
-keep class android.support.** { *; }
-keep interface android.support.** { *; }
-dontwarn android.support.**

# ============================================================================
# PERFORMANCE & OPTIMIZATION
# ============================================================================

# 🔧 Optimization settings
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

# 🔧 Keep line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# 🔧 Remove logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# ============================================================================
# SPECIFIC PLUGIN RULES
# ============================================================================

# 🔧 Shared Preferences
-keep class androidx.preference.** { *; }

# 🔧 Device Info
-keep class io.flutter.plugins.deviceinfo.** { *; }

# 🔧 Package Info
-keep class io.flutter.plugins.packageinfo.** { *; }

# 🔧 Connectivity
-keep class io.flutter.plugins.connectivity.** { *; }

# 🔧 Audio Players
-keep class xyz.luan.audioplayers.** { *; }

# 🔧 Haptic Feedback
-keep class com.hapticfeedback.** { *; }

# ============================================================================
# WEBVIEW & URL LAUNCHER (se usati da Stripe)
# ============================================================================

# 🔧 WebView rules for Stripe Payment Sheet
-keep class android.webkit.** { *; }
-dontwarn android.webkit.**

# ============================================================================
# 🔧 GOOGLE PLAY CORE RULES - FIX PER MISSING CLASSES
# ============================================================================

# 🔧 FIX: Ignore missing Google Play Core classes (for deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# 🔧 FIX: Specific missing classes from error
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# 🔧 FIX: Flutter Play Store integration
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# 🔧 FIX: If using Google Play Core, keep these
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# ============================================================================
# FINAL CATCH-ALL RULES
# ============================================================================

# 🔧 Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# 🔧 Keep all enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 🔧 Keep Parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}