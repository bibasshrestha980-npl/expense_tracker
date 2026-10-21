import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Enable only after registering the deployed apps in Firebase App Check.
/// Enforcement is a server-side setting, not something a client flag can enforce.
Future<void> activateAppIntegrity() async {
  const enabled = bool.fromEnvironment('APP_CHECK_ENABLED');
  const siteKey = String.fromEnvironment('APP_CHECK_WEB_SITE_KEY');
  if (!enabled) return;
  if (kIsWeb && !kDebugMode && siteKey.isEmpty) {
    throw StateError(
      'APP_CHECK_WEB_SITE_KEY is required for App Check on web.',
    );
  }
  await FirebaseAppCheck.instance.activate(
    providerWeb: kIsWeb
        ? (kDebugMode ? WebDebugProvider() : ReCaptchaV3Provider(siteKey))
        : null,
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleDeviceCheckProvider(),
  );
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
}
