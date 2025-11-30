import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'vision_challenge.dart';

class ChallengeService {
  static const String _streakKey = 'vision_streak';
  static const String _lastCompletionKey = 'last_completion_date';
  static const String _totalXPKey = 'total_xp';
  static const String _completedChallengesKey = 'completed_challenges';
  static const String _unlockedBadgesKey = 'unlocked_badges';

  // EXPANDED: 10 different challenge types for maximum variety
  static final List<VisionChallenge> allChallenges = [
    // Color Challenges (3 variations)
    VisionChallenge(
      id: 'color_diff_warm',
      title: 'Warm Color Detective',
      description: 'Spot the different warm-colored square',
      emoji: '🔥',
      type: ChallengeType.colorDifference,
      xpReward: 50,
      duration: Duration(seconds: 30),
      variant: 'warm', // Red, Orange, Yellow family
    ),
    VisionChallenge(
      id: 'color_diff_cool',
      title: 'Cool Color Detective',
      description: 'Find the different cool-colored square',
      emoji: '❄️',
      type: ChallengeType.colorDifference,
      xpReward: 50,
      duration: Duration(seconds: 30),
      variant: 'cool', // Blue, Green, Purple family
    ),
    VisionChallenge(
      id: 'color_diff_contrast',
      title: 'Color Contrast Master',
      description: 'Spot the contrasting color',
      emoji: '🎨',
      type: ChallengeType.colorDifference,
      xpReward: 60,
      duration: Duration(seconds: 25),
      variant: 'contrast', // Complementary colors
    ),

    // Sharpness Challenges (2 variations)
    VisionChallenge(
      id: 'sharpness_letters',
      title: 'Letter Clarity',
      description: 'Find the sharpest letter',
      emoji: '🔍',
      type: ChallengeType.sharpnessCheck,
      xpReward: 60,
      duration: Duration(seconds: 20),
      variant: 'letters',
    ),
    VisionChallenge(
      id: 'sharpness_shapes',
      title: 'Shape Sharpness',
      description: 'Identify the clearest shape',
      emoji: '🔷',
      type: ChallengeType.sharpnessCheck,
      xpReward: 60,
      duration: Duration(seconds: 20),
      variant: 'shapes',
    ),

    // Contrast Challenges (2 variations)
    VisionChallenge(
      id: 'contrast_grayscale',
      title: 'Grayscale Contrast',
      description: 'Find the highest contrast gray',
      emoji: '🌓',
      type: ChallengeType.contrastTest,
      xpReward: 70,
      duration: Duration(seconds: 25),
      variant: 'grayscale',
    ),
    VisionChallenge(
      id: 'contrast_color',
      title: 'Color Contrast',
      description: 'Spot the most vibrant color',
      emoji: '🌈',
      type: ChallengeType.contrastTest,
      xpReward: 75,
      duration: Duration(seconds: 25),
      variant: 'color',
    ),

    // Speed Challenges (2 variations)
    VisionChallenge(
      id: 'speed_fast',
      title: 'Lightning Speed',
      description: 'Quick! Tap the different one',
      emoji: '⚡',
      type: ChallengeType.focusSpeed,
      xpReward: 80,
      duration: Duration(seconds: 15),
      variant: 'fast',
    ),
    VisionChallenge(
      id: 'speed_pattern',
      title: 'Pattern Recognition',
      description: 'Find the pattern breaker fast',
      emoji: '🎯',
      type: ChallengeType.focusSpeed,
      xpReward: 85,
      duration: Duration(seconds: 18),
      variant: 'pattern',
    ),

    // Peripheral Vision Challenge
    VisionChallenge(
      id: 'peripheral',
      title: 'Peripheral Vision',
      description: 'Spot the edge anomaly',
      emoji: '👁️',
      type: ChallengeType.peripheralVision,
      xpReward: 90,
      duration: Duration(seconds: 30),
      variant: 'edges',
    ),
  ];

  static final List<Achievement> allAchievements = [
    Achievement(
      id: 'first_challenge',
      title: 'First Steps',
      description: 'Complete your first challenge',
      emoji: '🌱',
      requiredCount: 1,
      type: AchievementType.totalChallenges,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Getting Consistent',
      description: 'Maintain a 3-day streak',
      emoji: '🔥',
      requiredCount: 3,
      type: AchievementType.streak,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Complete challenges for 7 days straight',
      emoji: '⭐',
      requiredCount: 7,
      type: AchievementType.streak,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Vision Champion',
      description: 'Unstoppable 30-day streak!',
      emoji: '🏆',
      requiredCount: 30,
      type: AchievementType.streak,
    ),
    Achievement(
      id: 'challenges_10',
      title: 'Dedicated Trainee',
      description: 'Complete 10 challenges',
      emoji: '💪',
      requiredCount: 10,
      type: AchievementType.totalChallenges,
    ),
    Achievement(
      id: 'challenges_50',
      title: 'Vision Expert',
      description: 'Complete 50 challenges',
      emoji: '🎯',
      requiredCount: 50,
      type: AchievementType.totalChallenges,
    ),
    Achievement(
      id: 'perfect_score',
      title: 'Perfectionist',
      description: 'Get a perfect score on any challenge',
      emoji: '💎',
      requiredCount: 1,
      type: AchievementType.perfectScore,
    ),
    Achievement(
      id: 'color_master',
      title: 'Color Master',
      description: 'Complete 10 color challenges',
      emoji: '🌈',
      requiredCount: 10,
      type: AchievementType.specific,
    ),
    Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Complete 10 speed challenges',
      emoji: '⚡',
      requiredCount: 10,
      type: AchievementType.specific,
    ),
  ];

  // Get daily challenge - NOW WITH MORE VARIETY
  static VisionChallenge getDailyChallenge() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(2024)).inDays;

    // Use day AND month for more randomization
    final seed = dayOfYear + (now.month * 31);
    final index = seed % allChallenges.length;

    return allChallenges[index];
  }

  // Get 3 random bonus challenges (for users who want to play more)
  static List<VisionChallenge> getBonusChallenges() {
    final random = Random(DateTime.now().day);
    final shuffled = List<VisionChallenge>.from(allChallenges)..shuffle(random);
    return shuffled.take(3).toList();
  }

  // Get current streak
  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(_streakKey) ?? 0;
    final lastCompletion = prefs.getString(_lastCompletionKey);

    if (lastCompletion == null) return 0;

    final lastDate = DateTime.parse(lastCompletion);
    final today = DateTime.now();
    final difference = today.difference(lastDate).inDays;

    if (difference > 1) {
      await prefs.setInt(_streakKey, 0);
      return 0;
    }

    return streak;
  }

  // Check if today's challenge is completed
  static Future<bool> isTodayCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCompletion = prefs.getString(_lastCompletionKey);

    if (lastCompletion == null) return false;

    final lastDate = DateTime.parse(lastCompletion);
    final today = DateTime.now();

    return lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day;
  }

  // Complete a challenge
  static Future<void> completeChallenge(
    VisionChallenge challenge,
    int score,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final currentStreak = await getCurrentStreak();
    final todayCompleted = await isTodayCompleted();

    if (!todayCompleted) {
      await prefs.setInt(_streakKey, currentStreak + 1);
      await prefs.setString(
        _lastCompletionKey,
        DateTime.now().toIso8601String(),
      );
    }

    final currentXP = prefs.getInt(_totalXPKey) ?? 0;
    await prefs.setInt(_totalXPKey, currentXP + challenge.xpReward);

    final result = ChallengeResult(
      challengeId: challenge.id,
      completedAt: DateTime.now(),
      score: score,
      xpEarned: challenge.xpReward,
    );

    final completedList = prefs.getStringList(_completedChallengesKey) ?? [];
    completedList.add(jsonEncode(result.toJson()));
    await prefs.setStringList(_completedChallengesKey, completedList);

    await _checkAchievements();
  }

  static Future<int> getTotalXP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalXPKey) ?? 0;
  }

  static Future<int> getUserLevel() async {
    final xp = await getTotalXP();
    return (xp / 500).floor() + 1;
  }

  static Future<double> getXPProgress() async {
    final xp = await getTotalXP();
    final currentLevelXP = xp % 500;
    return currentLevelXP / 500;
  }

  static Future<List<ChallengeResult>> getCompletedChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final completedList = prefs.getStringList(_completedChallengesKey) ?? [];

    return completedList
        .map((json) => ChallengeResult.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<List<String>> getUnlockedBadges() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_unlockedBadgesKey) ?? [];
  }

  static Future<List<Achievement>> _checkAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedBadges = await getUnlockedBadges();
    final newlyUnlocked = <Achievement>[];

    final streak = await getCurrentStreak();
    final completed = await getCompletedChallenges();
    final totalChallenges = completed.length;

    for (final achievement in allAchievements) {
      if (unlockedBadges.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.type) {
        case AchievementType.streak:
          shouldUnlock = streak >= achievement.requiredCount;
          break;
        case AchievementType.totalChallenges:
          shouldUnlock = totalChallenges >= achievement.requiredCount;
          break;
        case AchievementType.perfectScore:
          shouldUnlock = completed.any((c) => c.score >= 95);
          break;
        case AchievementType.specific:
          if (achievement.id == 'color_master') {
            final colorChallenges = completed
                .where((c) => c.challengeId.contains('color'))
                .length;
            shouldUnlock = colorChallenges >= achievement.requiredCount;
          } else if (achievement.id == 'speed_demon') {
            final speedChallenges = completed
                .where((c) => c.challengeId.contains('speed'))
                .length;
            shouldUnlock = speedChallenges >= achievement.requiredCount;
          }
          break;
      }

      if (shouldUnlock) {
        unlockedBadges.add(achievement.id);
        newlyUnlocked.add(achievement);
      }
    }

    await prefs.setStringList(_unlockedBadgesKey, unlockedBadges);
    return newlyUnlocked;
  }

  static Future<Map<DateTime, bool>> getCalendarData() async {
    final completed = await getCompletedChallenges();
    final calendar = <DateTime, bool>{};

    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);

      calendar[dateKey] = completed.any((c) {
        final completedDate = c.completedAt;
        return completedDate.year == dateKey.year &&
            completedDate.month == dateKey.month &&
            completedDate.day == dateKey.day;
      });
    }

    return calendar;
  }
}
