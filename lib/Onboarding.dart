import 'dart:convert';
import 'dart:io';

import 'package:eyetest/home.dart';
import 'package:eyetest/login.dart';
import 'package:eyetest/paywall.dart';
import 'package:eyetest/paywallandroid.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:device_frame/device_frame.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // ADD THIS

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  final InAppReview inAppReview = InAppReview.instance;
  bool _hasRequestedReview = false;
  bool x = false;

  final List<Map<String, dynamic>> onboardingData = [
    {
      'title': 'Test your vision\nanytime, anywhere!',
      'description':
          'Check visual acuity, color perception, and\nmore — no appointments needed.',
      'image': 'assets/images/onboarding1.png',
      'backgroundColor': Color(0xFFFFD700),
    },
    {
      'title': 'Accurate results made\nsimple',
      'description':
          'Follow easy, illustrated instructions and get\nprecise results instantly after test.',
      'image': 'assets/images/onboarding2.png',
      'backgroundColor': Color(0xFF00C851),
    },
    {
      'title': 'Love EyeTest?',
      'description': 'Rate us to help more people\ndiscover it',
      'isRatingPage': true,
      'backgroundColor': Colors.black,
    },
    {
      'title': 'Vision testing made\nconvenient',
      'description':
          'Take tests anytime, anywhere — right from\nyour phone or tablet.',
      'image': 'assets/images/onboarding3.png',
      'backgroundColor': Colors.white,
    },
  ];

  @override
  void initState() {
    super.initState();
    getValues();
  }

  getValues() async {
    x = await getdiscforvas();
  }

  // IMPROVED: Better review request with fallback
  Future<void> _requestReview() async {
    if (_hasRequestedReview) return;
    _hasRequestedReview = true;

    try {
      // Check if in-app review is available
      final isAvailable = await inAppReview.isAvailable();

      print('📱 In-App Review Available: $isAvailable');
      print('📱 Platform: ${Platform.operatingSystem}');

      if (isAvailable) {
        // Request the review
        await inAppReview.requestReview();
        print(
          '✅ Review requested (but may not show due to Google Play quotas)',
        );
      } else {
        print('⚠️ In-App Review not available');
      }
    } catch (e) {
      print('❌ Error requesting review: $e');
    }
  }

  // NEW: Fallback - Open Play Store/App Store directly
  Future<void> _openStoreForReview() async {
    try {
      final appId = Platform.isAndroid
          ? 'com.eyeshealthtest.app' // REPLACE with your Android package name
          : '6621183937'; // REPLACE with your iOS App ID

      await inAppReview.openStoreListing(appStoreId: appId);
      print('✅ Opened store listing for review');
    } catch (e) {
      print('❌ Error opening store: $e');
    }
  }

  Future<void> _onContinue() async {
    if (_currentIndex < onboardingData.length - 1) {
      _controller.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    } else {
      Widget nextPage;
      final hasActiveSubscription = await checkUserSubscription();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);

      if (Platform.isAndroid) {
        if (x) {
          nextPage = PhoneLoginPage();
        } else {
          if (!hasActiveSubscription) {
            nextPage = PaywallAndroid();
          } else {
            nextPage = HomePage();
          }
        }
      } else {
        if (x) {
          nextPage = PhoneLoginPage();
        } else {
          if (!hasActiveSubscription) {
            nextPage = PaywallScreen();
          } else {
            nextPage = HomePage();
          }
        }
      }

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => nextPage));
    }
  }

  Future<bool> checkUserSubscription() async {
    bool isSubscribed = false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final activeEntitlement = customerInfo.entitlements.active['pro'];

      if (activeEntitlement != null) {
        isSubscribed = activeEntitlement.isActive;
        return isSubscribed;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      isSubscribed = false;
      return isSubscribed;
    }
  }

  Future<bool> getdiscforvas() async {
    print("getdiscforvas called");
    final response = await http.get(
      Uri.parse('https://eyeshealthtest.com/he/sa/android/getdisc.php'),
      headers: {'Content-Type': 'application/json'},
    );

    print("getdiscforvas called11");

    if (response.statusCode == 200) {
      String disc = response.body;
      var typesof = jsonDecode(response.body);
      print("Discriminator: ${typesof['type']}");
      print("Discriminator: ${typesof['disclaimer']}");

      if (typesof['type'].toString().trim() == "vas") {
        return true;
      } else {
        return false;
      }
    } else {
      print(response.statusCode);
      return false;
    }
  }

  Widget _buildDots() {
    return Padding(
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(onboardingData.length, (index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            width: 60,
            height: 8,
            decoration: BoxDecoration(
              color: index <= _currentIndex
                  ? Color(0xFF049281)
                  : Color(0xFF666666),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRatingPage(Map<String, dynamic> item) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Text(
              item['title'],
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 14),
            Text(
              item['description'],
              style: TextStyle(
                fontSize: 17,
                color: Colors.white.withOpacity(0.85),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 35),

            // Phone mockup (keeping your existing code)
            Container(
              height: 450,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Transform.scale(
                      scale: 0.85,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 5,
                              offset: Offset(0, 15),
                            ),
                          ],
                        ),
                        child: DeviceFrame(
                          device: Devices.ios.iPhone13ProMax,
                          screen: Container(
                            color: Colors.white,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(
                                          0xFF049281,
                                        ).withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: Image.asset(
                                      'assets/img/Logo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'EyeTest',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF049281),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Vision Testing App',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 15,
                    child: _buildReviewCard(
                      "Great for quick\neye checks! The tests\nare easy to follow.",
                      'S',
                      Colors.purple,
                    ),
                  ),
                  Positioned(
                    top: 90,
                    right: 15,
                    child: _buildReviewCard(
                      "Finally an app that\nhelps me monitor my\nvision health!",
                      'M',
                      Colors.blue,
                    ),
                  ),
                  Positioned(
                    bottom: 90,
                    left: 15,
                    child: _buildReviewCard(
                      "Accurate results and\nvery user-friendly.\nHighly recommend!",
                      'J',
                      Colors.orange,
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 15,
                    child: _buildReviewCard(
                      "The color blind test\nreally helped me\nunderstand my vision",
                      'A',
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),

            // IMPROVED: Tap to rate with better interaction
            GestureDetector(
              onTap: () {
                print('⭐ Stars tapped - attempting review');
                _requestReview();

                // NEW: Fallback - open store after 2 seconds if review didn't show
                Future.delayed(Duration(seconds: 2), () {
                  // Optionally show a button to manually open store
                });
              },
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: Icon(
                          Icons.star_rounded,
                          color: Color(0xFF049281),
                          size: 44,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to rate us',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),

                  // NEW: Optional fallback button (shows after attempting review)
                  if (Platform.isAndroid) ...[
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: _openStoreForReview,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Rate on Google Play',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(String text, String initial, Color color) {
    return Container(
      padding: EdgeInsets.all(14),
      constraints: BoxConstraints(maxWidth: 170),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: List.generate(
                    5,
                    (index) =>
                        Icon(Icons.star, color: Color(0xFF049281), size: 16),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _buildDots(),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: onboardingData.length,
              onPageChanged: (i) {
                setState(() => _currentIndex = i);

                // Trigger review when reaching the rate us page
                if (onboardingData[i]['isRatingPage'] == true) {
                  print("📱 Reached rating page - requesting review");
                  // Delay to ensure page is fully visible
                  Future.delayed(Duration(milliseconds: 500), () {
                    _requestReview();
                  });
                }
              },
              itemBuilder: (context, i) {
                final item = onboardingData[i];

                if (item['isRatingPage'] == true) {
                  return _buildRatingPage(item);
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 40),
                      alignment: Alignment.center,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: item['backgroundColor'],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            item['image'],
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          Text(
                            item['title'],
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.36,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Text(
                            item['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFCCCCCC),
                              height: 1.375,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF049281),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _onContinue,
              child: Center(
                child: Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
