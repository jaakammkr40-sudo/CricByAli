import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/score_models.dart';
import '../../providers/score_provider.dart';
import '../../widgets/gradient_background.dart';
import 'match_setup_screen.dart';
import 'scoring_screen.dart';

class ScoreHomeScreen extends ConsumerWidget {
  const ScoreHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Manager'),
        automaticallyImplyLeading: false,
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Resume banner when match in progress
            if (state.live != null)
              _ResumeBanner(
                live: state.live!,
                onResume: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScoringScreen()),
                ),
                onDiscard: () => _confirmDiscard(context, ref),
              ),
            Expanded(
              child: state.matches.isEmpty && state.live == null
                  ? _EmptyState(onNew: () => _newMatch(context))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      children: [
                        for (final match in state.matches)
                          _MatchHistoryCard(
                            match: match,
                            onDelete: () => _confirmDelete(context, ref, match.id),
                            onEditWinner: () => _editWinner(context, ref, match),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: state.live == null
          ? FloatingActionButton.extended(
              onPressed: () => _newMatch(context),
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.black87,
              icon: const Icon(Icons.add),
              label: const Text('New Match',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  void _newMatch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MatchSetupScreen()),
    );
  }

  void _confirmDiscard(BuildContext context, WidgetRef ref) {
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
            },
            child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgMid,
        title: const Text('Delete Match?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(scoreProvider.notifier).deleteMatch(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _editWinner(BuildContext context, WidgetRef ref, ScoreMatch match) {
    String? selected = match.winner;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.bgMid,
          title: const Text('Edit Winner',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final team in [match.teamA, match.teamB, null])
                RadioListTile<String?>(
                  value: team,
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v),
                  title: Text(team ?? 'Tie',
                      style: const TextStyle(color: AppColors.textPrimary)),
                  activeColor: AppColors.secondary,
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                ref.read(scoreProvider.notifier).editMatchWinner(match.id, selected);
                Navigator.pop(ctx);
              },
              child: const Text('Save',
                  style: TextStyle(color: AppColors.secondary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Resume Banner ────────────────────────────────────────────────────────────

class _ResumeBanner extends StatelessWidget {
  final LiveMatchState live;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const _ResumeBanner(
      {required this.live, required this.onResume, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onResume,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.sports_cricket, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Match In Progress',
                      style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5)),
                  Text('${live.teamA}  vs  ${live.teamB}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  Text('${live.runs}/${live.wickets}  (${live.oversStr})  Inn ${live.currentInnings}/2',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Resume',
                      style: TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onDiscard,
                  child: const Text('Discard',
                      style: TextStyle(color: Colors.white54, fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyState({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, gradient: AppColors.primaryGradient),
            child: const Icon(Icons.sports_cricket, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('No Matches Yet',
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Start scoring your first match',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add),
            label: const Text('New Match'),
          ),
        ],
      ),
    );
  }
}

// ─── Match History Card ───────────────────────────────────────────────────────

class _MatchHistoryCard extends StatefulWidget {
  final ScoreMatch match;
  final VoidCallback onDelete;
  final VoidCallback onEditWinner;

  const _MatchHistoryCard({
    required this.match,
    required this.onDelete,
    required this.onEditWinner,
  });

  @override
  State<_MatchHistoryCard> createState() => _MatchHistoryCardState();
}

class _MatchHistoryCardState extends State<_MatchHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final first = match.firstInnings;
    final second = match.secondInnings;
    final winnerLabel = match.winner == null ? 'TIE' : '${match.winner} WON';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // ── Header (tap to expand) ──
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgMid,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: _expanded ? Radius.zero : const Radius.circular(0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${match.teamA}  vs  ${match.teamB}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  Text('${match.overs} ov',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
          ),

          // ── Brief summary (always visible) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              children: [
                _inningsRow(first),
                if (second != null) ...[
                  const SizedBox(height: 4),
                  _inningsRow(second),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: match.winner != null
                            ? AppColors.winnerGreen.withOpacity(0.15)
                            : AppColors.bgMid,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: match.winner != null
                              ? AppColors.winnerGreen
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Text(winnerLabel,
                          style: TextStyle(
                              color: match.winner != null
                                  ? AppColors.winnerGreen
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                    // Top bat + bowl chips
                    if (first.topBatsman != null)
                      _miniChip(Icons.person, first.topBatsman!.name,
                          '${first.topBatsman!.runs}(${first.topBatsman!.balls})'),
                    if (first.topBowler != null)
                      _miniChip(Icons.sports_cricket, first.topBowler!.name,
                          '${first.topBowler!.wickets}/${first.topBowler!.runs}'),
                  ],
                ),
              ],
            ),
          ),

          // ── Full scorecard (expanded) ──
          if (_expanded && second != null) ...[
            const Divider(color: AppColors.cardBorder, height: 1),
            _FullInningsTable(innings: first),
            const Divider(color: AppColors.cardBorder, height: 1),
            _FullInningsTable(innings: second),
          ],

          // ── Actions ──
          const Divider(color: AppColors.cardBorder, height: 1),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: widget.onEditWinner,
                  icon: const Icon(Icons.edit, size: 15),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.cardBorder),
              Expanded(
                child: TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, size: 15),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inningsRow(InningsData innings) => Row(
        children: [
          Expanded(
              child: Text(innings.battingTeam,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Text('${innings.totalRuns}/${innings.wickets}',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(width: 5),
          Text('(${innings.overStr})',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      );

  Widget _miniChip(IconData icon, String name, String stat) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 3),
          Text('$name $stat',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              overflow: TextOverflow.ellipsis),
        ],
      );
}

// ─── Full Innings Table ───────────────────────────────────────────────────────

class _FullInningsTable extends StatelessWidget {
  final InningsData innings;
  const _FullInningsTable({required this.innings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Innings title
          Text(
            '${innings.battingTeam}   ${innings.totalRuns}/${innings.wickets}  (${innings.overStr} ov)',
            style: const TextStyle(
                color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          // Batting header
          _hdr(['Batsman', 'R', 'B', 'SR']),
          ...innings.batsmen.map((b) {
            final sr = b.balls == 0 ? '-' : (b.runs / b.balls * 100).toStringAsFixed(0);
            return _batRow(b.name, '${b.runs}', '${b.balls}', sr, b.isOut, b.runs >= 50);
          }),

          const SizedBox(height: 8),
          // Bowling header
          _hdr(['Bowler', 'O', 'R', 'W']),
          ...innings.bowlers.map((b) {
            return _bowlRow(b.name, b.overStr, '${b.runs}', '${b.wickets}', b.wickets >= 3);
          }),
        ],
      ),
    );
  }

  Widget _hdr(List<String> cols) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.cardBorder))),
        child: Row(
          children: [
            Expanded(
                child: Text(cols[0],
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1))),
            for (final c in cols.skip(1))
              SizedBox(
                width: 32,
                child: Text(c,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
              ),
          ],
        ),
      );

  Widget _batRow(String name, String r, String b, String sr, bool isOut, bool fifty) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  Text(isOut ? 'out' : 'not out',
                      style: TextStyle(
                          color: isOut ? Colors.redAccent : AppColors.winnerGreen,
                          fontSize: 9)),
                ],
              ),
            ),
            _cell(r, highlight: fifty),
            _cell(b),
            _cell(sr),
          ],
        ),
      );

  Widget _bowlRow(String name, String o, String r, String w, bool highlight) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
                child: Text(name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))),
            _cell(o),
            _cell(r),
            _cell(w, highlight: highlight),
          ],
        ),
      );

  Widget _cell(String v, {bool highlight = false}) => SizedBox(
        width: 32,
        child: Text(v,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: highlight ? AppColors.secondary : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w500)),
      );
}
