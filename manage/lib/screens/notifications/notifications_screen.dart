// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../models/reminder.dart';
import '../../providers/providers.dart';
import '../../providers/auth_providers.dart';
import '../../router/app_router.dart';
import '../../utils/responsive_layout.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReminderType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get counts for badges
    final activeReminders = ref.watch(activeRemindersProvider);
    final allReminders = ref.watch(remindersProvider);
    final systemNotifications = ref.watch(adminNotificationsProvider);

    final activeCount = activeReminders.maybeWhen(
      data: (reminders) => reminders.length,
      orElse: () => 0,
    );

    final upcomingCount = allReminders.maybeWhen(
      data: (reminders) => reminders
          .where(
            (r) =>
                r.status == ReminderStatus.pending &&
                r.dueDate.isAfter(DateTime.now()),
          )
          .length,
      orElse: () => 0,
    );

    final systemCount = systemNotifications.maybeWhen(
      data: (notifications) => notifications.where((n) => !n.read).length,
      orElse: () => 0,
    );

    final allCount = allReminders.maybeWhen(
      data: (reminders) => reminders.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Reminders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => coordinator.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Reminders',
            onPressed: _syncReminders,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Reminder Settings',
            onPressed: () => _showSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Reminder',
            onPressed: () => _showAddReminderDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            _buildTabWithBadge('Active', activeCount, theme),
            _buildTabWithBadge('Upcoming', upcomingCount, theme),
            _buildTabWithBadge('System', systemCount, theme),
            _buildTabWithBadge('All', allCount, theme),
          ],
        ),
      ),
      body: Column(
        children: [
          // Add spacing between tabs and content
          const SizedBox(height: 8),
          // Filter chips (hide for System tab)
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) => _tabController.index == 2
                ? const SizedBox.shrink()
                : _buildFilterChips(theme),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTab(),
                _buildUpcomingTab(),
                _buildSystemNotificationsTab(),
                _buildAllTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabWithBadge(String text, int count, ThemeData theme) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Types'),
            selected: _selectedType == null,
            onSelected: (_) => setState(() => _selectedType = null),
          ),
          const SizedBox(width: 8),
          ...ReminderType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type.displayName),
                selected: _selectedType == type,
                onSelected: (_) => setState(() => _selectedType = type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    final remindersAsync = ref.watch(activeRemindersProvider);
    final allRemindersAsync = ref.watch(remindersProvider);

    // When a type filter is selected, also check all reminders for that type
    // so users can see type-specific reminders even if they aren't in the
    // "active" (within advance notice) window yet
    if (_selectedType != null) {
      return allRemindersAsync.when(
        data: (allReminders) {
          // Show pending reminders of the selected type (including upcoming)
          final typeFiltered = allReminders
              .where(
                (r) =>
                    r.type == _selectedType &&
                    r.status == ReminderStatus.pending,
              )
              .toList();

          if (typeFiltered.isEmpty) {
            return _buildEmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No ${_selectedType!.displayName} Reminders',
              subtitle: 'No pending reminders of this type',
            );
          }
          return _buildReminderList(typeFiltered);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      );
    }

    return remindersAsync.when(
      data: (reminders) {
        final filtered = _filterByType(reminders);
        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'No Active Reminders',
            subtitle: 'You\'re all caught up!',
          );
        }
        return _buildReminderList(filtered);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildUpcomingTab() {
    final remindersAsync = ref.watch(remindersProvider);

    return remindersAsync.when(
      data: (reminders) {
        // When a type filter is selected, show all pending reminders of that type
        // (including overdue ones) so users can see all reminders of a specific type
        if (_selectedType != null) {
          final typeFiltered = reminders
              .where(
                (r) =>
                    r.type == _selectedType &&
                    r.status == ReminderStatus.pending,
              )
              .toList();

          if (typeFiltered.isEmpty) {
            return _buildEmptyState(
              icon: Icons.event_available,
              title: 'No ${_selectedType!.displayName} Reminders',
              subtitle: 'No pending reminders of this type',
            );
          }
          return _buildReminderList(typeFiltered);
        }

        // Default: Filter to show only future reminders (due today or later)
        final upcoming = reminders
            .where(
              (r) => r.daysUntilDue >= 0 && r.status == ReminderStatus.pending,
            )
            .toList();

        if (upcoming.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_available,
            title: 'No Upcoming Reminders',
            subtitle: 'No reminders scheduled',
          );
        }
        return _buildReminderList(upcoming);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSystemNotificationsTab() {
    final notificationsAsync = ref.watch(adminNotificationsProvider);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return _buildEmptyState(
            icon: Icons.notifications_active_outlined,
            title: 'No System Notifications',
            subtitle:
                'System notifications like team member joins will appear here',
          );
        }
        return _buildSystemNotificationList(notifications);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSystemNotificationList(List<AdminNotification> notifications) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Mark all as read button
                if (notifications.any((n) => !n.read))
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final user = ref.read(currentUserProvider).value;
                            if (user != null) {
                              await markAllAdminNotificationsAsRead(user.id);
                            }
                          },
                          icon: const Icon(Icons.done_all, size: 18),
                          label: const Text('Mark all as read'),
                        ),
                      ],
                    ),
                  ),
                // Notification list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildSystemNotificationTile(notification);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemNotificationTile(AdminNotification notification) {
    final theme = Theme.of(context);
    final isUnread = !notification.read;

    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'team_member_joined':
        icon = Icons.person_add;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        iconColor = theme.colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isUnread
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Row(
          children: [
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTimeAgo(notification.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Mark as read',
                onPressed: () => markAdminNotificationAsRead(notification.id),
              )
            : null,
        onTap: () {
          if (isUnread) {
            markAdminNotificationAsRead(notification.id);
          }
          // Could navigate to team management or show details
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildAllTab() {
    final remindersAsync = ref.watch(remindersProvider);

    return remindersAsync.when(
      data: (reminders) {
        // When a type filter is selected, show all reminders of that type
        // (including completed/dismissed) so users see full history
        if (_selectedType != null) {
          final typeFiltered = reminders
              .where((r) => r.type == _selectedType)
              .toList();

          if (typeFiltered.isEmpty) {
            return _buildEmptyState(
              icon: Icons.notifications_none,
              title: 'No ${_selectedType!.displayName} Reminders',
              subtitle: 'No reminders of this type',
            );
          }
          return _buildReminderList(typeFiltered);
        }

        // Default: show all reminders
        if (reminders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.notifications_none,
            title: 'No Reminders',
            subtitle: 'Create your first reminder to get started',
          );
        }
        return _buildReminderList(reminders);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  List<Reminder> _filterByType(List<Reminder> reminders) {
    if (_selectedType == null) return reminders;
    return reminders.where((r) => r.type == _selectedType).toList();
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderList(List<Reminder> reminders) {
    // Group by date
    final grouped = <String, List<Reminder>>{};

    for (final reminder in reminders) {
      final key = _getDateGroupKey(reminder);
      grouped.putIfAbsent(key, () => []).add(reminder);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > Breakpoints.tablet;
        final columns = constraints.maxWidth > Breakpoints.desktop ? 3 : 2;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final entry = grouped.entries.elementAt(index);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isWide)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.8,
                        ),
                        itemCount: entry.value.length,
                        itemBuilder: (context, idx) {
                          final r = entry.value[idx];
                          return _ReminderCard(
                            reminder: r,
                            onComplete: () => _completeReminder(r),
                            onDismiss: () => _dismissReminder(r),
                            onSnooze: () => _showSnoozeDialog(r),
                            onTap: () => _navigateToSource(r),
                          );
                        },
                      )
                    else
                      ...entry.value.map(
                        (r) => _ReminderCard(
                          reminder: r,
                          onComplete: () => _completeReminder(r),
                          onDismiss: () => _dismissReminder(r),
                          onSnooze: () => _showSnoozeDialog(r),
                          onTap: () => _navigateToSource(r),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _getDateGroupKey(Reminder reminder) {
    final days = reminder.daysUntilDue;
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days <= 7) return 'This Week';
    if (days <= 30) return 'This Month';
    return 'Later';
  }

  Future<void> _syncReminders() async {
    final farmId = ref.read(activeFarmIdProvider);
    if (farmId == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Syncing reminders...'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      final reminderService = ref.read(reminderServiceProvider);
      await reminderService.syncAllReminders(farmId);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Reminders synced successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error syncing: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _completeReminder(Reminder reminder) async {
    final repository = ref.read(reminderRepositoryProvider);
    await repository.completeReminder(reminder.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.task_alt, color: Colors.white),
              SizedBox(width: 8),
              Text('Reminder completed'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _dismissReminder(Reminder reminder) async {
    final repository = ref.read(reminderRepositoryProvider);
    await repository.dismissReminder(reminder.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.notifications_off, color: Colors.white),
              SizedBox(width: 8),
              Text('Reminder dismissed'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showSnoozeDialog(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('1 hour'),
              onTap: () => _snoozeReminder(reminder, const Duration(hours: 1)),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('3 hours'),
              onTap: () => _snoozeReminder(reminder, const Duration(hours: 3)),
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Tomorrow'),
              onTap: () => _snoozeReminder(reminder, const Duration(days: 1)),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Next week'),
              onTap: () => _snoozeReminder(reminder, const Duration(days: 7)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _snoozeReminder(Reminder reminder, Duration duration) async {
    Navigator.pop(context);
    final repository = ref.read(reminderRepositoryProvider);
    await repository.snoozeReminder(reminder.id, duration);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder snoozed')));
    }
  }

  Future<void> _navigateToSource(Reminder reminder) async {
    if (reminder.animalId != null) {
      final animalAsync = await ref.read(
        animalByIdProvider(reminder.animalId!).future,
      );
      if (animalAsync != null && mounted) {
        coordinator.push(AnimalDetailRoute(animal: animalAsync));
      }
    }
  }

  void _showAddReminderDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    ReminderType selectedType = ReminderType.custom;
    ReminderPriority selectedPriority = ReminderPriority.medium;
    bool isCreating = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primaryContainer,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_alert,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Reminder',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Create a custom reminder',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: isCreating
                              ? null
                              : () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Title',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: titleController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Check vaccination schedule',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.title,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Description (optional)',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: descriptionController,
                            decoration: InputDecoration(
                              hintText: 'Add more details...',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.notes,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                              ),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Reminder Type',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ReminderType.values.map((type) {
                              final isSelected = selectedType == type;
                              final typeColor = _getTypeColor(type);

                              return InkWell(
                                onTap: () =>
                                    setState(() => selectedType = type),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? typeColor.withValues(alpha: 0.15)
                                        : colorScheme.surfaceContainerHighest
                                              .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? typeColor
                                          : colorScheme.outlineVariant
                                                .withValues(alpha: 0.5),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getTypeIcon(type),
                                        color: typeColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        type.displayName,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? typeColor
                                                  : colorScheme.onSurface,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Priority',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: ReminderPriority.values.map((priority) {
                              final isSelected = selectedPriority == priority;
                              final priorityColor = _getPriorityColor(priority);

                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: priority != ReminderPriority.urgent
                                        ? 8
                                        : 0,
                                  ),
                                  child: InkWell(
                                    onTap: () => setState(
                                      () => selectedPriority = priority,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? priorityColor.withValues(
                                                alpha: 0.15,
                                              )
                                            : colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? priorityColor
                                              : colorScheme.outlineVariant
                                                    .withValues(alpha: 0.5),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.flag,
                                            color: priorityColor,
                                            size: 18,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            priority.displayName,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                  color: isSelected
                                                      ? priorityColor
                                                      : colorScheme.onSurface,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Due Date',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() => selectedDate = date);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      color: Colors.teal,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatDate(selectedDate),
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          _getDaysUntil(selectedDate),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit_calendar,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Error message
                          if (errorText != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      errorText!,
                                      style: TextStyle(
                                        color: colorScheme.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Footer with actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isCreating
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: isCreating
                                ? null
                                : () async {
                                    if (titleController.text.trim().isEmpty) {
                                      setState(() {
                                        errorText = 'Please enter a title';
                                      });
                                      return;
                                    }

                                    final farmId = ref.read(
                                      activeFarmIdProvider,
                                    );
                                    if (farmId == null) {
                                      setState(() {
                                        errorText = 'No farm selected';
                                      });
                                      return;
                                    }

                                    setState(() {
                                      isCreating = true;
                                      errorText = null;
                                    });

                                    try {
                                      final repository = ref.read(
                                        reminderRepositoryProvider,
                                      );
                                      final now = DateTime.now();

                                      await repository.createReminder(
                                        Reminder(
                                          id: '',
                                          farmId: farmId,
                                          type: selectedType,
                                          title: titleController.text.trim(),
                                          description:
                                              descriptionController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : descriptionController.text
                                                    .trim(),
                                          dueDate: selectedDate,
                                          priority: selectedPriority,
                                          createdAt: now,
                                          updatedAt: now,
                                        ),
                                      );

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Reminder created'),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        setState(() {
                                          isCreating = false;
                                          errorText =
                                              'Failed to create reminder: $e';
                                        });
                                      }
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: isCreating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add_alert, size: 18),
                            label: Text(
                              isCreating ? 'Creating...' : 'Add Reminder',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getTypeColor(ReminderType type) {
    switch (type) {
      case ReminderType.breeding:
        return Colors.pink;
      case ReminderType.health:
        return Colors.red;
      case ReminderType.weightCheck:
        return Colors.blue;
      case ReminderType.custom:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.breeding:
        return Icons.favorite;
      case ReminderType.health:
        return Icons.medical_services;
      case ReminderType.weightCheck:
        return Icons.monitor_weight;
      case ReminderType.custom:
        return Icons.notifications;
    }
  }

  Color _getPriorityColor(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return Colors.grey;
      case ReminderPriority.medium:
        return Colors.blue;
      case ReminderPriority.high:
        return Colors.orange;
      case ReminderPriority.urgent:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getDaysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final days = target.difference(today).inDays;

    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days < 7) return 'In $days days';
    if (days < 30) return 'In ${(days / 7).floor()} weeks';
    return 'In ${(days / 30).floor()} months';
  }

  void _showSettingsDialog(BuildContext context) {
    // Always fetch fresh settings from the database before opening dialog
    final farmId = ref.read(activeFarmIdProvider);
    if (farmId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No farm selected')));
      return;
    }

    // Show loading indicator while fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch fresh settings from repository
    ref
        .read(reminderRepositoryProvider)
        .getSettings(farmId)
        .then((settings) {
          Navigator.pop(context); // Close loading
          showDialog(
            context: context,
            builder: (context) => _ReminderSettingsDialog(settings: settings),
          );
        })
        .catchError((e) {
          Navigator.pop(context); // Close loading
          // Show dialog with default settings on error
          showDialog(
            context: context,
            builder: (context) => _ReminderSettingsDialog(
              settings: ReminderSettings(farmId: farmId),
            ),
          );
        });
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onComplete;
  final VoidCallback onDismiss;
  final VoidCallback onSnooze;
  final VoidCallback onTap;

  const _ReminderCard({
    required this.reminder,
    required this.onComplete,
    required this.onDismiss,
    required this.onSnooze,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = reminder.isOverdue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isOverdue
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildTypeIcon(theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reminder.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (reminder.animalTagId != null)
                          Text(
                            'Animal: ${reminder.animalTagId}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildPriorityBadge(theme),
                ],
              ),
              if (reminder.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  reminder.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isOverdue ? Icons.warning_amber : Icons.schedule,
                    size: 16,
                    color: isOverdue
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    reminder.dueDateText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOverdue
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isOverdue ? FontWeight.bold : null,
                    ),
                  ),
                  const Spacer(),
                  // Action buttons
                  IconButton(
                    icon: const Icon(Icons.snooze, size: 20),
                    onPressed: onSnooze,
                    tooltip: 'Snooze',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onDismiss,
                    tooltip: 'Dismiss',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    onPressed: onComplete,
                    tooltip: 'Mark Complete',
                    visualDensity: VisualDensity.compact,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(ThemeData theme) {
    IconData icon;
    Color color;

    switch (reminder.type) {
      case ReminderType.breeding:
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      case ReminderType.health:
        icon = Icons.medical_services;
        color = Colors.red;
        break;
      case ReminderType.weightCheck:
        icon = Icons.scale;
        color = Colors.blue;
        break;
      case ReminderType.custom:
        icon = Icons.notifications;
        color = theme.colorScheme.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildPriorityBadge(ThemeData theme) {
    Color color;
    switch (reminder.priority) {
      case ReminderPriority.urgent:
        color = Colors.red;
        break;
      case ReminderPriority.high:
        color = Colors.orange;
        break;
      case ReminderPriority.medium:
        color = Colors.blue;
        break;
      case ReminderPriority.low:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        reminder.priority.displayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ReminderSettingsDialog extends ConsumerStatefulWidget {
  final ReminderSettings settings;

  const _ReminderSettingsDialog({required this.settings});

  @override
  ConsumerState<_ReminderSettingsDialog> createState() =>
      _ReminderSettingsDialogState();
}

class _ReminderSettingsDialogState
    extends ConsumerState<_ReminderSettingsDialog> {
  late bool _breedingEnabled;
  late bool _healthEnabled;
  late bool _weightCheckEnabled;
  late int _advanceNoticeDays;
  late int _weightCheckInterval;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _breedingEnabled = widget.settings.breedingRemindersEnabled;
    _healthEnabled = widget.settings.healthRemindersEnabled;
    _weightCheckEnabled = widget.settings.weightCheckRemindersEnabled;
    _advanceNoticeDays = widget.settings.defaultAdvanceNoticeDays;
    _weightCheckInterval = widget.settings.weightCheckIntervalDays;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorScheme.primary, colorScheme.primaryContainer],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Configure your notification preferences',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reminder Types Section
                    _buildSectionHeader(
                      theme,
                      icon: Icons.notifications_active,
                      iconColor: Colors.orange,
                      title: 'Reminder Types',
                      subtitle:
                          'Enable or disable specific reminder categories',
                    ),
                    const SizedBox(height: 12),
                    _buildToggleCard(
                      theme: theme,
                      icon: Icons.favorite,
                      iconColor: Colors.pink,
                      title: 'Breeding Reminders',
                      subtitle: 'Heat cycles, expected births',
                      value: _breedingEnabled,
                      onChanged: (value) =>
                          setState(() => _breedingEnabled = value),
                    ),
                    const SizedBox(height: 8),
                    _buildToggleCard(
                      theme: theme,
                      icon: Icons.medical_services,
                      iconColor: Colors.red,
                      title: 'Health Reminders',
                      subtitle: 'Vaccinations, medications, follow-ups',
                      value: _healthEnabled,
                      onChanged: (value) =>
                          setState(() => _healthEnabled = value),
                    ),
                    const SizedBox(height: 8),
                    _buildToggleCard(
                      theme: theme,
                      icon: Icons.monitor_weight,
                      iconColor: Colors.blue,
                      title: 'Weight Check Reminders',
                      subtitle: 'Regular weight monitoring',
                      value: _weightCheckEnabled,
                      onChanged: (value) =>
                          setState(() => _weightCheckEnabled = value),
                    ),

                    const SizedBox(height: 24),

                    // Timing Section
                    _buildSectionHeader(
                      theme,
                      icon: Icons.schedule,
                      iconColor: Colors.purple,
                      title: 'Timing',
                      subtitle: 'Configure when reminders appear',
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownCard(
                      theme: theme,
                      icon: Icons.notifications,
                      iconColor: Colors.teal,
                      title: 'Advance Notice',
                      subtitle: 'Days before due date',
                      value: _advanceNoticeDays,
                      items: [1, 2, 3, 5, 7, 14],
                      itemLabel: (v) => '$v days',
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _advanceNoticeDays = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDropdownCard(
                      theme: theme,
                      icon: Icons.repeat,
                      iconColor: Colors.indigo,
                      title: 'Weight Check Interval',
                      subtitle: 'How often to remind',
                      value: _weightCheckInterval,
                      items: [3, 5, 7, 10, 14, 21, 30],
                      itemLabel: (v) => '$v days',
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _weightCheckInterval = value);
                        }
                      },
                    ),

                    // Error message
                    if (_errorText != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer with actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? iconColor.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? iconColor.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDropdownCard<T>({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<T>(
              value: value,
              underline: const SizedBox(),
              isDense: true,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final repository = ref.read(reminderRepositoryProvider);
      final updatedSettings = widget.settings.copyWith(
        breedingRemindersEnabled: _breedingEnabled,
        healthRemindersEnabled: _healthEnabled,
        weightCheckRemindersEnabled: _weightCheckEnabled,
        defaultAdvanceNoticeDays: _advanceNoticeDays,
        weightCheckIntervalDays: _weightCheckInterval,
      );

      await repository.saveSettings(updatedSettings);

      // Invalidate the provider to refresh the data
      ref.invalidate(reminderSettingsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Settings saved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorText = 'Failed to save settings: ${e.toString()}';
        });
      }
    }
  }
}
