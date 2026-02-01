import 'package:flutter/material.dart';

/// Privacy Policy Screen - Consistent with Settings design
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                'Privacy Policy',
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
                _PolicySection(
                  title: 'Introduction',
                  icon: Icons.info_outline,
                  children: [
                    _PolicyTile(
                      icon: Icons.description_outlined,
                      iconColor: Colors.blue,
                      title: 'About This Policy',
                      content:
                          'This Privacy Policy explains how data is collected, used, and protected within the Farm Management Platform.',
                    ),
                    _PolicyTile(
                      icon: Icons.verified_outlined,
                      iconColor: Colors.green,
                      title: 'Our Commitment',
                      content:
                          'The Platform is built with a commitment to transparency, responsible data use, and user control.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Data Controller Section
                _PolicySection(
                  title: 'Data Controller',
                  icon: Icons.admin_panel_settings_outlined,
                  children: [
                    _PolicyTile(
                      icon: Icons.gavel_outlined,
                      iconColor: Colors.indigo,
                      title: 'Legal Compliance',
                      content:
                          'The Platform operator acts as the Data Controller and processes data in accordance with applicable laws, including GDPR (where applicable) and the Uganda Data Protection and Privacy Act, 2019.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Data Collection Section
                _PolicySection(
                  title: 'Data We Collect',
                  icon: Icons.storage_outlined,
                  children: [
                    _PolicyTile(
                      icon: Icons.pets_outlined,
                      iconColor: Colors.orange,
                      title: 'Farm Records',
                      content:
                          'Livestock and farm records entered by users for management purposes.',
                    ),
                    _PolicyTile(
                      icon: Icons.settings_outlined,
                      iconColor: Colors.purple,
                      title: 'Operational Data',
                      content:
                          'Data required to deliver Platform functionality and ensure proper operation.',
                    ),
                    _PolicyTile(
                      icon: Icons.sync_outlined,
                      iconColor: Colors.teal,
                      title: 'Technical Data',
                      content:
                          'Data necessary for system reliability, backup, and synchronization.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Data Usage Section
                _PolicySection(
                  title: 'How Data Is Used',
                  icon: Icons.data_usage_outlined,
                  children: [
                    _PolicyTile(
                      icon: Icons.insights_outlined,
                      iconColor: Colors.blue,
                      title: 'Management & Insights',
                      content:
                          'Provide livestock record management, summaries, and insights to help you manage your farm.',
                    ),
                    _PolicyTile(
                      icon: Icons.cloud_sync_outlined,
                      iconColor: Colors.green,
                      title: 'Cloud Backup',
                      content:
                          'Perform automatic cloud backup and synchronization to prevent data loss.',
                    ),
                    _PolicyTile(
                      icon: Icons.auto_awesome_outlined,
                      iconColor: Colors.amber,
                      title: 'System Improvement',
                      content:
                          'Improve system reliability, usability, and performance based on usage patterns.',
                    ),
                    _PolicyTile(
                      icon: Icons.psychology_outlined,
                      iconColor: Colors.pink,
                      title: 'Research & ML',
                      content:
                          'Support applied research and train machine learning models to improve livestock management tools. Focus is on aggregated patterns, not individual users.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Data Protection Section
                _PolicySection(
                  title: 'Data Protection',
                  icon: Icons.security_outlined,
                  children: [
                    _PolicyTile(
                      icon: Icons.block_outlined,
                      iconColor: Colors.red,
                      title: 'No Data Sales',
                      content:
                          'The Platform does not sell data, share it for advertising purposes, or trade user information.',
                    ),
                    _PolicyTile(
                      icon: Icons.shield_outlined,
                      iconColor: Colors.green,
                      title: 'Security Measures',
                      content:
                          'Reasonable technical and organizational measures are implemented to protect stored data.',
                    ),
                    _PolicyTile(
                      icon: Icons.person_outline,
                      iconColor: Colors.blue,
                      title: 'Data Ownership',
                      content:
                          'All data entered into the Platform remains the property of the user. We do not claim ownership over your data.',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // User Rights Section
                _PolicySection(
                  title: 'Your Rights',
                  icon: Icons.verified_user_outlined,
                  children: [
                    _PolicyTile(
                      icon: Icons.visibility_outlined,
                      iconColor: Colors.blue,
                      title: 'Access Your Data',
                      content:
                          'You have the right to access all your stored data at any time.',
                    ),
                    _PolicyTile(
                      icon: Icons.download_outlined,
                      iconColor: Colors.green,
                      title: 'Export Your Data',
                      content:
                          'You can export your data in standard formats whenever you need.',
                    ),
                    _PolicyTile(
                      icon: Icons.exit_to_app_outlined,
                      iconColor: Colors.orange,
                      title: 'Stop Using',
                      content:
                          'You may stop using the Platform at any time without penalty.',
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

// Policy Section Card - Similar to _SettingsSection
class _PolicySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _PolicySection({
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

// Policy Tile - Similar to _SettingsTile but with content instead of subtitle
class _PolicyTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const _PolicyTile({
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
            'Contact us for any privacy concerns',
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
