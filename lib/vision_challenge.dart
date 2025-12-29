class VisionChallenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final ChallengeType type;
  final int xpReward;
  final Duration duration;
  final String? variant; // For challenge variations

  VisionChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.xpReward,
    required this.duration,
    this.variant,
  });
}

enum ChallengeType {
  colorDifference,
  focusSpeed,
  sharpnessCheck,
  contrastTest,
  peripheralVision,
  trackingExercise,
}

class ChallengeResult {
  final String challengeId;
  final DateTime completedAt;
  final int score;
  final int xpEarned;

  ChallengeResult({
    required this.challengeId,
    required this.completedAt,
    required this.score,
    required this.xpEarned,
  });

  Map<String, dynamic> toJson() => {
    'challengeId': challengeId,
    'completedAt': completedAt.toIso8601String(),
    'score': score,
    'xpEarned': xpEarned,
  };

  factory ChallengeResult.fromJson(Map<String, dynamic> json) =>
      ChallengeResult(
        challengeId: json['challengeId'],
        completedAt: DateTime.parse(json['completedAt']),
        score: json['score'],
        xpEarned: json['xpEarned'],
      );
}

// ADD THIS ACHIEVEMENT CLASS
class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int requiredCount;
  final AchievementType type;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.requiredCount,
    required this.type,
  });
}

// ADD THIS ACHIEVEMENT TYPE ENUM
enum AchievementType { streak, totalChallenges, perfectScore, specific }
