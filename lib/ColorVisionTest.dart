import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorVisionTest extends StatefulWidget {
  const ColorVisionTest({Key? key}) : super(key: key);

  @override
  State<ColorVisionTest> createState() => _ColorVisionTestState();
}

class _ColorVisionTestState extends State<ColorVisionTest>
    with TickerProviderStateMixin {
  int step = 0;
  String answer = '';
  String feedback = '';
  bool isCorrect = false;
  List<String> userAnswers = List.filled(6, '');
  bool showFeedback = false;

  late AnimationController _progressController;
  late AnimationController _feedbackController;
  late Animation<double> _progressAnimation;
  late Animation<double> _feedbackOpacity;
  late Animation<double> _feedbackScale;

  final TextEditingController _textController = TextEditingController();

  final List<String> testImages = [
    'assets/img/ColorVisionTest1.png',
    'assets/img/ColorVisionTest2.jpg',
    'assets/img/ColorVisionTest3.png',
    'assets/img/ColorVisionTest4.png',
    'assets/img/ColorVisionTest5.png',
    'assets/img/ColorVisionTest6.png',
  ];

  final List<String> correctAnswers = ['12', '27', '5', '6', 'N', 'W'];
  final List<String> testDescriptions = [
    'Plate 1',
    'Plate 2',
    'Plate 3',
    'Plate 4',
    'Plate 5',
    'Plate 6',
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: (step + 1) / testImages.length,
    ).animate(_progressController);

    _feedbackOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_feedbackController);
    _feedbackScale = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(_feedbackController);

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _feedbackController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: (step + 1) / testImages.length,
    ).animate(_progressController);
    _progressController.reset();
    _progressController.forward();
  }

  void handleCheck() {
    userAnswers[step] = answer;

    if (answer.toLowerCase() == correctAnswers[step].toLowerCase()) {
      setState(() {
        feedback = 'Correct! Well done.';
        isCorrect = true;
        showFeedback = true;
      });
    } else {
      setState(() {
        feedback = 'Incorrect. The correct answer is: ${correctAnswers[step]}';
        isCorrect = false;
        showFeedback = true;
      });
    }

    _feedbackController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _feedbackController.reverse().then((_) {
            if (mounted) {
              setState(() => showFeedback = false);
            }
          });
        }
      });
    });
  }

  void handleNext() {
    setState(() {
      feedback = '';
      isCorrect = false;
      showFeedback = false;
    });

    if (step < testImages.length - 1) {
      setState(() {
        step++;
        answer = userAnswers[step];
        _textController.text = answer;
      });
      _updateProgress();
    } else {
      _showResults();
    }
  }

  void handlePrevious() {
    if (step > 0) {
      setState(() {
        step--;
        answer = userAnswers[step];
        _textController.text = answer;
        feedback = '';
        isCorrect = false;
        showFeedback = false;
      });
      _updateProgress();
    }
  }

  void _showResults() {
    int correctCount = 0;
    for (int i = 0; i < userAnswers.length; i++) {
      if (userAnswers[i].toLowerCase() == correctAnswers[i].toLowerCase()) {
        correctCount++;
      }
    }

    int percentage = ((correctCount / testImages.length) * 100).round();
    String resultMessage =
        'Test Complete!\n\nScore: $correctCount/${testImages.length} ($percentage%)\n\n';

    if (percentage >= 80) {
      resultMessage += 'Excellent! Your color vision appears to be normal.';
    } else if (percentage >= 60) {
      resultMessage +=
          'Good results, but consider consulting an eye care professional for a comprehensive examination.';
    } else {
      resultMessage +=
          'Consider consulting an eye care professional for a thorough color vision assessment.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Test Results',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          resultMessage,
          style: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF7C4DFF))),
          ),
        ],
      ),
    );
  }

  void _showHintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '💡 Helpful Hint',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Focus on the different colors and shades in the dot pattern. Numbers or letters are formed by dots of similar colors grouping together. If you have difficulty seeing any pattern, that information is also valuable for assessment.',
          style: TextStyle(color: Color(0xFFAAAAAA), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Got it!',
                style: TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                      _buildInstructionCard(),
                      const SizedBox(height: 24),
                      _buildTestImageCard(),
                      const SizedBox(height: 24),
                      _buildAnswerInputCard(),
                      const SizedBox(height: 24),
                      _buildControls(),
                      const SizedBox(height: 32),
                      _buildTipsContainer(),
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
                const Text(
                  'Color Vision Test',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Plate ${step + 1} of ${testImages.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7C4DFF),
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
              color: const Color(0xFF7C4DFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF7C4DFF).withOpacity(0.3),
              ),
            ),
            child: const Center(
              child: Text('🎨', style: TextStyle(fontSize: 18)),
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
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${((step + 1) / testImages.length * 100).round()}% Complete',
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
              color: const Color(0xFF7C4DFF).withOpacity(0.2),
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
                  'Look at the colored dots below and identify any number or letter you can see hidden within the pattern.',
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

  Widget _buildTestImageCard() {
    return Container(
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
                testDescriptions[step],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: _showHintDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF7C4DFF).withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    '💡 Hint',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7C4DFF),
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
              testImages[step],
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInputCard() {
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
            'What do you see?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            onChanged: (value) => setState(() => answer = value),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Enter number or letter',
              hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
              filled: true,
              fillColor: const Color(0xFF333333),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF555555)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF555555)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF7C4DFF),
                  width: 2,
                ),
              ),
            ),
          ),
          if (showFeedback) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _feedbackController,
              builder: (context, child) {
                return Opacity(
                  opacity: _feedbackOpacity.value,
                  child: Transform.scale(
                    scale: _feedbackScale.value,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFF5D1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCorrect
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFF44336),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            isCorrect ? '✓' : '✗',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feedback,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        Row(
          children: [
            if (step > 0)
              Expanded(
                child: _buildActionButton(
                  onPressed: handlePrevious,
                  title: 'Previous',
                  isPrimary: false,
                  icon: '←',
                ),
              ),
            if (step > 0) const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                onPressed: handleCheck,
                title: 'Check Answer',
                isPrimary: true,
                disabled: answer.trim().isEmpty,
                icon: '✓',
              ),
            ),
          ],
        ),
        if (isCorrect) ...[
          const SizedBox(height: 16),
          _buildActionButton(
            onPressed: handleNext,
            title: step < testImages.length - 1 ? 'Next Plate' : 'Finish Test',
            isPrimary: true,
            icon: step < testImages.length - 1 ? '→' : '✓',
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            testImages.length,
            (index) => Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == step
                    ? const Color(0xFF7C4DFF)
                    : index < step
                    ? (userAnswers[index].toLowerCase() ==
                              correctAnswers[index].toLowerCase()
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF666666))
                    : const Color(0xFF333333),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String title,
    required bool isPrimary,
    bool disabled = false,
    String? icon,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFF2A2A2A)
              : isPrimary
              ? const Color(0xFF7C4DFF)
              : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Text(
                icon,
                style: TextStyle(
                  fontSize: 16,
                  color: disabled
                      ? const Color(0xFF666666)
                      : isPrimary
                      ? const Color(0xFF0A0A0A)
                      : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: disabled
                    ? const Color(0xFF666666)
                    : isPrimary
                    ? const Color(0xFF0A0A0A)
                    : Colors.white,
              ),
            ),
          ],
        ),
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
          const Text(
            '💡 Testing Tips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...[
            '• Look for patterns formed by different colored dots',
            '• Take your time - there\'s no rush',
            '• If you can\'t see anything, that\'s also valid information',
            '• Ensure good lighting conditions for accurate results',
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tip,
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
}
