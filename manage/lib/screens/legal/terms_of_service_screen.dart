import 'package:flutter/material.dart';

/// Terms of Service Screen - Consistent with Settings design
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar matching Settings style
          SliverAppBar.large(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Terms of Service',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary, colorScheme.primaryContainer],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Last Updated Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.update, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Last updated: February 1, 2026',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Introduction Section
                _TermsSection(
                  title: 'Introduction',
                  icon: Icons.handshake_outlined,
                  children: [
                    _TermsTile(
                      icon: Icons.agriculture_outlined,
                      iconColor: Colors.green,
                      title: 'About the Platform',
                      content:
                          'This Farm Management Platform is designed to support livestock farmers through digital record-keeping, summaries, and decision-support tools.',
                    ),
                    _TermsTile(
                      icon: Icons.check_circle_outline,
                      iconColor: Colors.blue,
                      title: 'Agreement',
                      content:
                          'By accessing or using the Platform, you agree to these Terms of Service. If you do not agree to these terms, please do not use the Platform.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Platform Nature Section
                _TermsSection(
                  title: 'Nature of the Platform',
                  icon: Icons.build_outlined,
                  children: [
                    _TermsTile(
                      icon: Icons.construction_outlined,
                      iconColor: Colors.orange,
                      title: 'Active Development',
                      content:
                          'The Platform is under active development and may change over time. Features may be added, modified, or removed to improve functionality and reliability.',
                    ),
                    _TermsTile(
                      icon: Icons.info_outline,
                      iconColor: Colors.purple,
                      title: 'Informational Use',
                      content:
                          'The Platform provides tools and insights for informational purposes only. It does not replace professional veterinary, agricultural, financial, or legal advice.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // User Responsibilities Section
                _TermsSection(
                  title: 'User Responsibilities',
                  icon: Icons.assignment_ind_outlined,
                  children: [
                    _TermsTile(
                      icon: Icons.fact_check_outlined,
                      iconColor: Colors.blue,
                      title: 'Data Accuracy',
                      content:
                          'You are responsible for the accuracy and completeness of all data you enter into the Platform.',
                    ),
                    _TermsTile(
                      icon: Icons.person_outline,
                      iconColor: Colors.green,
                      title: 'Your Decisions',
                      content:
                          'Decisions made using information from the Platform are your own responsibility.',
                    ),
                    _TermsTile(
                      icon: Icons.gavel_outlined,
                      iconColor: Colors.indigo,
                      title: 'Lawful Use',
                      content:
                          'You will use the Platform in a lawful, ethical, and responsible manner.',
                    ),
                    _TermsTile(
                      icon: Icons.block_outlined,
                      iconColor: Colors.red,
                      title: 'No Misuse',
                      content:
                          'You will not attempt to misuse, disrupt, or reverse-engineer the Platform.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Automated Insights Section
                _TermsSection(
                  title: 'Automated Insights',
                  icon: Icons.lightbulb_outlined,
                  children: [
                    _TermsTile(
                      icon: Icons.auto_awesome_outlined,
                      iconColor: Colors.amber,
                      title: 'Decision Support',
                      content:
                          'The Platform may generate automated insights or recommendations based on user-provided data.',
                    ),
                    _TermsTile(
                      icon: Icons.warning_amber_outlined,
                      iconColor: Colors.orange,
                      title: 'Not Professional Advice',
                      content:
                          'These outputs are intended to support decision-making only and should not be treated as professional advice. Final decisions and outcomes remain your responsibility.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Availability Section
                _TermsSection(
                  title: 'Availability & Changes',
                  icon: Icons.cloud_outlined,
                  children: [
                    _TermsTile(
                      icon: Icons.public_outlined,
                      iconColor: Colors.blue,
                      title: 'Service Availability',
                      content:
                          'The Platform is provided "as is" and "as available". Continuous availability is not guaranteed.',
                    ),
                    _TermsTile(
                      icon: Icons.build_circle_outlined,
                      iconColor: Colors.teal,
                      title: 'Maintenance',
                      content:
                          'Access may be temporarily limited due to maintenance, updates, or technical issues.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Liability Section
                _TermsSection(
                  title: 'Limitation of Liability',
                  icon: Icons.shield_outlined,
                  children: [
                    _TermsTile(
                      icon: Icons.security_outlined,
                      iconColor: Colors.green,
                      title: 'Legal Protection',
                      content:
                          'To the maximum extent permitted by applicable law, the creators of the Platform are not liable for any direct, indirect, incidental, or consequential damages arising from use of the Platform.',
                    ),
                    _TermsTile(
                      icon: Icons.warning_outlined,
                      iconColor: Colors.red,
                      title: 'Use at Own Risk',
                      content:
                          'Use of the Platform is entirely at your own risk.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Termination Section
                _TermsSection(
                  title: 'Termination',
                  icon: Icons.cancel_outlined,
                  children: [
                    _TermsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: Colors.orange,
                      title: 'Platform Rights',
                      content:
                          'The Platform reserves the right to suspend or terminate access in cases of misuse or violation of these terms.',
                    ),
                    _TermsTile(
                      icon: Icons.exit_to_app_outlined,
                      iconColor: Colors.blue,
                      title: 'Your Rights',
                      content:
                          'Users may stop using the Platform at any time without penalty.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Contact Section
                _ContactCard(isDark: isDark),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// Terms Section Card - Similar to _SettingsSection
class _TermsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _TermsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children.asMap().entries.map((entry) {
            final isLast = entry.key == children.length - 1;
            return Column(
              children: [
                entry.value,
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Terms Tile - Similar to _SettingsTile but with content
class _TermsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const _TermsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Contact Card
class _ContactCard extends StatelessWidget {
  final bool isDark;

  const _ContactCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surfaceContainerHigh,
                ]
              : [
                  colorScheme.primaryContainer.withValues(alpha: 0.3),
                  colorScheme.secondaryContainer.withValues(alpha: 0.3),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.contact_support,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Questions?',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact us about these terms',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ContactChip(
                icon: Icons.email_outlined,
                label: 'andrewayiko15@gmail.com',
                color: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ContactChip(
                icon: Icons.phone_outlined,
                label: '+256788 916070',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ContactChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
