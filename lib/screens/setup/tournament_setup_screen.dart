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
  final _teamCountCtrl = TextEditingController(text: '12');
  final _groupCountCtrl = TextEditingController(text: '4');

  bool _useAutoTeams = true;
  List<TextEditingController> _teamControllers = [];
  int _manualTeamCount = 8;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _teamCountCtrl.dispose();
    _groupCountCtrl.dispose();
    for (final c in _teamControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _switchToManual() {
    final count = int.tryParse(_teamCountCtrl.text) ?? 8;
    final clampedCount = count.clamp(2, 200);
    for (final c in _teamControllers) {
      c.dispose();
    }
    _teamControllers = List.generate(
      clampedCount,
      (i) => TextEditingController(text: 'Team ${i + 1}'),
    );
    setState(() {
      _useAutoTeams = false;
      _manualTeamCount = clampedCount;
    });
  }

  List<Team> _buildTeams() {
    if (_useAutoTeams) {
      final count = int.tryParse(_teamCountCtrl.text) ?? 8;
      return TournamentEngine.generateDummyTeams(count.clamp(2, 200));
    }
    final names = <String>{};
    final teams = <Team>[];
    for (final ctrl in _teamControllers) {
      final raw = ctrl.text.trim();
      final name = names.contains(raw) ? '$raw (${names.length})' : raw;
      names.add(name);
      teams.add(Team(id: _uuid.v4(), name: name));
    }
    return teams;
  }

  void _createTournament() {
    if (!_formKey.currentState!.validate()) return;

    final teams = _buildTeams();
    final numGroups = int.tryParse(_groupCountCtrl.text) ?? 4;

    if (numGroups > teams.length) {
      _showError('Number of groups cannot exceed number of teams.');
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
              const SizedBox(height: 24),
              _sectionLabel('Teams'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      controller: _teamCountCtrl,
                      label: 'Number of Teams',
                      hint: '12',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 2) return 'Min 2';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _teamModeToggle(),
              const SizedBox(height: 12),
              if (!_useAutoTeams) ...[
                _sectionLabel('Team Names'),
                const SizedBox(height: 10),
                ..._teamControllers.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _textField(
                      controller: e.value,
                      label: 'Team ${e.key + 1}',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _iconBtn(Icons.remove, () {
                      if (_teamControllers.length <= 2) return;
                      _teamControllers.last.dispose();
                      setState(() {
                        _teamControllers.removeLast();
                        _manualTeamCount--;
                      });
                    }),
                    const SizedBox(width: 8),
                    _iconBtn(Icons.add, () {
                      setState(() {
                        _manualTeamCount++;
                        _teamControllers.add(
                          TextEditingController(
                              text: 'Team $_manualTeamCount'),
                        );
                      });
                    }),
                    const SizedBox(width: 10),
                    Text(
                      '${_teamControllers.length} teams',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
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

  Widget _teamModeToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _useAutoTeams = true),
            child: _modeCard(
              icon: Icons.auto_awesome,
              label: 'Auto-Generate',
              subtitle: 'Use preset team names',
              selected: _useAutoTeams,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: _switchToManual,
            child: _modeCard(
              icon: Icons.edit_note,
              label: 'Enter Manually',
              subtitle: 'Type your team names',
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
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                )
              ]
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
              color: selected
                  ? Colors.white70
                  : AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}
