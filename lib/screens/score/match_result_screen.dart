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
    final secondBatsmen = live.batsmanStats.values.toList();
    final secondBowlers = live.bowlerStats.values.toList();

    String? winner;
    if (secondRuns >= live.target) {
      winner = live.teamB;
    } else if (secondRuns == first.totalRuns) {
      winner = null;
    } else {
      winner = live.teamA;
    }

    final secondInnings = InningsData(
      battingTeam: live.teamB,
      totalRuns: secondRuns,
      wickets: secondWickets,
      legalBalls: live.legalBalls,
      totalOvers: live.totalOvers,
      batsmen: secondBatsmen,
      bowlers: secondBowlers,
    );

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Winner badge
                      _WinnerBadge(winner: winner),
                      const SizedBox(height: 16),

                      // Quick scorecard
                      _QuickScorecard(
                        teamA: live.teamA,
                        teamB: live.teamB,
                        first: first,
                        secondRuns: secondRuns,
                        secondWickets: secondWickets,
                        secondOvers: secondOvers,
                      ),
                      const SizedBox(height: 16),

                      // Full innings details
                      _InningsDetail(innings: first, label: '1st Innings'),
                      const SizedBox(height: 12),
                      _InningsDetail(innings: secondInnings, label: '2nd Innings'),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: const BoxDecoration(
                  color: AppColors.bgDeep,
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Column(
                  children: [
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
                    const SizedBox(height: 8),
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Winner Badge ─────────────────────────────────────────────────────────────

class _WinnerBadge extends StatelessWidget {
  final String? winner;
  const _WinnerBadge({required this.winner});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.winnerGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.winnerGreen, width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.winnerGreen.withOpacity(0.3), blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: AppColors.secondary, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              winner == null ? 'MATCH TIED!' : '$winner\nWINS!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Scorecard ──────────────────────────────────────────────────────────

class _QuickScorecard extends StatelessWidget {
  final String teamA, teamB;
  final InningsData first;
  final int secondRuns, secondWickets;
  final String secondOvers;

  const _QuickScorecard({
    required this.teamA,
    required this.teamB,
    required this.first,
    required this.secondRuns,
    required this.secondWickets,
    required this.secondOvers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _row(teamA, first.totalRuns, first.wickets, first.overStr, true),
          const Divider(color: AppColors.cardBorder, height: 1),
          _row(teamB, secondRuns, secondWickets, secondOvers, false),
        ],
      ),
    );
  }

  Widget _row(String team, int runs, int wkts, String overs, bool isFirst) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isFirst ? '1st' : '2nd',
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(team,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ),
            Text('$runs/$wkts',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('($overs)',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
}

// ─── Full Innings Detail ──────────────────────────────────────────────────────

class _InningsDetail extends StatefulWidget {
  final InningsData innings;
  final String label;

  const _InningsDetail({required this.innings, required this.label});

  @override
  State<_InningsDetail> createState() => _InningsDetailState();
}

class _InningsDetailState extends State<_InningsDetail> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final innings = widget.innings;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgMid,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: _expanded ? Radius.zero : const Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(widget.label,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Text(innings.battingTeam,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const Spacer(),
                  Text('${innings.totalRuns}/${innings.wickets}  (${innings.overStr})',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: AppColors.textMuted),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            // Batting table
            _tableHeader(['Batsman', 'R', 'B', 'SR']),
            ...innings.batsmen.map((b) => _battingRow(b)),
            _dividerRow(),

            // Bowling table
            _tableHeader(['Bowler', 'O', 'R', 'W']),
            ...innings.bowlers.map((b) => _bowlingRow(b)),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> cols) => Container(
        color: AppColors.bgMid.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
                child: Text(cols[0],
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1))),
            for (final c in cols.skip(1))
              SizedBox(
                width: 36,
                child: Text(c,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
              ),
          ],
        ),
      );

  Widget _battingRow(BatsmanStats b) {
    final sr = b.balls == 0 ? 0.0 : (b.runs / b.balls * 100);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(b.isOut ? 'Out' : 'Not Out',
                    style: TextStyle(
                        color: b.isOut ? Colors.redAccent : AppColors.winnerGreen,
                        fontSize: 10)),
              ],
            ),
          ),
          _cell('${b.runs}', highlight: b.runs >= 50),
          _cell('${b.balls}'),
          _cell(sr.toStringAsFixed(0)),
        ],
      ),
    );
  }

  Widget _bowlingRow(BowlerStats b) {
    final eco = b.balls == 0 ? 0.0 : (b.runs / b.balls * 6);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(b.name,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          _cell(b.overStr),
          _cell('${b.runs}'),
          _cell('${b.wickets}', highlight: b.wickets >= 3),
        ],
      ),
    );
  }

  Widget _cell(String v, {bool highlight = false}) => SizedBox(
        width: 36,
        child: Text(v,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: highlight ? AppColors.secondary : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w500)),
      );

  Widget _dividerRow() => const Divider(color: AppColors.cardBorder, height: 1, thickness: 1);
}

// ─── Gold Button ─────────────────────────────────────────────────────────────

class _GoldBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GoldBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.secondary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
