import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

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
        feedback = 'color_vision.feedback.correct'.tr();
        isCorrect = true;
        showFeedback = true;
      });
    } else {
      setState(() {
        feedback = 'color_vision.feedback.incorrect'.tr(
          namedArgs: {'answer': correctAnswers[step]},
        );
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
    String resultMessage = 'color_vision.result.score'.tr(
      namedArgs: {
        'correct': '$correctCount',
        'total': '${testImages.length}',
        'percentage': '$percentage',
      },
    );

    String interpretation;
    if (percentage >= 80) {
      interpretation = 'color_vision.result.excellent'.tr();
    } else if (percentage >= 60) {
      interpretation = 'color_vision.result.good'.tr();
    } else {
      interpretation = 'color_vision.result.consult'.tr();
    }

    resultMessage += '\n\n$interpretation';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'color_vision.result.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
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
            child: Text(
              'color_vision.result.ok'.tr(),
              style: const TextStyle(color: Color(0xFF7C4DFF)),
            ),
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
        title: Text(
          'color_vision.hint_dialog.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'color_vision.hint_dialog.message'.tr(),
          style: const TextStyle(color: Color(0xFFAAAAAA), height: 1.4),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'color_vision.hint_dialog.got_it'.tr(),
                style: const TextStyle(
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
                Text(
                  'color_vision.title'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'color_vision.plate_counter'.tr(
                    namedArgs: {
                      'current': '${step + 1}',
                      'total': '${testImages.length}',
                    },
                  ),
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
            'color_vision.progress'.tr(
              namedArgs: {
                'percent': '${((step + 1) / testImages.length * 100).round()}',
              },
            ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'color_vision.instructions.title'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'color_vision.instructions.description'.tr(),
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
                'color_vision.plate_name'.tr(
                  namedArgs: {'number': '${step + 1}'},
                ),
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
                  child: Text(
                    'color_vision.hint'.tr(),
                    style: const TextStyle(
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
          Text(
            'color_vision.question'.tr(),
            style: const TextStyle(
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
              hintText: 'color_vision.input_placeholder'.tr(),
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
                  title: 'color_vision.buttons.previous'.tr(),
                  isPrimary: false,
                  icon: '←',
                ),
              ),
            if (step > 0) const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                onPressed: handleCheck,
                title: 'color_vision.buttons.check'.tr(),
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
            title: step < testImages.length - 1
                ? 'color_vision.buttons.next'.tr()
                : 'color_vision.buttons.finish'.tr(),
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
          Text(
            'color_vision.tips.title'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...[
            'color_vision.tips.tip1',
            'color_vision.tips.tip2',
            'color_vision.tips.tip3',
            'color_vision.tips.tip4',
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
}
