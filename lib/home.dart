import 'dart:io';

import 'package:eyetest/AmslerGridAnalysis.dart';
import 'package:eyetest/Astigmatismtest.dart';
import 'package:eyetest/ColorVisionTest.dart';
import 'package:eyetest/DryEye.dart';
import 'package:eyetest/VisionFieldAnalysis.dart';
import 'package:eyetest/VisualAcuityTest.dart';
import 'package:eyetest/challenge_service.dart';
import 'package:eyetest/chatai.dart';
import 'package:eyetest/daily_challenge_page.dart';
import 'package:eyetest/notification_service.dart';
import 'package:eyetest/paywall.dart';
import 'package:eyetest/paywallandroid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool isSubscribed = true;
  // bool isAndroid = false;
  bool isloggedin = false;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _chatButtonController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _chatButtonScaleAnimation;
  late Animation<double> _chatButtonOpacityAnimation;

  // Language data
  final Map<String, Map<String, String>> languages = {
    'en': {'name': 'English', 'flag': '🇺🇸', 'nativeName': 'English'},
    'es': {'name': 'Spanish', 'flag': '🇪🇸', 'nativeName': 'Español'},
    'fr': {'name': 'French', 'flag': '🇫🇷', 'nativeName': 'Français'},
    'de': {'name': 'German', 'flag': '🇩🇪', 'nativeName': 'Deutsch'},
    'ar': {'name': 'Arabic', 'flag': '🇸🇦', 'nativeName': 'العربية'},
    'zh': {'name': 'Chinese', 'flag': '🇨🇳', 'nativeName': '中文'},
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkSubscriptionStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // isAndroid = Theme.of(context).platform == TargetPlatform.android;
    _updateChatButtonAnimation();
  }

  void _initializeAnimations() {
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _chatButtonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _chatButtonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _chatButtonController, curve: Curves.easeOut),
    );

    _chatButtonOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chatButtonController, curve: Curves.easeOut),
    );
  }

  void _updateChatButtonAnimation() {
    if (isloggedin || isSubscribed) {
      _chatButtonController.forward();
    } else {
      _chatButtonController.reverse();
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    await handleisloggedin();
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final activeEntitlement = customerInfo.entitlements.active['pro'];
      setState(() {
        isSubscribed = activeEntitlement != null;
      });

      print('Subscription status: $isSubscribed');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateChatButtonAnimation();
      });
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      setState(() {
        isSubscribed = true;
      });
    }
  }

  handleisloggedin() async {
    final prefs = await SharedPreferences.getInstance();
    final legged = prefs.getBool('isLoggedIn') ?? false;
    setState(() {
      isloggedin = legged;
    });
  }

  Future<void> _handleTestAccess(Widget destination) async {
    final prefs = await SharedPreferences.getInstance();
    final isloggedin = prefs.getBool('isLoggedIn') ?? false;
    if (isSubscribed || isloggedin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } else {
      if (Platform.isAndroid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PaywallAndroid()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PaywallScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    _chatButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildStatsContainer(),
                      const SizedBox(height: 32),
                      _buildTestsSection(),
                      if (!isSubscribed && !isloggedin) ...[
                        const SizedBox(height: 20),
                        _buildPremiumCTA(),
                      ],
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                Text(
                  'app_title'.tr(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'app_subtitle'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isloggedin || isSubscribed
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF4081),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isloggedin || isSubscribed
                          ? 'premium_active'.tr()
                          : 'free_version'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              // ENHANCED LANGUAGE SELECTOR - Always at top
              _buildModernLanguageSelector(),
              const SizedBox(width: 8),
              const SizedBox(height: 12),
              // UPGRADE BUTTON - Below language selector
              if (!isSubscribed && !isloggedin)
                AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatingAnimation.value),
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: _buildPremiumButton(),
                      ),
                    );
                  },
                ),
              // CHAT AI BUTTON - Below upgrade button
              if (isSubscribed || isloggedin) ...[
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _chatButtonController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _chatButtonScaleAnimation.value,
                      child: Opacity(
                        opacity: _chatButtonOpacityAnimation.value,
                        child: _buildChatButton(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // MODERN ENHANCED LANGUAGE SELECTOR
  Widget _buildModernLanguageSelector() {
    final currentLocale = context.locale;
    final currentLang =
        languages[currentLocale.languageCode] ?? languages['en']!;

    return GestureDetector(
      onTap: _showLanguageBottomSheet,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00E5FF).withOpacity(0.15),
              const Color(0xFF049281).withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00E5FF).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Globe icon with glow
            // Container(
            //   width: 28,
            //   height: 28,
            //   decoration: BoxDecoration(
            //     color: const Color(0xFF00E5FF).withOpacity(0.2),
            //     shape: BoxShape.circle,
            //   ),
            //   child: Center(
            //     child: Text('🌐', style: const TextStyle(fontSize: 14)),
            //   ),
            // ),
            const SizedBox(width: 8),
            // Current language flag
            Text(currentLang['flag']!, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            // Dropdown indicator
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF00E5FF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LanguageBottomSheet(
        languages: languages,
        currentLocale: context.locale,
        onLanguageSelected: (locale) {
          context.setLocale(locale);
          Navigator.pop(context);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildPremiumButton() {
    return GestureDetector(
      onTap: () {
        if (Platform.isAndroid) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PaywallAndroid()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PaywallScreen()),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/img/crown.png',
              width: 20,
              height: 20,
              color: const Color(0xFF0A0A0A),
            ),
            const SizedBox(width: 8),
            Text(
              isSubscribed ? 'pro'.tr() : 'upgrade'.tr(),
              style: const TextStyle(
                color: Color(0xFF0A0A0A),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => AIChatPage())),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF18FFFF), const Color(0xFF00E5FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF00E5FF), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF18FFFF).withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤖', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              'ask_ai'.tr(),
              style: const TextStyle(
                color: Color(0xFF0A0A0A),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... rest of your existing widgets (buildStatsContainer, buildTestsSection, etc.)
  // Keep all other methods unchanged

  Widget _buildStatsContainer() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('6', 'total_tests')),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            isloggedin || isSubscribed ? '6' : '1',
            'available',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('∞', 'uses')),
      ],
    );
  }

  Widget _buildStatCard(String number, String labelKey) {
    final screenWidth = MediaQuery.of(context).size.width;
    final numberFontSize = screenWidth * 0.08;
    final labelFontSize = screenWidth * 0.03;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              number,
              style: TextStyle(
                fontSize: numberFontSize.clamp(20.0, 32.0),
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              labelKey.tr(),
              style: TextStyle(
                fontSize: labelFontSize.clamp(10.0, 14.0),
                color: const Color(0xFF888888),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallengeCard() {
    return FutureBuilder<bool>(
      future: ChallengeService.isTodayCompleted(),
      builder: (context, snapshot) {
        final isCompleted = snapshot.data ?? false;
        final challenge = ChallengeService.getDailyChallenge();

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DailyChallengeHomePage()),
            );
            if (result == true) {
              setState(() {});
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCompleted
                    ? [const Color(0xFF1A1A1A), const Color(0xFF1A1A1A)]
                    : [
                        const Color(0xFF049281).withOpacity(0.15),
                        const Color(0xFF037268).withOpacity(0.1),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF333333)
                    : const Color(0xFF049281).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: isCompleted
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFF049281).withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                if (!isCompleted)
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF049281).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF049281), Color(0xFF037268)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF049281).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            challenge.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF049281),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        '⭐',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'daily_challenge.title'.tr(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                if (isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E676),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          '✓',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'done'.tr(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              challenge.title.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: Color(0xFF049281),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${challenge.duration.inSeconds}s',
                                  style: const TextStyle(
                                    color: Color(0xFF049281),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.stars_rounded,
                                  color: Color(0xFF049281),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+${challenge.xpReward} XP',
                                  style: const TextStyle(
                                    color: Color(0xFF049281),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF333333)
                              : const Color(0xFF049281),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            isCompleted ? '✓' : '→',
                            style: TextStyle(
                              color:
                                  isCompleted ? Colors.white54 : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestsSection() {
    final tests = [
      TestData(
        title: 'tests.visual_acuity.title'.tr(),
        description: 'tests.visual_acuity.description'.tr(),
        icon: '👁️',
        accentColor: const Color(0xFF00E5FF),
        route: VisualAcuityTest(),
        isLocked: false,
        isPrimary: true,
      ),
      TestData(
        title: 'tests.vision_field.title'.tr(),
        description: 'tests.vision_field.description'.tr(),
        icon: '🎯',
        accentColor: const Color(0xFFFF4081),
        route: VisionFieldTest(),
        isLocked: true,
      ),
      TestData(
        title: 'tests.color_vision.title'.tr(),
        description: 'tests.color_vision.description'.tr(),
        icon: '🎨',
        accentColor: const Color(0xFF7C4DFF),
        route: ColorVisionTest(),
        isLocked: true,
      ),
      TestData(
        title: 'tests.astigmatism.title'.tr(),
        description: 'tests.astigmatism.description'.tr(),
        icon: '⭐',
        accentColor: const Color(0xFFFFD740),
        route: AstigmatismTest(),
        isLocked: true,
      ),
      TestData(
        title: 'tests.amsler_grid.title'.tr(),
        description: 'tests.amsler_grid.description'.tr(),
        icon: '▦',
        accentColor: const Color(0xFFFF6E40),
        route: AmslerGridTest(),
        isLocked: true,
      ),
      TestData(
        title: 'tests.dry_eye.title'.tr(),
        description: 'tests.dry_eye.description'.tr(),
        icon: '💧',
        accentColor: const Color(0xFF18FFFF),
        route: DryEyeTest(),
        isLocked: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'vision_assessment_suite'.tr(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        _buildDailyChallengeCard(),
        const SizedBox(height: 24),
        ...tests.map(
          (test) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTestCard(test),
          ),
        ),
      ],
    );
  }

  Widget _buildTestCard(TestData test) {
    return GestureDetector(
      onTap: () => test.isLocked
          ? _handleTestAccess(test.route)
          : Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => test.route),
            ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(height: 3, color: test.accentColor),
              ),
              if (test.isLocked && !isSubscribed && !isloggedin)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      border: Border.all(color: test.accentColor, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: const Text('🔒', style: TextStyle(fontSize: 12)),
                  ),
                ),
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: test.accentColor.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: test.accentColor.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      test.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(100, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      test.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFAAAAAA),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          test.isLocked && !isSubscribed && !isloggedin
                              ? 'upgrade_to_access'.tr()
                              : 'start_test'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: test.accentColor,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: test.accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '→',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCTA() {
    return GestureDetector(
      onTap: () {
        if (Platform.isAndroid) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PaywallAndroid()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PaywallScreen()),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        padding: const EdgeInsets.all(28),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  'unlock_professional'.tr(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'unlock_description'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFAAAAAA),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ...[
                  'features.all_tests',
                  'features.ai_chat',
                  'features.analytics',
                  'features.tracking',
                  'features.no_ads',
                ].map(
                  (featureKey) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• ${featureKey.tr()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'upgrade_now'.tr(),
                    style: const TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// CUSTOM LANGUAGE BOTTOM SHEET WIDGET
class _LanguageBottomSheet extends StatelessWidget {
  final Map<String, Map<String, String>> languages;
  final Locale currentLocale;
  final Function(Locale) onLanguageSelected;

  const _LanguageBottomSheet({
    required this.languages,
    required this.currentLocale,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00E5FF).withOpacity(0.2),
                        const Color(0xFF049281).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🌐', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Language',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Choose your preferred language',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF333333), height: 1),
          // Language list
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final langCode = languages.keys.elementAt(index);
                final lang = languages[langCode]!;
                final isSelected = currentLocale.languageCode == langCode;

                return _LanguageItem(
                  flag: lang['flag']!,
                  nativeName: lang['nativeName']!,
                  englishName: lang['name']!,
                  isSelected: isSelected,
                  onTap: () => onLanguageSelected(Locale(langCode)),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// LANGUAGE ITEM WIDGET
class _LanguageItem extends StatelessWidget {
  final String flag;
  final String nativeName;
  final String englishName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageItem({
    required this.flag,
    required this.nativeName,
    required this.englishName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00E5FF).withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Flag
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00E5FF).withOpacity(0.3)
                      : const Color(0xFF333333),
                ),
              ),
              child: Center(
                child: Text(flag, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            // Language names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected ? const Color(0xFF00E5FF) : Colors.white,
                    ),
                  ),
                  Text(
                    englishName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            // Check mark
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: Color(0xFF0A0A0A),
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TestData {
  final String title;
  final String description;
  final String icon;
  final Color accentColor;
  final Widget route;
  final bool isLocked;
  final bool isPrimary;

  TestData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.route,
    this.isLocked = false,
    this.isPrimary = false,
  });
}
