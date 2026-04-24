import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/score_models.dart';
import '../../providers/score_provider.dart';
import '../../widgets/gradient_background.dart';
import 'match_result_screen.dart';

class ScoringScreen extends ConsumerStatefulWidget {
  const ScoringScreen({super.key});

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  bool _busy = false;

  Future<void> _onBall(BallType type, int runs) async {
    if (_busy) return;
    setState(() => _busy = true);
    ref.read(scoreProvider.notifier).recordBall(type: type, runs: runs);
    await _handleState();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _handleState() async {
    final live = ref.read(scoreProvider).live;
    if (live == null) return;

    if (live.matchComplete) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MatchResultScreen()),
        );
      }
      return;
    }

    if (live.inningsComplete && live.currentInnings == 1) {
      await _inningsBreakDialog();
      return;
    }

    if (live.needsNewBatsman) {
      await _newBatsmanDialog();
    }

    final updatedLive = ref.read(scoreProvider).live;
    if (updatedLive != null && updatedLive.needsNewBowler) {
      await _newBowlerDialog();
    }
  }

  Future<void> _newBatsmanDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PlayerDialog(
        title: 'New Batsman',
        hint: 'Enter batsman name',
        controller: ctrl,
        onConfirm: () {
          final name = ctrl.text.trim();
          if (name.isEmpty) return false;
          ref.read(scoreProvider.notifier).newBatsman(name);
          return true;
        },
      ),
    );
    ctrl.dispose();
  }

  Future<void> _newBowlerDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PlayerDialog(
        title: 'New Bowler',
        hint: 'Enter bowler name',
        controller: ctrl,
        onConfirm: () {
          final name = ctrl.text.trim();
          if (name.isEmpty) return false;
          ref.read(scoreProvider.notifier).newBowler(name);
          return true;
        },
      ),
    );
    ctrl.dispose();
  }

  Future<void> _inningsBreakDialog() async {
    final live = ref.read(scoreProvider).live!;
    final s1 = TextEditingController();
    final s2 = TextEditingController();
    final b = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InningsBreakDialog(
        firstInningsTeam: live.teamA,
        firstInningsRuns: live.runs,
        firstInningsWickets: live.wickets,
        firstInningsOvers: live.oversStr,
        target: live.runs + 1,
        secondTeam: live.teamB,
        s1: s1,
        s2: s2,
        b: b,
        onStart: () {
          final striker = s1.text.trim();
          final nonStriker = s2.text.trim();
          final bowler = b.text.trim();
          if (striker.isEmpty || nonStriker.isEmpty || bowler.isEmpty) {
            return false;
          }
          ref.read(scoreProvider.notifier).startSecondInnings(
                striker: striker,
                nonStriker: nonStriker,
                bowler: bowler,
              );
          return true;
        },
      ),
    );
    s1.dispose();
    s2.dispose();
    b.dispose();
  }

  void _confirmDiscard() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgMid,
        title: const Text('Discard Match?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('All scoring data will be lost.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(scoreProvider.notifier).discardMatch();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Discard',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(scoreProvider).live;
    if (live == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text('${live.battingTeam}  vs  ${live.bowlingTeam}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmDiscard,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'Inn ${live.currentInnings}/2',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ScoreBoard(live: live),
                    const SizedBox(height: 12),
                    _BatsmenCard(live: live),
                    const SizedBox(height: 10),
                    _BowlerCard(live: live),
                    const SizedBox(height: 10),
                    _OverDisplay(balls: live.overDisplay),
                  ],
                ),
              ),
            ),
            _BallButtons(onTap: _onBall, busy: _busy),
          ],
        ),
      ),
    );
  }
}

// ─── Scoreboard ─────────────────────────────────────────────────────────────

class _ScoreBoard extends StatelessWidget {
  final LiveMatchState live;
  const _ScoreBoard({required this.live});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.4), blurRadius: 16)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${live.runs}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w900),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/${live.wickets}',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 28,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Text(
            'Overs  ${live.oversStr} / ${live.totalOvers}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (live.currentInnings == 2) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Target ${live.target}  •  Need ${(live.target - live.runs).clamp(0, 9999)} off ${((live.totalOvers * 6) - live.legalBalls).clamp(0, 9999)} balls',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Batsmen ─────────────────────────────────────────────────────────────────

class _BatsmenCard extends StatelessWidget {
  final LiveMatchState live;
  const _BatsmenCard({required this.live});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _batsmanRow(live.striker, live.batsmanStats[live.striker], true),
          const Divider(color: AppColors.cardBorder, height: 12),
          _batsmanRow(live.nonStriker, live.batsmanStats[live.nonStriker], false),
        ],
      ),
    );
  }

  Widget _batsmanRow(String name, BatsmanStats? stats, bool isStriker) {
    return Row(
      children: [
        Text(
          isStriker ? '* ' : '  ',
          style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 16,
              fontWeight: FontWeight.w900),
        ),
        Expanded(
          child: Text(
            name.isEmpty ? '—' : name,
            style: TextStyle(
              color: isStriker ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: isStriker ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        if (stats != null)
          Text(
            '${stats.runs} (${stats.balls})',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}

// ─── Bowler ───────────────────────────────────────────────────────────────────

class _BowlerCard extends StatelessWidget {
  final LiveMatchState live;
  const _BowlerCard({required this.live});

  @override
  Widget build(BuildContext context) {
    final bowl = live.bowlerStats[live.currentBowler];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_cricket,
              size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              live.currentBowler,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
          ),
          if (bowl != null)
            Text(
              '${bowl.wickets}-${bowl.runs}  (${bowl.overStr})',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

// ─── Over display ─────────────────────────────────────────────────────────────

class _OverDisplay extends StatelessWidget {
  final List<String> balls;
  const _OverDisplay({required this.balls});

  @override
  Widget build(BuildContext context) {
    if (balls.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('This over: ',
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Wrap(
            spacing: 6,
            children: balls.map((b) {
              Color c = AppColors.textSecondary;
              if (b == 'W') c = Colors.redAccent;
              if (b == '4' || b == '6') c = AppColors.secondary;
              if (b.startsWith('Wd') || b.startsWith('NB')) {
                c = AppColors.byePurple;
              }
              return Text(b,
                  style: TextStyle(
                      color: c,
                      fontSize: 13,
                      fontWeight: FontWeight.w700));
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Ball Buttons ─────────────────────────────────────────────────────────────

class _BallButtons extends StatelessWidget {
  final Future<void> Function(BallType, int) onTap;
  final bool busy;

  const _BallButtons({required this.onTap, required this.busy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      decoration: const BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        children: [
          // Runs row
          Row(
            children: [0, 1, 2, 3, 4, 6].map((r) {
              return Expanded(
                child: _BallBtn(
                  label: r == 0 ? '•' : '$r',
                  color: r == 4 || r == 6
                      ? AppColors.secondary
                      : AppColors.cardBg,
                  textColor:
                      r == 4 || r == 6 ? Colors.black87 : AppColors.textPrimary,
                  onTap: busy ? null : () => onTap(BallType.normal, r),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Extras & wicket row
          Row(
            children: [
              Expanded(
                child: _BallBtn(
                  label: 'Wide',
                  color: AppColors.byePurple.withOpacity(0.25),
                  textColor: AppColors.byePurple,
                  onTap: busy ? null : () => onTap(BallType.wide, 0),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _BallBtn(
                  label: 'No Ball',
                  color: AppColors.byePurple.withOpacity(0.25),
                  textColor: AppColors.byePurple,
                  onTap: busy ? null : () => onTap(BallType.noBall, 0),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: _BallBtn(
                  label: 'WICKET',
                  color: Colors.redAccent.withOpacity(0.2),
                  textColor: Colors.redAccent,
                  onTap: busy ? null : () => onTap(BallType.wicket, 0),
                  large: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BallBtn extends StatelessWidget {
  final String label;
  final Color color, textColor;
  final VoidCallback? onTap;
  final bool large;

  const _BallBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(vertical: large ? 14 : 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: textColor.withOpacity(0.4), width: large ? 1.5 : 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: onTap == null ? textColor.withOpacity(0.4) : textColor,
              fontSize: large ? 14 : 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dialogs ──────────────────────────────────────────────────────────────────

class _PlayerDialog extends StatefulWidget {
  final String title, hint;
  final TextEditingController controller;
  final bool Function() onConfirm;

  const _PlayerDialog({
    required this.title,
    required this.hint,
    required this.controller,
    required this.onConfirm,
  });

  @override
  State<_PlayerDialog> createState() => _PlayerDialogState();
}

class _PlayerDialogState extends State<_PlayerDialog> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgMid,
      title: Text(widget.title,
          style: const TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.controller,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: _error,
            ),
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _confirm,
          child: const Text('OK',
              style: TextStyle(color: AppColors.secondary)),
        ),
      ],
    );
  }

  void _confirm() {
    final ok = widget.onConfirm();
    if (!ok) {
      setState(() => _error = 'Name cannot be empty');
      return;
    }
    Navigator.pop(context);
  }
}

class _InningsBreakDialog extends StatefulWidget {
  final String firstInningsTeam, secondTeam;
  final int firstInningsRuns, firstInningsWickets, target;
  final String firstInningsOvers;
  final TextEditingController s1, s2, b;
  final bool Function() onStart;

  const _InningsBreakDialog({
    required this.firstInningsTeam,
    required this.firstInningsRuns,
    required this.firstInningsWickets,
    required this.firstInningsOvers,
    required this.target,
    required this.secondTeam,
    required this.s1,
    required this.s2,
    required this.b,
    required this.onStart,
  });

  @override
  State<_InningsBreakDialog> createState() => _InningsBreakDialogState();
}

class _InningsBreakDialogState extends State<_InningsBreakDialog> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgMid,
      title: const Text('Innings Break',
          style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '${widget.firstInningsTeam}   ${widget.firstInningsRuns}/${widget.firstInningsWickets}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                  Text(
                    '(${widget.firstInningsOvers} ov)',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.secondTeam} needs ${widget.target} to win',
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.secondTeam} Opening Batsmen'.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _tf(widget.s1, 'Striker'),
            const SizedBox(height: 8),
            _tf(widget.s2, 'Non-Striker'),
            const SizedBox(height: 12),
            const Text(
              'OPENING BOWLER',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _tf(widget.b, 'Bowler'),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _start,
          child: const Text('Start 2nd Innings',
              style: TextStyle(color: AppColors.secondary)),
        ),
      ],
    );
  }

  Widget _tf(TextEditingController ctrl, String label) => TextField(
        controller: ctrl,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(hintText: label),
      );

  void _start() {
    final ok = widget.onStart();
    if (!ok) {
      setState(() => _error = 'All fields are required');
      return;
    }
    Navigator.pop(context);
  }
}
