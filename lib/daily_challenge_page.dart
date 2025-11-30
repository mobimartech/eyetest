import 'package:eyetest/ChallengePlayPage.dart';
import 'package:eyetest/achievements_page.dart';
import 'package:eyetest/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'vision_challenge.dart';
import 'challenge_service.dart';

class DailyChallengeHomePage extends StatefulWidget {
  const DailyChallengeHomePage({Key? key}) : super(key: key);

  @override
  State<DailyChallengeHomePage> createState() => _DailyChallengeHomePageState();
}

class _DailyChallengeHomePageState extends State<DailyChallengeHomePage> {
  int currentStreak = 0;
  int totalXP = 0;
  int userLevel = 1;
  double xpProgress = 0.0;
  bool isTodayCompleted = false;
  List<String> unlockedBadges = [];
  VisionChallenge? dailyChallenge;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final streak = await ChallengeService.getCurrentStreak();
    final xp = await ChallengeService.getTotalXP();
    final level = await ChallengeService.getUserLevel();
    final progress = await ChallengeService.getXPProgress();
    final completed = await ChallengeService.isTodayCompleted();
    final badges = await ChallengeService.getUnlockedBadges();
    final challenge = ChallengeService.getDailyChallenge();

    setState(() {
      currentStreak = streak;
      totalXP = xp;
      userLevel = level;
      xpProgress = progress;
      isTodayCompleted = completed;
      unlockedBadges = badges;
      dailyChallenge = challenge;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF049281),
              Color(0x33000000),
              Color(0xFF121212),
              Colors.black,
            ],
            stops: [0, 0.5, 0.7, 1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Challenge',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMM d').format(DateTime.now()),
                          style: TextStyle(
                            color: Color(0xFF049281),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Streak Card
                _buildStreakCard(),
                SizedBox(height: 20),

                // Level Progress Card
                _buildLevelCard(),
                SizedBox(height: 20),

                // Today's Challenge Card
                if (dailyChallenge != null) _buildChallengeCard(),
                SizedBox(height: 20),

                // Achievements Section
                _buildAchievementsSection(),
                SizedBox(height: 20),

                // Calendar View
                _buildCalendarSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF049281), Color(0xFF037268)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0x60049281),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Streak',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text('🔥', style: TextStyle(fontSize: 32)),
                  SizedBox(width: 12),
                  Text(
                    '$currentStreak',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'days',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isTodayCompleted ? '✓ Completed' : 'Pending',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF049281).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level $userLevel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$totalXP XP',
                    style: TextStyle(
                      color: Color(0xFF049281),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text('⭐', style: TextStyle(fontSize: 40)),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: xpProgress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF049281)),
              minHeight: 12,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${(xpProgress * 500).toInt()} / 500 XP to Level ${userLevel + 1}',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return FutureBuilder<bool>(
      future: NotificationService().isNotificationEnabled(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF049281).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFF049281),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Reminder',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Get notified at 8:00 PM',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: isEnabled,
                    activeColor: const Color(0xFF049281),
                    onChanged: (value) async {
                      await NotificationService().setNotificationEnabled(value);
                      setState(() {});
                    },
                  ),
                ],
              ),
              if (isEnabled) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    await NotificationService().showTestNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent!'),
                        backgroundColor: Color(0xFF049281),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.send_outlined,
                    color: Color(0xFF049281),
                    size: 18,
                  ),
                  label: const Text(
                    'Send Test Notification',
                    style: TextStyle(
                      color: Color(0xFF049281),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildChallengeCard() {
    return GestureDetector(
      onTap: isTodayCompleted
          ? null
          : () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChallengePlayPage(challenge: dailyChallenge!),
                ),
              );
              if (result == true) {
                _loadData();
              }
            },
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isTodayCompleted
                ? [Colors.grey[800]!, Colors.grey[900]!]
                : [Color(0xFF1a1a1a), Color(0xFF0d0d0d)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTodayCompleted ? Colors.grey[700]! : Color(0xFF049281),
            width: 2,
          ),
          boxShadow: [
            if (!isTodayCompleted)
              BoxShadow(
                color: Color(0x40049281),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF049281), Color(0xFF037268)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      dailyChallenge!.emoji,
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dailyChallenge!.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        dailyChallenge!.description,
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: Color(0xFF049281),
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '${dailyChallenge!.duration.inSeconds}s',
                      style: TextStyle(
                        color: Color(0xFF049281),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 20),
                    Icon(
                      Icons.stars_rounded,
                      color: Color(0xFF049281),
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '+${dailyChallenge!.xpReward} XP',
                      style: TextStyle(
                        color: Color(0xFF049281),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: isTodayCompleted
                    ? LinearGradient(
                        colors: [Colors.grey[700]!, Colors.grey[600]!],
                      )
                    : LinearGradient(
                        colors: [Color(0xFF049281), Color(0xFF037268)],
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  isTodayCompleted ? '✓ Completed Today' : 'Start Challenge',
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
    );
  }
Widget _buildAchievementsSection() {
  final achievements = ChallengeService.allAchievements.take(4).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Achievements',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to Achievements Page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AchievementsPage(),
                ),
              );
            },
            child: const Text(
              'View All',
              style: TextStyle(
                color: Color(0xFF049281),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          final isUnlocked = unlockedBadges.contains(achievement.id);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFF049281).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked
                    ? const Color(0xFF049281)
                    : Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  achievement.emoji,
                  style: TextStyle(
                    fontSize: 32,
                    color: isUnlocked ? null : Colors.white.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

  Widget _buildCalendarSection() {
    return FutureBuilder<Map<DateTime, bool>>(
      future: ChallengeService.getCalendarData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox();
        }

        final calendar = snapshot.data!;
        final sortedDates = calendar.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        final last7Days = sortedDates.take(7).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 Days',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: last7Days.map((date) {
                final isCompleted = calendar[date] ?? false;
                final isToday =
                    date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

                return Column(
                  children: [
                    Text(
                      DateFormat('E').format(date).substring(0, 1),
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Color(0xFF049281)
                            : Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          isCompleted ? '✓' : date.day.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
