import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/tournament_engine.dart';
import '../../models/team.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/app_button.dart';
import '../groups/group_overview_screen.dart';

const _uuid = Uuid();

class TournamentSetupScreen extends ConsumerStatefulWidget {
  const TournamentSetupScreen({super.key});

  @override
  ConsumerState<TournamentSetupScreen> createState() =>
      _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends ConsumerState<TournamentSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Al Fatah Cup 2025');
  final _groupCountCtrl = TextEditingController(text: '4');
  final _bulkCtrl = TextEditingController();
  final _addOneCtrl = TextEditingController();

  bool _useAutoTeams = true;
  int _autoTeamCount = 12;

  // List of (id, controller) for the editable team list
  final List<(String, TextEditingController)> _teams = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _groupCountCtrl.dispose();
    _bulkCtrl.dispose();
    _addOneCtrl.dispose();
    for (final (_, c) in _teams) {
      c.dispose();
    }
    super.dispose();
  }

  void _parseBulk() {
    final lines = _bulkCtrl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return;

    setState(() {
      for (final line in lines) {
        _teams.add((_uuid.v4(), TextEditingController(text: line)));
      }
      _bulkCtrl.clear();
    });
  }

  void _addOneTeam() {
    final name = _addOneCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _teams.add((_uuid.v4(), TextEditingController(text: name)));
      _addOneCtrl.clear();
    });
  }

  void _removeTeam(int index) {
    final (_, ctrl) = _teams[index];
    ctrl.dispose();
    setState(() => _teams.removeAt(index));
  }

  List<Team> _buildTeams() {
    if (_useAutoTeams) {
      return TournamentEngine.generateDummyTeams(_autoTeamCount.clamp(2, 200));
    }
    final seen = <String>{};
    final result = <Team>[];
    for (final (id, ctrl) in _teams) {
      var name = ctrl.text.trim();
      if (name.isEmpty) name = 'Team';
      if (seen.contains(name)) name = '$name (${result.length + 1})';
      seen.add(name);
      result.add(Team(id: id, name: name));
    }
    return result;
  }

  void _createTournament() {
    if (!_formKey.currentState!.validate()) return;

    if (!_useAutoTeams && _teams.length < 2) {
      _showError('Add at least 2 teams.');
      return;
    }

    final teams = _buildTeams();
    final numGroups = int.tryParse(_groupCountCtrl.text) ?? 1;

    if (numGroups > teams.length) {
      _showError('Groups cannot exceed number of teams (${teams.length}).');
      return;
    }

    ref.read(tournamentProvider.notifier).createTournament(
          name: _nameCtrl.text.trim(),
          teams: teams,
          numGroups: numGroups.clamp(1, teams.length),
        );

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GroupOverviewScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Tournament'),
        leading: const BackButton(),
      ),
      body: GradientBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _sectionLabel('Tournament Details'),
              const SizedBox(height: 10),
              _textField(
                controller: _nameCtrl,
                label: 'Tournament Name',
                hint: 'e.g. Al Fatah Cup 2025',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter tournament name' : null,
              ),
              const SizedBox(height: 20),
              _textField(
                controller: _groupCountCtrl,
                label: 'Number of Groups',
                hint: '4',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Min 1';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              _sectionLabel('Team Entry Mode'),
              const SizedBox(height: 10),
              _modeToggle(),
              const SizedBox(height: 20),

              if (_useAutoTeams) ...[
                _sectionLabel('Number of Teams'),
                const SizedBox(height: 10),
                _autoTeamCountRow(),
              ],

              if (!_useAutoTeams) ...[
                // ── Bulk paste area ──────────────────────────────
                _sectionLabel('Paste Teams (one per line)'),
                const SizedBox(height: 8),
                _bulkPasteField(),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Add These Teams',
                  icon: Icons.playlist_add,
                  onPressed: _parseBulk,
                ),
                const SizedBox(height: 24),

                // ── Parsed / editable list ───────────────────────
                if (_teams.isNotEmpty) ...[
                  Row(
                    children: [
                      _sectionLabel('Teams  (${_teams.length})'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          for (final (_, c) in _teams) c.dispose();
                          setState(() => _teams.clear());
                        },
                        child: const Text(
                          'Clear all',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._teams.asMap().entries.map(
                        (e) => _teamRow(e.key, e.value.$2),
                      ),
                  const SizedBox(height: 12),
                ],

                // ── Add single team ──────────────────────────────
                _sectionLabel('Add One Team'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _addOneCtrl,
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Team name',
                          hintText: 'e.g. 432 Ahmad',
                        ),
                        onFieldSubmitted: (_) => _addOneTeam(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _addOneTeam,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.black87, size: 22),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 36),
              AppButton(
                label: 'Create Tournament',
                icon: Icons.sports_cricket,
                isGold: true,
                onPressed: _createTournament,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulkPasteField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: _bulkCtrl,
        maxLines: 7,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '101 EB\n302\n432 Ahmad\nReal Madrid\n...',
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }

  Widget _teamRow(int index, TextEditingController ctrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.cardBorder),
          Expanded(
            child: TextField(
              controller: ctrl,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
            onPressed: () => _removeTeam(index),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _autoTeamCountRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_autoTeamCount > 2) setState(() => _autoTeamCount--);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.bgMid,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.remove,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
          Expanded(
            child: Text(
              '$_autoTeamCount teams',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_autoTeamCount < 200) setState(() => _autoTeamCount++);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.bgMid,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _useAutoTeams = true),
            child: _modeCard(
              icon: Icons.auto_awesome,
              label: 'Auto-Generate',
              subtitle: 'Use preset names',
              selected: _useAutoTeams,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _useAutoTeams = false),
            child: _modeCard(
              icon: Icons.format_list_bulleted,
              label: 'Enter Teams',
              subtitle: 'Paste or type names',
              selected: !_useAutoTeams,
            ),
          ),
        ),
      ],
    );
  }

  Widget _modeCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool selected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: selected ? AppColors.primaryGradient : null,
        color: selected ? null : AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.cardBorder,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: selected ? Colors.white : AppColors.textMuted, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: selected ? Colors.white70 : AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: validator,
    );
  }
}
