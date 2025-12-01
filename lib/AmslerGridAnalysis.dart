import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class AmslerGridTest extends StatefulWidget {
  const AmslerGridTest({Key? key}) : super(key: key);

  @override
  State<AmslerGridTest> createState() => _AmslerGridTestState();
}

class _AmslerGridTestState extends State<AmslerGridTest>
    with SingleTickerProviderStateMixin {
  bool showHintDialog = false;
  bool showFeedbackDialog = false;
  String? selectedOption;
  bool testCompleted = false;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(
      begin: 0.5,
      end: testCompleted ? 1.0 : 0.5,
    ).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleAnswer(String option) {
    setState(() {
      selectedOption = option;
      testCompleted = true;
      showFeedbackDialog = true;
    });

    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: 1.0,
    ).animate(_scaleController);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
    _scaleController.forward(from: 0);
  }

  void _resetTest() {
    setState(() {
      testCompleted = false;
      selectedOption = null;
      showFeedbackDialog = false;
    });
    _scaleController.reset();
  }

  Future<void> _openLearnMore(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
              _buildProgressBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!testCompleted) ...[
                        _buildInstructionCard(),
                        const SizedBox(height: 24),
                        _buildTestImageCard(),
                        const SizedBox(height: 24),
                        _buildQuestionCard(),
                        const SizedBox(height: 24),
                        _buildAnswerButtons(),
                        const SizedBox(height: 32),
                        _buildTipsContainer(),
                      ] else ...[
                        _buildResultCard(),
                        const SizedBox(height: 24),
                        _buildActionButton(
                          onPressed: _resetTest,
                          title: 'amsler_grid.buttons.retry'.tr(),
                          isOutlined: true,
                          icon: '🔄',
                        ),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                Text(
                  'amsler_grid.title'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  testCompleted
                      ? 'amsler_grid.header.subtitle_complete'.tr()
                      : 'amsler_grid.header.subtitle_testing'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFF6E40),
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
              color: const Color(0xFFFF6E40).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF6E40).withOpacity(0.3),
              ),
            ),
            child: const Center(
              child: Text('⊞', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: testCompleted ? 1.0 : 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6E40),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            testCompleted
                ? 'amsler_grid.progress.complete'.tr()
                : 'amsler_grid.progress.half'.tr(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFAAAAAA),
              fontWeight: FontWeight.w600,
            ),
          ),
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
              color: const Color(0xFFFF6E40).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('ℹ️', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'amsler_grid.instructions.title'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'amsler_grid.instructions.description'.tr(),
                  style: const TextStyle(
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

  Widget _buildTestImageCard() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'amsler_grid.chart_title'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => showHintDialog = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6E40).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFF6E40).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'amsler_grid.hint'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF6E40),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    'assets/img/amsler_grid.png',
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard() {
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
          Text(
            'amsler_grid.question.title'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'amsler_grid.question.description'.tr(),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFAAAAAA),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButtons() {
    return Column(
      children: [
        _buildActionButton(
          onPressed: () => _handleAnswer('Yes'),
          title: 'amsler_grid.answers.yes'.tr(),
          isPrimary: true,
          icon: '⚠️',
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          onPressed: () => _handleAnswer('No'),
          title: 'amsler_grid.answers.no'.tr(),
          isOutlined: true,
          icon: '✓',
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final isPositive = selectedOption == 'Yes';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPositive ? const Color(0xFF2D1B1B) : const Color(0xFF1B2D1B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPositive ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isPositive ? '⚠️' : '✓',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isPositive
                      ? 'amsler_grid.result.positive.title'.tr()
                      : 'amsler_grid.result.negative.title'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isPositive
                ? 'amsler_grid.result.positive.description'.tr()
                : 'amsler_grid.result.negative.description'.tr(),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFCCCCCC),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'amsler_grid.result.recommendations_title'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPositive
                ? 'amsler_grid.result.positive.recommendation'.tr()
                : 'amsler_grid.result.negative.recommendation'.tr(),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFAAAAAA),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _openLearnMore(
              'https://www.aao.org/search/public/results?q=amsler%20grid%20test',
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6E40).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6E40).withOpacity(0.3),
                ),
              ),
              child: Text(
                'amsler_grid.buttons.learn_more'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFFF6E40),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsContainer() {
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
          Text(
            'amsler_grid.tips.title'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...[
            'amsler_grid.tips.tip1',
            'amsler_grid.tips.tip2',
            'amsler_grid.tips.tip3',
            'amsler_grid.tips.tip4',
          ].map(
            (tipKey) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tipKey.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFAAAAAA),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String title,
    bool isPrimary = false,
    bool isOutlined = false,
    String? icon,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFFFF6E40)
              : isOutlined
              ? Colors.transparent
              : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16),
          border: isOutlined
              ? Border.all(color: const Color(0xFFFF6E40))
              : null,
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
                color: isPrimary
                    ? const Color(0xFF0A0A0A)
                    : isOutlined
                    ? const Color(0xFFFF6E40)
                    : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
