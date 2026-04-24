import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/score_models.dart';
import '../../providers/score_provider.dart';
import '../../widgets/gradient_background.dart';
import '../main_shell.dart';

class MatchResultScreen extends ConsumerWidget {
  const MatchResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(scoreProvider).live;
    if (live == null) return const SizedBox.shrink();

    final first = live.firstInnings!;
    final secondRuns = live.runs;
    final secondWickets = live.wickets;
    final secondOvers = live.oversStr;

    String? winner;
    if (secondRuns >= live.target) {
      winner = live.teamB;
    } else if (secondRuns == first.totalRuns) {
      winner = null;
    } else {
      winner = live.teamA;
    }

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Winner badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.winnerGradient,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.winnerGreen, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.winnerGreen.withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: AppColors.secondary, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        winner == null ? 'MATCH TIED!' : '$winner WINS!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Scorecard
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _inningsRow(
                        team: live.teamA,
                        runs: first.totalRuns,
                        wickets: first.wickets,
                        overStr: first.overStr,
                        isFirst: true,
                      ),
                      const Divider(color: AppColors.cardBorder, height: 1),
                      _inningsRow(
                        team: live.teamB,
                        runs: secondRuns,
                        wickets: secondWickets,
                        overStr: secondOvers,
                        isFirst: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Stats
                Row(
                  children: [
                    Expanded(
                        child: _StatsCard(
                            title: 'Top Batsman',
                            innings: first,
                            isBat: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _StatsCard(
                            title: 'Top Bowler',
                            innings: first,
                            isBat: false)),
                  ],
                ),

                const Spacer(),

                // Save button
                _GoldBtn(
                  label: 'Save & Finish',
                  icon: Icons.save,
                  onTap: () {
                    ref.read(scoreProvider.notifier).saveMatch();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    ref.read(scoreProvider.notifier).discardMatch();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (route) => false,
                    );
                  },
                  child: const Text('Discard',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inningsRow({
    required String team,
    required int runs,
    required int wickets,
    required String overStr,
    required bool isFirst,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isFirst ? '1st' : '2nd',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(team,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
            ),
            Text(
              '$runs/$wickets',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Text('($overStr)',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
}

class _StatsCard extends StatelessWidget {
  final String title;
  final InningsData innings;
  final bool isBat;

  const _StatsCard(
      {required this.title, required this.innings, required this.isBat});

  @override
  Widget build(BuildContext context) {
    final top = isBat ? innings.topBatsman : innings.topBowler;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 6),
          if (top == null)
            const Text('—',
                style: TextStyle(color: AppColors.textSecondary))
          else ...[
            Text(
              isBat
                  ? (top as BatsmanStats).name
                  : (top as BowlerStats).name,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              isBat
                  ? '${(top as BatsmanStats).runs}(${(top as BatsmanStats).balls})'
                  : '${(top as BowlerStats).wickets}-${(top as BowlerStats).runs}',
              style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoldBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GoldBtn(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
