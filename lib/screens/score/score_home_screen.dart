import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/score_models.dart';
import '../../providers/score_provider.dart';
import '../../widgets/gradient_background.dart';
import 'match_setup_screen.dart';

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
        child: state.matches.isEmpty
            ? _EmptyState(onNew: () => _newMatch(context))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  for (final match in state.matches)
                    _MatchHistoryCard(
                      match: match,
                      onDelete: () => _confirmDelete(context, ref, match.id),
                      onEditWinner: () =>
                          _editWinner(context, ref, match),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newMatch(context),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.add),
        label: const Text('New Match',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _newMatch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MatchSetupScreen()),
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
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(Icons.sports_cricket,
                color: Colors.white, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('No Matches Yet',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
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

class _MatchHistoryCard extends StatelessWidget {
  final ScoreMatch match;
  final VoidCallback onDelete;
  final VoidCallback onEditWinner;

  const _MatchHistoryCard({
    required this.match,
    required this.onDelete,
    required this.onEditWinner,
  });

  @override
  Widget build(BuildContext context) {
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgMid,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${match.teamA}  vs  ${match.teamB}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${match.overs} ov',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),

          // Scores
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _inningsRow(first),
                if (second != null) ...[
                  const SizedBox(height: 6),
                  _inningsRow(second),
                ],
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  child: Text(
                    winnerLabel,
                    style: TextStyle(
                      color: match.winner != null
                          ? AppColors.winnerGreen
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (first.topBatsman != null || first.topBowler != null) ...[
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (first.topBatsman != null)
                        Expanded(
                          child: _statChip(
                            Icons.person,
                            'Top Bat',
                            '${first.topBatsman!.name} ${first.topBatsman!.runs}(${first.topBatsman!.balls})',
                          ),
                        ),
                      if (first.topBowler != null)
                        Expanded(
                          child: _statChip(
                            Icons.sports_cricket,
                            'Top Bowl',
                            '${first.topBowler!.name} ${first.topBowler!.wickets}/${first.topBowler!.runs}',
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Actions
          const Divider(color: AppColors.cardBorder, height: 1),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onEditWinner,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.cardBorder),
              Expanded(
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
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
            child: Text(
              innings.battingTeam,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Text(
            '${innings.totalRuns}/${innings.wickets}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '(${innings.overStr})',
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      );

  Widget _statChip(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      );
}
