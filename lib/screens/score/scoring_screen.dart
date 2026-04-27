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
  bool _showPastOvers = false;

  Future<void> _onBall(BallType type, int runs) async {
    if (_busy) return;
    setState(() => _busy = true);
    ref.read(scoreProvider.notifier).recordBall(type: type, runs: runs);
    await _checkState();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _onSpecialBall(BallType type) async {
    if (_busy) return;
    final label = type == BallType.wide
        ? 'Wide'
        : type == BallType.noBall
            ? 'No Ball'
            : 'Bye';
    final runs = await _pickExtraRuns(label);
    if (runs == null) return;
    await _onBall(type, runs);
  }

  Future<void> _onCustomRuns() async {
    if (_busy) return;
    final runs = await _pickCustomRuns();
    if (runs == null) return;
    await _onBall(BallType.normal, runs);
  }

  Future<int?> _pickExtraRuns(String title) async {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.bgMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RunPickerSheet(
        title: '$title — Extra Runs?',
        values: [0, 1, 2, 3, 4, 5, 6],
      ),
    );
  }

  Future<int?> _pickCustomRuns() async {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.bgMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RunPickerSheet(
        title: 'Select Runs',
        values: [5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
        showCustomInput: true,
      ),
    );
  }

  Future<void> _checkState() async {
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
      await _inningsBreak();
      return;
    }

    if (live.needsNewBatsman) await _newBatsmanDialog();

    final l2 = ref.read(scoreProvider).live;
    if (l2 != null && l2.needsNewBowler) await _newBowlerDialog();
  }

  Future<void> _newBatsmanDialog() => _playerDialog('New Batsman', 'Batsman name', (name) {
        ref.read(scoreProvider.notifier).newBatsman(name);
      });

  Future<void> _newBowlerDialog() => _playerDialog('New Bowler', 'Bowler name', (name) {
        ref.read(scoreProvider.notifier).newBowler(name);
      });

  Future<void> _playerDialog(
      String title, String hint, void Function(String) onDone) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NameDialog(title: title, hint: hint, ctrl: ctrl, onDone: onDone),
    );
    ctrl.dispose();
  }

  Future<void> _inningsBreak() async {
    final live = ref.read(scoreProvider).live!;
    final s1 = TextEditingController();
    final s2 = TextEditingController();
    final b = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InningsBreakDialog(
        live: live,
        s1: s1,
        s2: s2,
        b: b,
        onStart: () {
          if (s1.text.trim().isEmpty || s2.text.trim().isEmpty || b.text.trim().isEmpty) return false;
          ref.read(scoreProvider.notifier).startSecondInnings(
                striker: s1.text.trim(),
                nonStriker: s2.text.trim(),
                bowler: b.text.trim(),
              );
          return true;
        },
      ),
    );
    s1.dispose(); s2.dispose(); b.dispose();
  }

  void _undo() {
    if (!ref.read(scoreProvider.notifier).canUndo) return;
    ref.read(scoreProvider.notifier).undoLastBall();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(scoreProvider).live;
    if (live == null) return const SizedBox.shrink();

    return PopScope(
      canPop: true, // allow back — match stays alive in provider
      child: Scaffold(
        appBar: AppBar(
          title: Text('${live.battingTeam}  vs  ${live.bowlingTeam}',
              style: const TextStyle(fontSize: 14)),
          leading: const BackButton(),
          actions: [
            if (ref.watch(scoreProvider.notifier).canUndo)
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo last ball',
                onPressed: _busy ? null : _undo,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text('Inn ${live.currentInnings}/2',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ),
            ),
          ],
        ),
        body: GradientBackground(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _ScoreBoard(live: live),
                      const SizedBox(height: 10),
                      _BatsmenCard(live: live),
                      const SizedBox(height: 8),
                      _BowlerCard(live: live),
                      const SizedBox(height: 8),
                      _OverDisplay(balls: live.overDisplay, overNum: live.currentOverNumber + 1),
                      if (live.pastOvers.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _PastOversToggle(
                          pastOvers: live.pastOvers,
                          expanded: _showPastOvers,
                          onToggle: () => setState(() => _showPastOvers = !_showPastOvers),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _BallButtons(onBall: _onBall, onSpecial: _onSpecialBall, onCustom: _onCustomRuns, busy: _busy),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Scoreboard ───────────────────────────────────────────────────────────────

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
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${live.runs}',
                  style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/${live.wickets}',
                    style: const TextStyle(color: Colors.white70, fontSize: 26, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Text('Overs  ${live.oversStr} / ${live.totalOvers}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Batsmen ──────────────────────────────────────────────────────────────────

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
          _row(live.striker, live.batsmanStats[live.striker], true),
          const Divider(color: AppColors.cardBorder, height: 10),
          _row(live.nonStriker, live.batsmanStats[live.nonStriker], false),
        ],
      ),
    );
  }

  Widget _row(String name, BatsmanStats? s, bool isStriker) => Row(
        children: [
          Text(isStriker ? '* ' : '  ',
              style: const TextStyle(color: AppColors.secondary, fontSize: 16, fontWeight: FontWeight.w900)),
          Expanded(
            child: Text(name.isEmpty ? '—' : name,
                style: TextStyle(
                  color: isStriker ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isStriker ? FontWeight.w700 : FontWeight.w400,
                )),
          ),
          if (s != null)
            Text('${s.runs} (${s.balls})',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      );
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
          const Icon(Icons.sports_cricket, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(live.currentBowler,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          if (bowl != null)
            Text('${bowl.wickets}-${bowl.runs}  (${bowl.overStr})',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Current Over ─────────────────────────────────────────────────────────────

class _OverDisplay extends StatelessWidget {
  final List<String> balls;
  final int overNum;
  const _OverDisplay({required this.balls, required this.overNum});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text('Over $overNum: ',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          Wrap(
            spacing: 6,
            children: balls.isEmpty
                ? [const Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 13))]
                : balls.map((b) => Text(b, style: TextStyle(color: _ballColor(b), fontSize: 13, fontWeight: FontWeight.w700))).toList(),
          ),
        ],
      ),
    );
  }

  Color _ballColor(String b) {
    if (b == 'W') return Colors.redAccent;
    if (b == '4' || b == '6') return AppColors.secondary;
    if (b.startsWith('Wd') || b.startsWith('NB') || b.startsWith('B')) return AppColors.byePurple;
    return AppColors.textSecondary;
  }
}

// ─── Past Overs ───────────────────────────────────────────────────────────────

class _PastOversToggle extends StatelessWidget {
  final List<List<String>> pastOvers;
  final bool expanded;
  final VoidCallback onToggle;
  const _PastOversToggle({required this.pastOvers, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgMid,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('Previous Overs (${pastOvers.length})',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const Spacer(),
                Icon(expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        if (expanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgMid,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: pastOvers.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text('Over ${e.key + 1}:',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ),
                      Wrap(
                        spacing: 6,
                        children: e.value
                            .map((b) => Text(b,
                                style: TextStyle(
                                    color: _ballColor(b),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)))
                            .toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Color _ballColor(String b) {
    if (b == 'W') return Colors.redAccent;
    if (b == '4' || b == '6') return AppColors.secondary;
    if (b.startsWith('Wd') || b.startsWith('NB') || b.startsWith('B')) return AppColors.byePurple;
    return AppColors.textSecondary;
  }
}

// ─── Ball Buttons ─────────────────────────────────────────────────────────────

class _BallButtons extends StatelessWidget {
  final Future<void> Function(BallType, int) onBall;
  final Future<void> Function(BallType) onSpecial;
  final Future<void> Function() onCustom;
  final bool busy;

  const _BallButtons({
    required this.onBall,
    required this.onSpecial,
    required this.onCustom,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
      decoration: const BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        children: [
          // Runs row: 0,1,2,3,4,6 + More
          Row(
            children: [
              ...[0, 1, 2, 3, 4, 6].map((r) => Expanded(
                    child: _Btn(
                      label: r == 0 ? '•' : '$r',
                      bg: r == 4 || r == 6 ? AppColors.secondary.withOpacity(0.2) : AppColors.cardBg,
                      fg: r == 4 || r == 6 ? AppColors.secondary : AppColors.textPrimary,
                      border: r == 4 || r == 6 ? AppColors.secondary.withOpacity(0.5) : AppColors.cardBorder,
                      onTap: busy ? null : () => onBall(BallType.normal, r),
                    ),
                  )),
              Expanded(
                child: _Btn(
                  label: '+',
                  bg: AppColors.cardBg,
                  fg: AppColors.textSecondary,
                  border: AppColors.cardBorder,
                  onTap: busy ? null : onCustom,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // Special row
          Row(
            children: [
              Expanded(
                child: _Btn(
                  label: 'Wide',
                  bg: AppColors.byePurple.withOpacity(0.15),
                  fg: AppColors.byePurple,
                  border: AppColors.byePurple.withOpacity(0.4),
                  onTap: busy ? null : () => onSpecial(BallType.wide),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _Btn(
                  label: 'No Ball',
                  bg: AppColors.byePurple.withOpacity(0.15),
                  fg: AppColors.byePurple,
                  border: AppColors.byePurple.withOpacity(0.4),
                  onTap: busy ? null : () => onSpecial(BallType.noBall),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _Btn(
                  label: 'Bye',
                  bg: AppColors.primary.withOpacity(0.15),
                  fg: AppColors.primary,
                  border: AppColors.primary.withOpacity(0.4),
                  onTap: busy ? null : () => onSpecial(BallType.bye),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                flex: 2,
                child: _Btn(
                  label: 'WICKET',
                  bg: Colors.redAccent.withOpacity(0.15),
                  fg: Colors.redAccent,
                  border: Colors.redAccent.withOpacity(0.4),
                  onTap: busy ? null : () => onBall(BallType.wicket, 0),
                  bold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color bg, fg, border;
  final VoidCallback? onTap;
  final bool bold;

  const _Btn({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
    required this.onTap,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: onTap == null ? fg.withOpacity(0.4) : fg,
              fontSize: bold ? 13 : 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Run Picker Sheet ─────────────────────────────────────────────────────────

class _RunPickerSheet extends StatefulWidget {
  final String title;
  final List<int> values;
  final bool showCustomInput;

  const _RunPickerSheet({
    required this.title,
    required this.values,
    this.showCustomInput = false,
  });

  @override
  State<_RunPickerSheet> createState() => _RunPickerSheetState();
}

class _RunPickerSheetState extends State<_RunPickerSheet> {
  final _ctrl = TextEditingController();
  bool _typing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Text(widget.title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.values.map((v) {
              final isSpecial = v == 4 || v == 6;
              return GestureDetector(
                onTap: () => Navigator.pop(context, v),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSpecial
                        ? AppColors.secondary.withOpacity(0.2)
                        : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSpecial
                          ? AppColors.secondary.withOpacity(0.6)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Center(
                    child: Text('$v',
                        style: TextStyle(
                          color: isSpecial ? AppColors.secondary : AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
          if (widget.showCustomInput) ...[
            const SizedBox(height: 12),
            if (!_typing)
              TextButton(
                onPressed: () => setState(() => _typing = true),
                child: const Text('Enter custom value',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(hintText: 'Enter runs (1–20)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final v = int.tryParse(_ctrl.text.trim());
                      if (v != null && v >= 0 && v <= 20) {
                        Navigator.pop(context, v);
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Dialogs ──────────────────────────────────────────────────────────────────

class _NameDialog extends StatefulWidget {
  final String title, hint;
  final TextEditingController ctrl;
  final void Function(String) onDone;

  const _NameDialog({
    required this.title,
    required this.hint,
    required this.ctrl,
    required this.onDone,
  });

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  String? _err;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgMid,
      title: Text(widget.title,
          style: const TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: widget.ctrl,
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(hintText: widget.hint, errorText: _err),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
            onPressed: _confirm,
            child: const Text('OK', style: TextStyle(color: AppColors.secondary))),
      ],
    );
  }

  void _confirm() {
    final name = widget.ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _err = 'Name required');
      return;
    }
    widget.onDone(name);
    Navigator.pop(context);
  }
}

class _InningsBreakDialog extends StatefulWidget {
  final LiveMatchState live;
  final TextEditingController s1, s2, b;
  final bool Function() onStart;

  const _InningsBreakDialog({
    required this.live,
    required this.s1,
    required this.s2,
    required this.b,
    required this.onStart,
  });

  @override
  State<_InningsBreakDialog> createState() => _InningsBreakDialogState();
}

class _InningsBreakDialogState extends State<_InningsBreakDialog> {
  String? _err;

  @override
  Widget build(BuildContext context) {
    final live = widget.live;
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
                  color: AppColors.bgDeep, borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Text('${live.teamA}   ${live.runs}/${live.wickets}',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                Text('(${live.oversStr} ov)',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${live.teamB} needs ${live.runs + 1} to win',
                    style: const TextStyle(
                        color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 14),
            _lbl('${live.teamB} Opening Batsmen'),
            const SizedBox(height: 6),
            _tf(widget.s1, 'Striker'),
            const SizedBox(height: 6),
            _tf(widget.s2, 'Non-Striker'),
            const SizedBox(height: 10),
            _lbl('Opening Bowler (${live.teamA})'),
            const SizedBox(height: 6),
            _tf(widget.b, 'Bowler name'),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_err!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _start,
            child: const Text('Start 2nd Innings',
                style: TextStyle(color: AppColors.secondary))),
      ],
    );
  }

  Widget _lbl(String t) => Text(t.toUpperCase(),
      style: const TextStyle(
          color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w600));

  Widget _tf(TextEditingController c, String h) => TextField(
      controller: c,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(hintText: h));

  void _start() {
    if (!widget.onStart()) {
      setState(() => _err = 'All fields required');
      return;
    }
    Navigator.pop(context);
  }
}
