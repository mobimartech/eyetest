import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'vision_challenge.dart';
import 'challenge_service.dart';
import 'dart:ui';

class ChallengePlayPage extends StatefulWidget {
  final VisionChallenge challenge;

  const ChallengePlayPage({Key? key, required this.challenge})
    : super(key: key);

  @override
  State<ChallengePlayPage> createState() => _ChallengePlayPageState();
}

class _ChallengePlayPageState extends State<ChallengePlayPage> {
  late Timer _timer;
  int _secondsRemaining = 0;
  int _currentRound = 0;
  int _maxRounds = 5;
  bool _isPlaying = false;
  bool _isComplete = false;

  // Scoring metrics
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _streak = 0;
  int _maxStreak = 0;
  List<int> _responseTimes = [];
  DateTime? _roundStartTime;

  // Challenge-specific data
  int? _differentIndex;
  List<Color> _colors = [];
  List<double> _blurLevels = [];
  List<double> _contrastLevels = [];

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.challenge.duration.inSeconds;
    _startChallenge();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startChallenge() {
    setState(() {
      _isPlaying = true;
      _currentRound = 1;
    });
    _generateNewRound();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _endChallenge();
        }
      });
    });
  }

  void _generateNewRound() {
    _roundStartTime = DateTime.now();
    final random = Random();
    _differentIndex = random.nextInt(9);

    switch (widget.challenge.type) {
      case ChallengeType.colorDifference:
        _generateColorChallenge();
        break;
      case ChallengeType.sharpnessCheck:
        _generateSharpnessChallenge();
        break;
      case ChallengeType.contrastTest:
        _generateContrastChallenge();
        break;
      case ChallengeType.focusSpeed:
        _generateFocusChallenge();
        break;
      default:
        _generateColorChallenge();
    }
  }
void _generateColorChallenge() {
  final random = Random();
  
  // Handle different color variants
  Map<String, Color> selectedColors;
  
  switch (widget.challenge.variant) {
    case 'warm':
      // Warm color families
      selectedColors = {
        'base': Color(0xFFFF6B6B + random.nextInt(0x440000)),
        'diff': Color(0xFFFFD93D + random.nextInt(0x440000)),
      };
      break;
      
    case 'cool':
      // Cool color families
      selectedColors = {
        'base': Color(0xFF4ECDC4 + random.nextInt(0x003344)),
        'diff': Color(0xFF6C5CE7 + random.nextInt(0x330044)),
      };
      break;
      
    case 'contrast':
      // High contrast complementary colors
      final colorPairs = [
        {'base': const Color(0xFF2196F3), 'diff': const Color(0xFFFF5722)},
        {'base': const Color(0xFF4CAF50), 'diff': const Color(0xFFE91E63)},
        {'base': const Color(0xFF9C27B0), 'diff': const Color(0xFFCDDC39)},
      ];
      selectedColors = colorPairs[random.nextInt(colorPairs.length)];
      break;
      
    default:
      // Default random colors
      selectedColors = {
        'base': Color(0xFF2196F3),
        'diff': Color(0xFFFF5722),
      };
  }
  
  final baseColor = selectedColors['base']!;
  final diffColor = selectedColors['diff']!;
  
  final difficulty = min(_currentRound * 0.15, 0.8);
  
  _colors = List.generate(9, (index) {
    if (index == _differentIndex) {
      return Color.lerp(baseColor, diffColor, 1 - difficulty)!;
    } else {
      return Color.fromRGBO(
        (baseColor.red + random.nextInt(20) - 10).clamp(0, 255),
        (baseColor.green + random.nextInt(20) - 10).clamp(0, 255),
        (baseColor.blue + random.nextInt(20) - 10).clamp(0, 255),
        1.0,
      );
    }
  });
}

void _generateSharpnessChallenge() {
  _blurLevels = List.generate(9, (index) {
    if (index == _differentIndex) {
      return 0.0;
    } else {
      final difficulty = min(_currentRound * 0.2, 0.9);
      return 5.0 + (difficulty * 15.0);
    }
  });
}

  void _generateContrastChallenge() {
    // Generate visible contrast differences
    final difficulty = min(_currentRound * 0.15, 0.8);

    _contrastLevels = List.generate(9, (index) {
      if (index == _differentIndex) {
        return 1.0; // Full contrast
      } else {
        return 0.3 + (difficulty * 0.5); // Low to medium contrast
      }
    });
  }

  void _generateFocusChallenge() {
    // Similar to color but with size variations for focus
    _generateColorChallenge();
  }

  void _onSquareTap(int index) {
    if (!_isPlaying || _isComplete) return;

    // Calculate response time
    final responseTime = DateTime.now()
        .difference(_roundStartTime!)
        .inMilliseconds;
    _responseTimes.add(responseTime);

    if (index == _differentIndex) {
      // Correct answer
      setState(() {
        _correctAnswers++;
        _streak++;
        _maxStreak = max(_maxStreak, _streak);
        _currentRound++;

        if (_currentRound > _maxRounds) {
          _endChallenge();
        } else {
          _generateNewRound();
        }
      });
    } else {
      // Wrong answer
      setState(() {
        _wrongAnswers++;
        _streak = 0;
      });
    }
  }

  void _endChallenge() {
    _timer.cancel();
    setState(() {
      _isPlaying = false;
      _isComplete = true;
    });

    // Calculate precise score
    final score = _calculatePreciseScore();

    // Save results
    ChallengeService.completeChallenge(widget.challenge, score);

    // Show results
    if (!mounted) return;
    _showResultsDialog(score);
  }

  int _calculatePreciseScore() {
    // Base accuracy score (0-40 points)
    final accuracyScore = (_correctAnswers / _maxRounds * 40).round();

    // Speed bonus (0-30 points)
    final avgResponseTime = _responseTimes.isEmpty
        ? 3000
        : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;
    final speedScore = ((3000 - avgResponseTime.clamp(0, 3000)) / 3000 * 30)
        .round();

    // Streak bonus (0-20 points)
    final streakScore = (_maxStreak / _maxRounds * 20).round();

    // Perfect round bonus (10 points)
    final perfectBonus = _wrongAnswers == 0 ? 10 : 0;

    return (accuracyScore + speedScore + streakScore + perfectBonus).clamp(
      0,
      100,
    );
  }

  void _showResultsDialog(int score) {
    // Determine grade
    String grade;
    String emoji;
    Color gradeColor;

    if (score >= 90) {
      grade = 'EXCELLENT';
      emoji = '🌟';
      gradeColor = const Color(0xFF00E676);
    } else if (score >= 75) {
      grade = 'GREAT';
      emoji = '✨';
      gradeColor = const Color(0xFF00E5FF);
    } else if (score >= 60) {
      grade = 'GOOD';
      emoji = '👍';
      gradeColor = const Color(0xFFFFD740);
    } else {
      grade = 'KEEP TRYING';
      emoji = '💪';
      gradeColor = const Color(0xFFFF9100);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF121212),
                gradeColor.withOpacity(0.15),
                Colors.black,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gradeColor, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text(
                'Challenge Complete!',
                style: TextStyle(
                  color: gradeColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Score circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: gradeColor, width: 4),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          color: gradeColor,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        grade,
                        style: TextStyle(
                          color: gradeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Statistics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Accuracy',
                      '$_correctAnswers/$_maxRounds',
                      gradeColor,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow('Best Streak', '$_maxStreak', gradeColor),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      'Avg Speed',
                      '${(_responseTimes.isEmpty ? 0 : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length / 1000).toStringAsFixed(1)}s',
                      gradeColor,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      'XP Earned',
                      '+${widget.challenge.xpReward}',
                      gradeColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gradeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF049281),
              const Color(0x33000000),
              const Color(0xFF121212),
              Colors.black,
            ],
            stops: const [0, 0.4, 0.7, 1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.challenge.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildChallengeContent(),
                    ],
                  ),
                ),
              ),
              _buildScoreBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.challenge.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Round $_currentRound / $_maxRounds',
                style: const TextStyle(color: Color(0xFF049281), fontSize: 14),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${_secondsRemaining}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreItem(
            '✓',
            _correctAnswers.toString(),
            const Color(0xFF00E676),
          ),
          _buildScoreItem(
            '✗',
            _wrongAnswers.toString(),
            const Color(0xFFFF1744),
          ),
          _buildScoreItem('🔥', _streak.toString(), const Color(0xFFFFD740)),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String icon, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeContent() {
    switch (widget.challenge.type) {
      case ChallengeType.colorDifference:
        return _buildColorGrid();
      case ChallengeType.sharpnessCheck:
        return _buildSharpnessGrid();
      case ChallengeType.contrastTest:
        return _buildContrastGrid();
      default:
        return _buildColorGrid();
    }
  }

  Widget _buildColorGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _onSquareTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _colors[index],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _colors[index].withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSharpnessGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final isSharp = _blurLevels[index] == 0.0;

          return GestureDetector(
            onTap: () => _onSquareTap(index),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSharp
                      ? const Color(0xFF00E5FF)
                      : Colors.white.withOpacity(0.2),
                  width: isSharp ? 3 : 2,
                ),
                boxShadow: isSharp
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: _blurLevels[index],
                    sigmaY: _blurLevels[index],
                  ),
                  child: Text(
                    'E',
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.w900,
                      color: isSharp
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContrastGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final contrast = _contrastLevels[index];

          return GestureDetector(
            onTap: () => _onSquareTap(index),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(Colors.grey[800]!, Colors.white, contrast)!,
                    Color.lerp(
                      Colors.grey[900]!,
                      Colors.white,
                      contrast * 0.8,
                    )!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
