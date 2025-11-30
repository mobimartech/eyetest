import 'dart:io';

import 'package:eyetest/home.dart';
import 'package:eyetest/paywall.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:device_frame/device_frame.dart';

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

  Future<void> _requestReview() async {
    if (!_hasRequestedReview && await inAppReview.isAvailable()) {
      _hasRequestedReview = true;
      inAppReview.requestReview();
    }
  }

  Future<void> _onContinue() async {
    if (_currentIndex < onboardingData.length - 1) {
      _controller.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    } else {
      if (Platform.isAndroid) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSeenOnboarding', true);
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSeenOnboarding', true);
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => PaywallScreen()));
      }
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
            // Title
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
            // Subtitle
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
            // Phone mockup with reviews using device_frame
            Container(
              height: 450,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // iPhone frame with device_frame package
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
                                // Logo from assets
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
                                // App Name
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
                  // Review card - Top Left (closer to phone)
                  Positioned(
                    top: 20,
                    left: 15,
                    child: _buildReviewCard(
                      "Great for quick\neye checks! The tests\nare easy to follow.",
                      'S',
                      Colors.purple,
                    ),
                  ),
                  // Review card - Top Right (closer to phone)
                  Positioned(
                    top: 90,
                    right: 15,
                    child: _buildReviewCard(
                      "Finally an app that\nhelps me monitor my\nvision health!",
                      'M',
                      Colors.blue,
                    ),
                  ),
                  // Review card - Bottom Left (closer to phone)
                  Positioned(
                    bottom: 90,
                    left: 15,
                    child: _buildReviewCard(
                      "Accurate results and\nvery user-friendly.\nHighly recommend!",
                      'J',
                      Colors.orange,
                    ),
                  ),
                  // Review card - Bottom Right (closer to phone)
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
            // Star rating
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
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(String text, String initial, Color color) {
    return Container(
      padding: EdgeInsets.all(14), // Increased from 10 to 14
      constraints: BoxConstraints(maxWidth: 170), // Increased from 145 to 170
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18), // Increased from 16 to 18
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
              // Avatar with initial - Bigger
              Container(
                width: 32, // Increased from 28 to 32
                height: 32, // Increased from 28 to 32
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
                      fontSize: 16, // Increased from 14 to 16
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Stars - Bigger
              Expanded(
                child: Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      color: Color(0xFF049281),
                      size: 16, // Increased from 14 to 16
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10), // Increased from 8 to 10
          Text(
            text,
            style: TextStyle(
              fontSize: 12, // Increased from 11 to 12
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
                  _requestReview();
                }
              },
              itemBuilder: (context, i) {
                final item = onboardingData[i];

                // Check if this is the rating page
                if (item['isRatingPage'] == true) {
                  return _buildRatingPage(item);
                }

                // Regular onboarding page
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
