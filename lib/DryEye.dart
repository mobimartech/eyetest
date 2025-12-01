import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class DryEyeTest extends StatefulWidget {
  const DryEyeTest({Key? key}) : super(key: key);

  @override
  State<DryEyeTest> createState() => _DryEyeTestState();
}

class _DryEyeTestState extends State<DryEyeTest>
    with SingleTickerProviderStateMixin {
  Map<String, bool> symptoms = {
    'dryness': false,
    'irritation': false,
    'redness': false,
    'foreignBody': false,
    'sensitivity': false,
  };

  bool testCompleted = false;
  bool showResultDialog = false;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

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
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      symptoms[symptom] = !symptoms[symptom]!;
    });

    // Subtle animation
    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
    _scaleController.forward(from: 0);
  }

  void _handleSubmit() {
    setState(() {
      testCompleted = true;
      showResultDialog = true;
    });

    // Completion animation
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
    _scaleController.forward(from: 0);
  }

  void _resetTest() {
    setState(() {
      testCompleted = false;
      showResultDialog = false;
      symptoms = {
        'dryness': false,
        'irritation': false,
        'redness': false,
        'foreignBody': false,
        'sensitivity': false,
      };
    });
    _scaleController.reset();
  }

  Map<String, dynamic> _calculateResult() {
    final selectedSymptoms = symptoms.entries
        .where((entry) => entry.value)
        .map((e) => e.key)
        .toList();

    if (selectedSymptoms.length == 1) {
      switch (selectedSymptoms[0]) {
        case 'dryness':
          return {
            'type': 'mild',
            'title': 'dry_eye.results.single.dryness.title'.tr(),
            'description': 'dry_eye.results.single.dryness.description'.tr(),
            'recommendations': 'dry_eye.results.single.dryness.recommendation'
                .tr(),
            'learnMoreUrl': 'https://www.aao.org/eye-health/diseases/dry-eye',
          };
        case 'irritation':
          return {
            'type': 'mild',
            'title': 'dry_eye.results.single.irritation.title'.tr(),
            'description': 'dry_eye.results.single.irritation.description'.tr(),
            'recommendations':
                'dry_eye.results.single.irritation.recommendation'.tr(),
            'learnMoreUrl': 'https://www.aao.org/eye-health/diseases/dry-eye',
          };
        case 'redness':
          return {
            'type': 'moderate',
            'title': 'dry_eye.results.single.redness.title'.tr(),
            'description': 'dry_eye.results.single.redness.description'.tr(),
            'recommendations': 'dry_eye.results.single.redness.recommendation'
                .tr(),
            'learnMoreUrl': 'https://www.aao.org/eye-health/diseases/dry-eye',
          };
        case 'foreignBody':
          return {
            'type': 'moderate',
            'title': 'dry_eye.results.single.foreign_body.title'.tr(),
            'description': 'dry_eye.results.single.foreign_body.description'
                .tr(),
            'recommendations':
                'dry_eye.results.single.foreign_body.recommendation'.tr(),
            'learnMoreUrl': 'https://www.aao.org/eye-health/diseases/dry-eye',
          };
        case 'sensitivity':
          return {
            'type': 'moderate',
            'title': 'dry_eye.results.single.sensitivity.title'.tr(),
            'description': 'dry_eye.results.single.sensitivity.description'
                .tr(),
            'recommendations':
                'dry_eye.results.single.sensitivity.recommendation'.tr(),
            'learnMoreUrl': 'https://www.aao.org/eye-health/diseases/dry-eye',
          };
        default:
          return _getNoSymptomsResult();
      }
    } else if (selectedSymptoms.length > 1) {
      return {
        'type': 'severe',
        'title': 'dry_eye.results.multiple.title'.tr(),
        'description': 'dry_eye.results.multiple.description'.tr(),
        'recommendations': 'dry_eye.results.multiple.recommendation'.tr(),
        'learnMoreUrl': 'https://www.aao.org/eye-health/diseases/dry-eye',
      };
    } else {
      return _getNoSymptomsResult();
    }
  }

  Map<String, dynamic> _getNoSymptomsResult() {
    return {
      'type': 'none',
      'title': 'dry_eye.results.none.title'.tr(),
      'description': 'dry_eye.results.none.description'.tr(),
      'recommendations': 'dry_eye.results.none.recommendation'.tr(),
      'learnMoreUrl':
          'https://www.aao.org/search/public/results?q=dry%20eye&realmName=_UREALM_&wt=json&rows=10&start=0&user_id=',
    };
  }

  Future<void> _openLearnMore(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Map<String, dynamic> _getSymptomData(String symptom) {
    final data = {
      'dryness': {'label': 'dry_eye.symptoms.dryness'.tr(), 'icon': '💧'},
      'irritation': {'label': 'dry_eye.symptoms.irritation'.tr(), 'icon': '🔥'},
      'redness': {'label': 'dry_eye.symptoms.redness'.tr(), 'icon': '🔴'},
      'foreignBody': {
        'label': 'dry_eye.symptoms.foreign_body'.tr(),
        'icon': 'ℹ️',
      },
      'sensitivity': {
        'label': 'dry_eye.symptoms.sensitivity'.tr(),
        'icon': '☀️',
      },
    };
    return data[symptom] ?? {'label': '', 'icon': ''};
  }

  int get _selectedCount => symptoms.values.where((v) => v).length;

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!testCompleted) ...[
                        _buildInstructionCard(),
                        const SizedBox(height: 24),
                        _buildSymptomsCard(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                        const SizedBox(height: 32),
                        _buildTipsContainer(),
                      ] else ...[
                        _buildResultCard(),
                        const SizedBox(height: 24),
                        _buildActionButton(
                          onPressed: _resetTest,
                          title: 'dry_eye.buttons.retry'.tr(),
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
                  'dry_eye.title'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  testCompleted
                      ? 'dry_eye.header.subtitle_complete'.tr()
                      : 'dry_eye.header.subtitle_testing'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF18FFFF),
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
              color: const Color(0xFF18FFFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF18FFFF).withOpacity(0.3),
              ),
            ),
            child: const Center(
              child: Text('💧', style: TextStyle(fontSize: 18)),
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
              color: const Color(0xFF18FFFF).withOpacity(0.2),
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
                  'dry_eye.instructions.title'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'dry_eye.instructions.description'.tr(),
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

  Widget _buildSymptomsCard() {
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
                      'dry_eye.select_symptoms'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18FFFF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF18FFFF).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$_selectedCount/5',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF18FFFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...symptoms.keys.map((symptom) {
                  final data = _getSymptomData(symptom);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSymptomCheckbox(
                      symptom: symptom,
                      label: data['label'] as String,
                      icon: data['icon'] as String,
                      isChecked: symptoms[symptom]!,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSymptomCheckbox({
    required String symptom,
    required String label,
    required String icon,
    required bool isChecked,
  }) {
    return GestureDetector(
      onTap: () => _toggleSymptom(symptom),
      child: Container(
        decoration: BoxDecoration(
          color: isChecked
              ? const Color(0xFF18FFFF).withOpacity(0.1)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked
                ? const Color(0xFF18FFFF)
                : const Color(0xFF333333),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isChecked ? Colors.white : const Color(0xFFCCCCCC),
                  fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFF18FFFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isChecked
                      ? const Color(0xFF18FFFF)
                      : const Color(0xFF666666),
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Center(
                      child: Text(
                        '✓',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0A0A0A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return _buildActionButton(
      onPressed: _handleSubmit,
      title: _selectedCount > 0
          ? 'dry_eye.buttons.analyze'.tr(
              namedArgs: {'count': '$_selectedCount'},
            )
          : 'dry_eye.buttons.complete'.tr(),
      isPrimary: true,
      icon: '✓',
    );
  }

  Widget _buildResultCard() {
    final result = _calculateResult();
    final type = result['type'] as String;

    Color borderColor;
    Color backgroundColor;

    switch (type) {
      case 'severe':
        borderColor = const Color(0xFF4A2626);
        backgroundColor = const Color(0xFF2D1B1B);
        break;
      case 'moderate':
        borderColor = const Color(0xFF4A3A26);
        backgroundColor = const Color(0xFF2D231B);
        break;
      case 'mild':
        borderColor = const Color(0xFF26404A);
        backgroundColor = const Color(0xFF1B252D);
        break;
      default:
        borderColor = const Color(0xFF26482A);
        backgroundColor = const Color(0xFF1B2D1B);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                type == 'severe'
                    ? '🚨'
                    : type == 'moderate'
                    ? '⚠️'
                    : type == 'mild'
                    ? '💧'
                    : '✓',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result['title'] as String,
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
            result['description'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFCCCCCC),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'dry_eye.results.recommendations_title'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result['recommendations'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFAAAAAA),
              height: 1.4,
            ),
          ),
          // const SizedBox(height: 16),
          // GestureDetector(
          //   onTap: () => _openLearnMore(result['learnMoreUrl'] as String),
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //     decoration: BoxDecoration(
          //       color: const Color(0xFF18FFFF).withOpacity(0.2),
          //       borderRadius: BorderRadius.circular(12),
          //       border: Border.all(
          //         color: const Color(0xFF18FFFF).withOpacity(0.3),
          //       ),
          //     ),
          //     child: Text(
          //       'dry_eye.buttons.learn_more'.tr(),
          //       style: const TextStyle(
          //         fontSize: 14,
          //         color: Color(0xFF18FFFF),
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //   ),
          // ),
       
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
            'dry_eye.tips.title'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...[
            'dry_eye.tips.tip1',
            'dry_eye.tips.tip2',
            'dry_eye.tips.tip3',
            'dry_eye.tips.tip4',
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
              ? const Color(0xFF18FFFF)
              : isOutlined
              ? Colors.transparent
              : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16),
          border: isOutlined
              ? Border.all(color: const Color(0xFF18FFFF))
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
                    ? const Color(0xFF18FFFF)
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
