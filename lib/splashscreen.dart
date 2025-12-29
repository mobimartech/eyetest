import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:eyetest/login.dart';
import 'package:eyetest/paywallandroid.dart';
import 'package:http/http.dart' as http;
import 'package:eyetest/Onboarding.dart';
import 'package:eyetest/home.dart';
import 'package:eyetest/paywall.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController glowCtrl;
  bool isSubscribed = false;
  late AnimationController logoCtrl;
  late AnimationController particleCtrl;
  late AnimationController pulseCtrl;
  late AnimationController subtitleCtrl;
  late AnimationController titleCtrl;

  @override
  void dispose() {
    logoCtrl.dispose();
    pulseCtrl.dispose();
    glowCtrl.dispose();
    titleCtrl.dispose();
    subtitleCtrl.dispose();
    particleCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
      lowerBound: 1.0,
      upperBound: 1.1,
    );
    glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    subtitleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    startAnimationSequence();
  }

  void startAnimationSequence() async {
    logoCtrl.forward();
    pulseCtrl.repeat(reverse: true);
    glowCtrl.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 350));
    titleCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 180));
    subtitleCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 120));
    particleCtrl.forward();

    await Future.delayed(const Duration(seconds: 2));

    // --- NEW LOGIC STARTS HERE ---
    final prefs = await SharedPreferences.getInstance();
    final hasViewedOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final isloggedin = prefs.getBool('isLoggedIn') ?? false;

    // Replace this with your actual subscription check logic
    final hasActiveSubscription = await checkUserSubscription();
    print("Has active subscription: $hasActiveSubscription");
    Widget nextPage;
    if (!hasViewedOnboarding) {
      nextPage = OnboardingScreen();
    } else if (Platform.isAndroid) {
      bool x = await getdiscforvas();
      print("get disc for vas returned: $x");
      if (x) {
        nextPage = PhoneLoginPage();
      } else {
        print(
            "Navigating based on subscription status:: ${hasActiveSubscription}");
        if (!hasActiveSubscription) {
          nextPage = PaywallAndroid();
        } else {
          nextPage = HomePage();
        }
      }
    } else {
      bool x = await getdiscforvas();

      if (x) {
        if (isloggedin) {
          nextPage = HomePage();
        } else {
          nextPage = PhoneLoginPage();
        }
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
  } // Dummy async function for subscription check

  Future<bool> checkUserSubscription() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final activeEntitlement = customerInfo.entitlements.active['pro'];

      // setState(() {
      if (activeEntitlement != null) {
        isSubscribed = activeEntitlement.isActive;
        return isSubscribed;
      } // });
      else {
        return false;
      }
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      // setState(() {
      isSubscribed = false;
      // });
      return isSubscribed;
    }
  }

  Widget _buildParticles(Size size, double t) {
    // 6 particles, animated with appearance and scale
    final List<Offset> positions = [
      Offset(size.width * 0.10, size.height * 0.15),
      Offset(size.width * 0.25, size.height * 0.30),
      Offset(size.width * 0.40, size.height * 0.45),
      Offset(size.width * 0.65, size.height * 0.60),
      Offset(size.width * 0.80, size.height * 0.75),
      Offset(size.width * 0.60, size.height * 0.20),
    ];
    return IgnorePointer(
      child: Opacity(
        opacity: t,
        child: Stack(
          children: List.generate(6, (i) {
            final scale = 0.8 + 0.4 * sin(t * pi + i);
            return Positioned(
              left: positions[i].dx,
              top: positions[i].dy + 10 * sin(t * pi * (i + 1)),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(4, 146, 129, 0.6),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF049281).withOpacity(0.8),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: Offset.zero,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoAsset = 'assets/img/Logo.png'; // Make sure this asset exists.
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF049281),
      body: Stack(
        children: [
          // Gradient BG
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF049281),
                    Color(0xFF00665A),
                    Color(0xFF004940),
                    Color(0xFF000000),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.3, 0.5, 1],
                ),
              ),
            ),
          ),
          // Animated Particles
          AnimatedBuilder(
            animation: particleCtrl,
            builder: (_, __) => _buildParticles(size, particleCtrl.value),
          ),
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with glow and pulse
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      logoCtrl,
                      pulseCtrl,
                      glowCtrl,
                    ]),
                    builder: (context, _) {
                      final scale = Tween<double>(begin: 0.6, end: 1.0)
                              .animate(
                                CurvedAnimation(
                                  parent: logoCtrl,
                                  curve: Curves.elasticOut,
                                ),
                              )
                              .value *
                          pulseCtrl.value;
                      final opacity = CurvedAnimation(
                        parent: logoCtrl,
                        curve: Curves.easeIn,
                      ).value;
                      final rotate = Tween<double>(begin: -0.17, end: 0.0)
                          .animate(
                            CurvedAnimation(
                              parent: logoCtrl,
                              curve: Curves.easeOut,
                            ),
                          )
                          .value;
                      final glowOpacity = Tween<double>(begin: 0.3, end: 0.8)
                          .animate(
                            CurvedAnimation(
                              parent: glowCtrl,
                              curve: Curves.easeInOut,
                            ),
                          )
                          .value;
                      return Opacity(
                        opacity: opacity,
                        child: Transform.rotate(
                          angle: rotate,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow
                              Opacity(
                                opacity: glowOpacity,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF049281),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF049281),
                                        blurRadius: 60,
                                        spreadRadius: 20,
                                        offset: Offset.zero,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Logo
                              Transform.scale(
                                scale: scale,
                                child: Image.asset(
                                  logoAsset,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  // Title
                  AnimatedBuilder(
                    animation: titleCtrl,
                    builder: (context, _) {
                      final opacity = titleCtrl.value;
                      final slide = 50 * (1 - titleCtrl.value);
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, slide),
                          child: Column(
                            children: [
                              Text(
                                "Eye Test",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: const Color(
                                        0xFF049281,
                                      ).withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                width: 60,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF049281),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  // Subtitle
                  AnimatedBuilder(
                    animation: subtitleCtrl,
                    builder: (context, _) {
                      final opacity = subtitleCtrl.value;
                      final slide = 30 * (1 - subtitleCtrl.value);
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, slide),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(
                              "Test your vision anytime, anywhere",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(204, 255, 255, 255),
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                                height: 1.2,
                                shadows: [],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Bottom loading & decorative line
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: AnimatedBuilder(
              animation: subtitleCtrl,
              builder: (context, _) {
                final opacity = subtitleCtrl.value;
                return Opacity(
                  opacity: opacity,
                  child: Column(
                    children: [
                      // Loading indicator
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            // Loading Bar
                            Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Container(
                                  width: 84, // 70% of 120
                                  height: 3,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF049281),
                                        Color(0xFF06B399),
                                        Color(0xFF049281),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Loading...",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(153, 255, 255, 255),
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Decorative line
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        height: 1,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color.fromRGBO(4, 146, 129, 0.2),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
