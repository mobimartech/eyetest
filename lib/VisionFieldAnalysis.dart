import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class VisionFieldTest extends StatefulWidget {
  const VisionFieldTest({Key? key}) : super(key: key);

  @override
  State<VisionFieldTest> createState() => _VisionFieldTestState();
}

class _VisionFieldTestState extends State<VisionFieldTest>
    with TickerProviderStateMixin {
  bool testStarted = false;
  String testPhase = 'instructions'; // instructions, testing, complete
  String testResult = '';
  bool feedbackVisible = false;

  late AnimationController _movementController;
  late AnimationController _fadeController;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _movementTimer;
  int _currentPathIndex = 0;

  List<Offset> _movementPath = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to access MediaQuery here
    if (_movementPath.isEmpty) {
      _generateMovementPath();
    }
  }

  void _initializeAnimations() {
    _movementController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _positionAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(parent: _movementController, curve: Curves.linear),
        );
  }

  void _generateMovementPath() {
    final size = MediaQuery.of(context).size;
    _movementPath = [
      Offset(size.width / 2 - 10, size.height / 2 - 10),
      const Offset(50, 100),
      Offset(50, size.height - 300),
      Offset(size.width - 100, size.height - 300),
      Offset(size.width - 100, 100),
      Offset(size.width / 2 - 10, size.height / 2 - 10),
    ];
  }

  void _startMovingObject() {
    _fadeController.forward();
    _currentPathIndex = 0;
    _animateToNextPoint();
  }

  void _animateToNextPoint() {
    if (_currentPathIndex >= _movementPath.length - 1) {
      _currentPathIndex = 0;
    }

    final start = _movementPath[_currentPathIndex];
    final end = _movementPath[_currentPathIndex + 1];

    _positionAnimation = Tween<Offset>(begin: start, end: end).animate(
      CurvedAnimation(parent: _movementController, curve: Curves.linear),
    );

    _movementController.reset();
    _movementController.forward().then((_) {
      _currentPathIndex++;
      if (testStarted && mounted) {
        _animateToNextPoint();
      }
    });
  }

  void _handleStartTest() {
    setState(() {
      testStarted = true;
      testPhase = 'testing';
    });
    _startMovingObject();
  }

  void _handleStopTest() {
    setState(() {
      testStarted = false;
      testPhase = 'complete';
      testResult =
          'Test completed. If you frequently lose sight of moving objects in your peripheral vision, consider consulting an eye care professional for a comprehensive visual field examination.';
      feedbackVisible = true;
    });

    _fadeController.reverse();
    _movementController.stop();
  }

  void _resetTest() {
    setState(() {
      testStarted = false;
      testPhase = 'instructions';
      feedbackVisible = false;
    });
    _movementController.reset();
    _fadeController.reset();
    _currentPathIndex = 0;
  }

  Future<void> _openSourceLink() async {
    final url = Uri.parse(
      'https://www.aao.org/eye-health/vision-tests/visual-field-test',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _movementController.dispose();
    _fadeController.dispose();
    _movementTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: testPhase == 'instructions'
                    ? _buildInstructionsView()
                    : testPhase == 'testing'
                    ? _buildTestingView()
                    : _buildCompleteView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String subtitle = '';
    if (testPhase == 'instructions') {
      subtitle = 'Peripheral Vision Assessment';
    } else if (testPhase == 'testing') {
      subtitle = 'Test in Progress';
    } else if (testPhase == 'complete') {
      subtitle = 'Test Completed';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visual Field Test',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFF4081),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4081).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF4081).withOpacity(0.3),
              ),
            ),
            child: const Center(
              child: Text('🎯', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructionCard(),
          const SizedBox(height: 24),
          _buildStepsCard(),
          const SizedBox(height: 24),
          _buildWarningCard(),
          const SizedBox(height: 24),
          _buildActionButton(
            onPressed: _handleStartTest,
            title: 'Start Visual Field Test',
            isPrimary: true,
            icon: '▶',
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _openSourceLink,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                '🔗 Learn more about visual field tests',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFFF4081),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4081).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('ℹ️', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Instructions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This test evaluates your peripheral vision by tracking a moving object while focusing on a central point.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFAAAAAA),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to Take the Test',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildStepItem(
            '1',
            'Keep your eyes focused on the center point at all times',
          ),
          const SizedBox(height: 16),
          _buildStepItem(
            '2',
            'Use your peripheral vision to track the moving red dot',
          ),
          const SizedBox(height: 16),
          _buildStepItem(
            '3',
            'Tap anywhere on screen when you lose sight of the moving object',
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4081),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A0A0A),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFAAAAAA),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D1B1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A2626)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('⚠️', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This is a basic screening test. For comprehensive visual field assessment, please consult an eye care professional.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFFCCCB),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestingView() {
    return GestureDetector(
      onTap: _handleStopTest,
      child: Container(
        color: const Color(0xFF0A0A0A),
        child: Stack(
          children: [
            // Center Focus Point
            Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4081),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4081).withOpacity(0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Moving Object
            if (_movementPath.isNotEmpty)
              AnimatedBuilder(
                animation: _positionAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: _positionAnimation.value.dx,
                    top: _positionAnimation.value.dy,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4444).withOpacity(0.6),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Instruction Overlay
            Positioned(
              top: 100,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Focus on the center • Tap when object disappears',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Stop Button
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: _buildActionButton(
                onPressed: () {
                  setState(() {
                    testStarted = false;
                    testPhase = 'instructions';
                  });
                  _movementController.stop();
                  _fadeController.reverse();
                },
                title: 'Stop Test',
                isPrimary: false,
                icon: '⏹️',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Column(
              children: [
                const Text(
                  '✓',
                  style: TextStyle(fontSize: 48, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Test Complete',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  testResult,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFAAAAAA),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            onPressed: _resetTest,
            title: 'Take Test Again',
            isPrimary: true,
            icon: '🔄',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String title,
    required bool isPrimary,
    String? icon,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFFF4081) : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isPrimary ? const Color(0xFF0A0A0A) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
