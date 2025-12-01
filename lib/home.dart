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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool isSubscribed = false;
  bool isAndroid = false; // Store platform info as state
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _chatButtonController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _chatButtonScaleAnimation;
  late Animation<double> _chatButtonOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkSubscriptionStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to access Theme.of(context) here
    isAndroid = Theme.of(context).platform == TargetPlatform.android;
    _updateChatButtonAnimation();
  }

  void _initializeAnimations() {
    // Floating animation
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Chat button animation
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
    if (isAndroid || isSubscribed) {
      _chatButtonController.forward();
    } else {
      _chatButtonController.reverse();
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final activeEntitlement = customerInfo.entitlements.active['pro'];
      setState(() {
        isSubscribed = activeEntitlement != null;
      });

      print('Subscription status: $isSubscribed');
      // Update animation after subscription check
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateChatButtonAnimation();
      });
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      setState(() {
        isSubscribed = false;
      });
    }
  }

  void _handleTestAccess(Widget destination) {
    if (isSubscribed || isAndroid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaywallScreen()),
      );
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

                      // ADD THIS TEST NOTIFICATION SECTION
                      // _buildNotificationTestSection(),
                      //  const SizedBox(height: 32),
                      _buildTestsSection(),
                      if (!isSubscribed && !isAndroid) ...[
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
                const Text(
                  'EyeTest',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Vision Analytics',
                  style: TextStyle(
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
                        color: isAndroid || isSubscribed
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF4081),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAndroid || isSubscribed
                          ? 'Premium Active'
                          : 'Free Version',
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
              if (!isSubscribed && Platform.isIOS)
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
              if (isSubscribed || Platform.isAndroid) ...[
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

  Widget _buildPremiumButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaywallScreen()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700),
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
              isSubscribed ? 'PRO' : 'UPGRADE',
              // (isAndroid || isSubscribed) ? 'PRO' : 'UPGRADE',
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
          color: const Color(0xFF18FFFF),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF00E5FF), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF18FFFF).withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🤖', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text(
              'Ask AI',
              style: TextStyle(
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

  Widget _buildStatsContainer() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('6', 'Total Tests')),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            isAndroid || isSubscribed ? '6' : '1',
            'Available',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('∞', 'Uses')),
      ],
    );
  }

  Widget _buildStatCard(String number, String label) {
    // Get screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive font sizes based on screen width
    final numberFontSize = screenWidth * 0.08; // 7% of screen width
    final labelFontSize = screenWidth * 0.03; // 2.5% of screen width

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
                fontSize: numberFontSize.clamp(20.0, 32.0), // Min 20, Max 32
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: labelFontSize.clamp(10.0, 14.0), // Min 10, Max 14
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

  Widget _buildNotificationTestSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🔔', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Text(
                'Notification Test',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Test your daily challenge notifications',
            style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 20),

          // Test Immediate Notification Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await NotificationService().showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '✅ Test notification sent! Check your notification bar',
                      ),
                      backgroundColor: Color(0xFF00E676),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const Text(
                '🚀 Send Test Notification NOW',
                style: TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Toggle Daily Reminder
          FutureBuilder<bool>(
            future: NotificationService().isNotificationEnabled(),
            builder: (context, snapshot) {
              final isEnabled = snapshot.data ?? false;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Reminder (8 PM)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Get reminded every day',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isEnabled,
                      activeColor: const Color(0xFF00E5FF),
                      onChanged: (value) async {
                        await NotificationService().setNotificationEnabled(
                          value,
                        );
                        setState(() {});

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? '✅ Daily reminders enabled!'
                                    : '❌ Daily reminders disabled',
                              ),
                              backgroundColor: const Color(0xFF00E5FF),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Schedule Test for 10 seconds from now
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF00E5FF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // Schedule a notification for 10 seconds from now
                await NotificationService()
                    .scheduleTestNotificationIn10Seconds();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '⏰ Notification scheduled for 10 seconds from now',
                      ),
                      backgroundColor: Color(0xFFFFD740),
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              },
              child: const Text(
                '⏰ Schedule Test in 10 Seconds',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallengeCard() {
    //if (!isAndroid && !isSubscribed) return const SizedBox.shrink();

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
              setState(() {}); // Refresh to update completion status
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
                // Animated background effect
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
                      // Challenge Icon
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
                      // Challenge Info
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
                                  child: const Row(
                                    children: [
                                      Text('⚡', style: TextStyle(fontSize: 10)),
                                      SizedBox(width: 4),
                                      Text(
                                        'DAILY',
                                        style: TextStyle(
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
                                    child: const Row(
                                      children: [
                                        Text(
                                          '✓',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Done',
                                          style: TextStyle(
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
                              challenge.title,
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
                      // Arrow icon
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
                              color: isCompleted
                                  ? Colors.white54
                                  : Colors.white,
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
        title: 'Visual Acuity Test',
        description:
            'Comprehensive clarity assessment using advanced Snellen methodology',
        icon: '👁️',
        accentColor: const Color(0xFF00E5FF),
        route: VisualAcuityTest(),
        isLocked: false,
        isPrimary: true,
      ),
      TestData(
        title: 'Vision Field Analysis',
        description:
            'Advanced peripheral vision mapping and blind spot detection',
        icon: '🎯',
        accentColor: const Color(0xFFFF4081),
        route: VisionFieldTest(),
        isLocked: true,
      ),
      TestData(
        title: 'Color Perception Test',
        description: 'Professional Ishihara color vision deficiency screening',
        icon: '🎨',
        accentColor: const Color(0xFF7C4DFF),
        route: ColorVisionTest(),
        isLocked: true,
      ),
      TestData(
        title: 'Astigmatism Screening',
        description: 'Precise corneal irregularity detection and measurement',
        icon: '⚡',
        accentColor: const Color(0xFFFFD740),
        route: AstigmatismTest(),
        isLocked: true,
      ),
      TestData(
        title: 'Amsler Grid Analysis',
        description:
            'Macular degeneration and central vision distortion screening',
        icon: '⊞',
        accentColor: const Color(0xFFFF6E40),
        route: AmslerGridTest(),
        isLocked: true,
      ),
      TestData(
        title: 'Dry Eye Assessment',
        description:
            'Comprehensive tear film stability and eye comfort evaluation',
        icon: '💧',
        accentColor: const Color(0xFF18FFFF),
        route: DryEyeTest(),
        isLocked: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vision Assessment Suite',
          style: TextStyle(
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
        // Use ClipRRect to clip the accent line to the container's border radius
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Accent line - NOW PROPERLY CLIPPED
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  color: test.accentColor, // Use color instead of decoration
                ),
              ),
              if (test.isLocked && !isSubscribed && !isAndroid)
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
                          test.isLocked && !isSubscribed && !isAndroid
                              ? 'Upgrade to Access'
                              : 'Start Test',
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaywallScreen()),
      ),
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
                const Text(
                  'Unlock Professional Analysis',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get access to all vision tests with detailed reports and tracking',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFAAAAAA),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ...[
                  '• All 6 Professional Tests',
                  '• AI Eye Doctor Chat',
                  '• Detailed Analytics',
                  '• Progress Tracking',
                  '• No Ads',
                ].map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      feature,
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
                  child: const Text(
                    'Upgrade Now',
                    style: TextStyle(
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
