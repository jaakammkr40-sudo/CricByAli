import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/gradient_background.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: GradientBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // Avatar
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'AR',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Name
            const Center(
              child: Text(
                'Ali Raza Randhawa',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Developer & Creator of Cric By Ali',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Contact info
            _sectionLabel('Contact'),
            const SizedBox(height: 10),
            _contactTile(
              context,
              icon: Icons.phone,
              label: 'Phone',
              value: '+923111200138',
            ),
            const SizedBox(height: 8),
            _contactTile(
              context,
              icon: Icons.email,
              label: 'Email',
              value: 'itxali333@gmail.com',
            ),

            const SizedBox(height: 32),

            // Sponsors
            _sectionLabel('Sponsored By'),
            const SizedBox(height: 10),
            _sponsorCard(
              name: 'Al Fatah Cricket Club 429EB',
              subtitle: 'Burewala, Punjab',
              isPrimary: true,
            ),
            const SizedBox(height: 10),
            _sponsorCard(
              name: 'Burewala Union Cricket',
              subtitle: 'Official Cricket Union',
              isPrimary: false,
            ),

            const SizedBox(height: 32),

            // App info
            _sectionLabel('App Info'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Column(
                children: [
                  _InfoRow(label: 'App Name', value: 'Cric By Ali'),
                  Divider(color: AppColors.cardBorder, height: 20),
                  _InfoRow(label: 'Version', value: '1.0.0'),
                  Divider(color: AppColors.cardBorder, height: 20),
                  _InfoRow(label: 'Platform', value: 'Flutter (Android)'),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Made with ❤️ for local cricket\nAl Fatah Cricket Club 429EB',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      );

  Widget _contactTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) =>
      GestureDetector(
        onTap: () => _copy(context, value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    Text(value,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.copy, color: AppColors.textMuted, size: 16),
            ],
          ),
        ),
      );

  Widget _sponsorCard({
    required String name,
    required String subtitle,
    required bool isPrimary,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isPrimary ? AppColors.goldGradient : null,
          color: isPrimary ? null : AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary ? AppColors.secondary : AppColors.cardBorder,
            width: isPrimary ? 2 : 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.3),
                    blurRadius: 14,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.sports_cricket,
              color: isPrimary ? Colors.black87 : AppColors.secondary,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isPrimary ? Colors.black87 : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color:
                          isPrimary ? Colors.black54 : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
