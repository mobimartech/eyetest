import 'package:flutter/material.dart';
import 'challenge_service.dart';
import 'vision_challenge.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({Key? key}) : super(key: key);

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage>
    with SingleTickerProviderStateMixin {
  List<String> unlockedBadges = [];
  int totalXP = 0;
  int userLevel = 0;
  int currentStreak = 0;
  List<ChallengeResult> completedChallenges = [];

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _loadData();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final badges = await ChallengeService.getUnlockedBadges();
    final xp = await ChallengeService.getTotalXP();
    final level = await ChallengeService.getUserLevel();
    final streak = await ChallengeService.getCurrentStreak();
    final challenges = await ChallengeService.getCompletedChallenges();

    setState(() {
      unlockedBadges = badges;
      totalXP = xp;
      userLevel = level;
      currentStreak = streak;
      completedChallenges = challenges;
    });
  }

  int _getAchievementProgress(Achievement achievement) {
    switch (achievement.type) {
      case AchievementType.streak:
        return currentStreak;
      case AchievementType.totalChallenges:
        return completedChallenges.length;
      case AchievementType.perfectScore:
        return completedChallenges.where((c) => c.score >= 95).length;
      case AchievementType.specific:
        if (achievement.id == 'color_master') {
          return completedChallenges
              .where((c) => c.challengeId.contains('color'))
              .length;
        } else if (achievement.id == 'speed_demon') {
          return completedChallenges
              .where((c) => c.challengeId.contains('speed'))
              .length;
        }
        return 0;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAchievements = ChallengeService.allAchievements.length;
    final unlockedCount = unlockedBadges.length;
    final progressPercent = (unlockedCount / totalAchievements * 100).round();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF049281),
              Color(0x33000000),
              Color(0xFF121212),
              Colors.black,
            ],
            stops: [0, 0.4, 0.7, 1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressCard(
                unlockedCount,
                totalAchievements,
                progressPercent,
              ),
              Expanded(child: _buildAchievementsList()),
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
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Achievements',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF049281), Color(0xFF037268)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF049281).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Level $userLevel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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

  Widget _buildProgressCard(int unlocked, int total, int percent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF049281), Color(0xFF037268)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF049281).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Progress',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Keep collecting!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: unlocked / total,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$unlocked / $total Achievements Unlocked',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildCategorySection(
          'Streak Master',
          '🔥',
          ChallengeService.allAchievements
              .where((a) => a.type == AchievementType.streak)
              .toList(),
        ),
        const SizedBox(height: 24),
        _buildCategorySection(
          'Challenge Collector',
          '🎯',
          ChallengeService.allAchievements
              .where((a) => a.type == AchievementType.totalChallenges)
              .toList(),
        ),
        const SizedBox(height: 24),
        _buildCategorySection(
          'Perfect Vision',
          '💎',
          ChallengeService.allAchievements
              .where((a) => a.type == AchievementType.perfectScore)
              .toList(),
        ),
        const SizedBox(height: 24),
        _buildCategorySection(
          'Special Achievements',
          '✨',
          ChallengeService.allAchievements
              .where((a) => a.type == AchievementType.specific)
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    String title,
    String emoji,
    List<Achievement> achievements,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...achievements.map(
          (achievement) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAchievementCard(achievement),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = unlockedBadges.contains(achievement.id);
    final progress = _getAchievementProgress(achievement);
    final progressPercent = (progress / achievement.requiredCount).clamp(
      0.0,
      1.0,
    );

    return GestureDetector(
      onTap: () => _showAchievementDetails(achievement, isUnlocked, progress),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF049281)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.7, 1.0],
                )
              : const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF1A1A1A)],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? const Color(0xFF049281)
                : Colors.white.withOpacity(0.1),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFF049281).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Shimmer effect for unlocked achievements
            if (isUnlocked)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment(
                            -1.0 + _shimmerController.value * 3,
                            -1.0,
                          ),
                          end: Alignment(
                            1.0 + _shimmerController.value * 3,
                            1.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Row(
              children: [
                // Achievement Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? const Color(0xFF049281).withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnlocked
                          ? const Color(0xFF049281)
                          : Colors.white.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      achievement.emoji,
                      style: TextStyle(
                        fontSize: 32,
                        color: isUnlocked
                            ? null
                            : Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Achievement Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              achievement.title,
                              style: TextStyle(
                                color: isUnlocked
                                    ? Colors.white
                                    : Colors.white54,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '✓',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          color: isUnlocked
                              ? const Color(0xFF049281)
                              : Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                      if (!isUnlocked) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF049281),
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$progress / ${achievement.requiredCount}',
                          style: const TextStyle(
                            color: Color(0xFF049281),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetails(
    Achievement achievement,
    bool isUnlocked,
    int progress,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF121212),
                isUnlocked
                    ? const Color(0xFF049281).withOpacity(0.2)
                    : const Color(0xFF121212),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnlocked
                  ? const Color(0xFF049281)
                  : Colors.white.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(achievement.emoji, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              Text(
                achievement.title,
                style: TextStyle(
                  color: isUnlocked ? const Color(0xFF049281) : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                achievement.description,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!isUnlocked) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$progress / ${achievement.requiredCount}',
                        style: const TextStyle(
                          color: Color(0xFF049281),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✓ UNLOCKED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF049281),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
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
}
