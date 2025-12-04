import 'dart:convert';
import 'dart:io';

import 'package:eyetest/home.dart';
import 'package:eyetest/notification_service.dart';
import 'package:eyetest/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:easy_localization/easy_localization.dart'; // ADD THIS

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization BEFORE runApp
  await EasyLocalization.ensureInitialized(); // ADD THIS

  // Initialize notifications
  await NotificationService().initialize();

  // Run app wrapped with EasyLocalization
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('ar'),
        Locale('zh'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'), // Default language
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppsflyerSdk _appsflyerSdk;
  bool _attGranted = false;
  bool _hasProcessedAttribution = false;
  String _status = "Initializing...";
  String? _appsflyerUID;
  String? _appVersion;
  String? _platformVersion;

  Future<void> initRevenueCat() async {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(
      PurchasesConfiguration("appl_HLNlRmifZJLrajFZwzSWgBNvflh"),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) async {
      final status =
          await AppTrackingTransparency.requestTrackingAuthorization();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 800), () {
        _initApp();
      });
    });
  }

  Future<void> _initApp() async {
    print("=== App Initialization Started ===");
    await initRevenueCat();
    print("✅ RevenueCat initialized");
    await _getAppVersion();
    await _getPlatformVersion();
    print("✅ App Version: $_appVersion, Platform: $_platformVersion");
    print("✅ ATT request completed. Granted: $_attGranted");
    _initAppsFlyer();
    print("✅ AppsFlyer initialized");
    print("=== App Initialization Complete ===");
  }

  Future<void> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  Future<void> _getPlatformVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _platformVersion = androidInfo.version.release;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _platformVersion = iosInfo.systemVersion;
    }
  }

  Future<void> _requestATT() async {
    print("=== Requesting ATT Permission ===");
    if (Platform.isIOS) {
      try {
        print("iOS detected. Checking ATT status...");
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        print("Current ATT status: $status");
        final canRequest =
            await AppTrackingTransparency.getAdvertisingIdentifier();
        print("Advertising Identifier available: ${canRequest.isNotEmpty}");
        if (status == TrackingStatus.notDetermined) {
          print("⏸️ Status is notDetermined. Requesting authorization...");
          print(
            "⏸️ IMPORTANT: Check Settings → Privacy → Tracking is enabled!",
          );
          await Future.delayed(Duration(milliseconds: 300));
          print("🚀 About to show ATT dialog...");
          final result =
              await AppTrackingTransparency.requestTrackingAuthorization();
          print("👍 User responded with: $result");
          if (result == TrackingStatus.notDetermined) {
            print("❌ DIALOG DID NOT SHOW!");
            print("❌ This means device-level tracking is DISABLED");
            print(
              "❌ User must enable: Settings → Privacy & Security → Tracking",
            );
          }
          _attGranted = result == TrackingStatus.authorized;
        } else {
          _attGranted = status == TrackingStatus.authorized;
          print("ATT already determined: $status, granted: $_attGranted");
        }
      } catch (e) {
        print("❌ Error requesting ATT: $e");
        _attGranted = false;
      }
    } else {
      _attGranted = true;
      print("Android platform - ATT not required");
    }
    print("Final ATT status - Granted: $_attGranted");
    setState(() {});
  }

  void _initAppsFlyer() {
    print("=== Initializing AppsFlyer ===");
    final options = AppsFlyerOptions(
      afDevKey: Platform.isIOS ?'FjSERtDKGm29LmgGqGBpdn': "kea9rcdAoPshWf9oAdryw",
      appId: Platform.isIOS ? '6621183937' : "",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 60,
    );
    _appsflyerSdk = AppsflyerSdk(options);
    _appsflyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
    _appsflyerSdk.getAppsFlyerUID().then((uid) {
      print("AppsFlyer UID obtained: $uid");
      setState(() {
        _appsflyerUID = uid;
      });
    });
    _appsflyerSdk.onInstallConversionData((data) async {
      print("=== Install Conversion Data ===");
      print(data);
      if (_hasProcessedAttribution) {
        print("Already processed attribution, skipping...");
        return;
      }
      _hasProcessedAttribution = true;
      final extracted = _extractOneLinkParams(data);
      if (data['data']?['is_first_launch'] == true) {
        print("First launch detected, sending webhook...");
        await _sendOneLinkDataToWebhook(
          extractedParams: extracted,
          eventType: 'first_open_after_install',
          rawAppsFlyerData: data,
        );
        setState(() {
          _status = "Install conversion sent!";
        });
      }
    });
    _appsflyerSdk.onDeepLinking((deepLinkResult) async {
      print("=== Deep Link Received ===");
      print(deepLinkResult.toJson());
      final extracted = _extractOneLinkParams(deepLinkResult.toJson());
      await _sendOneLinkDataToWebhook(
        extractedParams: extracted,
        eventType: 'deep_link_open',
        rawAppsFlyerData: deepLinkResult.toJson(),
      );
      setState(() {
        _status = "Deep link sent!";
      });
    });
    print("=== AppsFlyer Setup Complete ===");
  }

  Map<String, dynamic> _extractOneLinkParams(Map data) {
    final d = data['data'] ?? {};
    String? decode(dynamic v) =>
        v == null ? null : Uri.decodeComponent(v.toString());
    String? clickId = decode(d['e_token']);
    if (clickId == '{Click_ID}' || clickId == '%7BClick_ID%7D') {
      clickId = 'placeholder_click_id_${DateTime.now().millisecondsSinceEpoch}';
    }
    String? eventName = decode(d['e_value']);
    if (eventName == '{Event_name}' || eventName == '%7BEvent_name%7D') {
      eventName = 'app_open';
    }
    String? eventValue = decode(d['adn_tid']);
    if (eventValue == '{Event_value}' || eventValue == '%7BEvent_value%7D') {
      eventValue = '1';
    }
    String? cn = decode(d['cn']);
    if (cn == '{cn}' || cn == '%7Bcn%7D') {
      cn = 'organic_campaign';
    }
    return {
      'cn': cn,
      'af_xp': decode(d['af_xp']),
      'pid': decode(d['pid']),
      'media_source': d['media_source']?.toString(),
      'click_id': clickId,
      'event_name': eventName,
      'event_value': eventValue,
      'af_status': d['af_status']?.toString(),
      'af_message': d['af_message']?.toString(),
      'campaign': d['campaign']?.toString(),
      'channel': d['channel']?.toString(),
      'deep_link_value': decode(d['deep_link_value']),
      'deep_link_sub1': decode(d['deep_link_sub1']),
      'deep_link_sub2': decode(d['deep_link_sub2']),
      'deep_link_sub3': decode(d['deep_link_sub3']),
      'att_permission_granted': _attGranted,
      'att_status': _attGranted ? 'authorized' : 'denied_or_restricted',
    };
  }

  Future<void> _sendOneLinkDataToWebhook({
    required Map<String, dynamic> extractedParams,
    required String eventType,
    required Map rawAppsFlyerData,
  }) async {
    const webhookUrl = 'https://eyeshealthtest.com/webhook/index.php';
    final payload = {
      "test_mode": false,
      "event_type": eventType,
      "timestamp": DateTime.now().toIso8601String(),
      "onelink_params": {
        "cn": extractedParams["cn"],
        "af_xp": extractedParams["af_xp"],
        "pid": extractedParams["pid"],
        "e_token": extractedParams["click_id"],
        "e_value": extractedParams["event_name"],
        "adn_tid": extractedParams["event_value"],
        "deep_link_sub1": extractedParams["deep_link_sub1"],
        "deep_link_sub2": extractedParams["deep_link_sub2"],
        "deep_link_sub3": extractedParams["deep_link_sub3"],
      },
      "attribution_data": {
        "af_status": extractedParams["af_status"] ?? "Unknown",
        "af_message": extractedParams["af_message"] ?? "",
        "media_source":
            extractedParams["media_source"] ??
            extractedParams["pid"] ??
            "organic",
        "campaign": extractedParams["campaign"],
        "channel": extractedParams["channel"],
        "att_permission_granted": _attGranted,
        "att_status": _attGranted ? "authorized" : "denied_or_restricted",
      },
      "device_info": {
        "platform": Platform.operatingSystem,
        "platform_version": _platformVersion ?? "unknown",
        "app_version": _appVersion ?? "unknown",
        "appsflyer_uid": _appsflyerUID,
        "att_permission_granted": _attGranted,
      },
      "raw_appsflyer_data": rawAppsFlyerData,
    };
    try {
      print("📧 Sending webhook to: $webhookUrl");
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'AIScanPro/${Platform.operatingSystem}/1.0',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );
      print("📨 Webhook response: ${response.statusCode}");
      if (response.statusCode == 200) {
        print("✅ Webhook sent successfully");
      } else {
        print("❌ Webhook failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Error sending webhook: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'app_title'.tr(), // ADD localization
      // ADD these for EasyLocalization support
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: SplashScreen(),
    );
  }
}
