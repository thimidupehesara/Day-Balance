import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_page.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../timer/presentation/today_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static TimeOfDay? _parseTime(String? value) {
    final parts = value?.split(':');
    if (parts == null || parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        hour < 0 ||
        hour > 23 ||
        minute == null ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _duration(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '${remainder}m';
    return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can log back in any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    ref.invalidate(todayControllerProvider);
    ref.invalidate(timerNotificationsProvider);
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth.user == null || today.user?.id == auth.user?.id
        ? today.user ?? auth.user
        : auth.user;
    final name = user?.displayName?.trim() ?? '';
    final initials = name.isEmpty
        ? ''
        : name
              .split(RegExp(r'\s+'))
              .take(2)
              .map((word) => word.characters.first.toUpperCase())
              .join();
    final wake = _parseTime(user?.wakeTime);
    final bed = _parseTime(user?.bedtime);
    final awakeMinutes = wake != null && bed != null
        ? (bed.hour * 60 + bed.minute - wake.hour * 60 - wake.minute) % 1440
        : null;
    final schedule = wake != null && bed != null && awakeMinutes != null
        ? '${wake.format(context)} – ${bed.format(context)} · ${_duration(awakeMinutes == 0 ? 1440 : awakeMinutes)} awake'
        : 'No schedule to show';
    final routine = user?.routineMinutes;
    final notifications = ref.watch(timerNotificationsProvider);

    return AppPage(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Row(
                  children: [
                    AppBackButton(onPressed: () => context.go('/today')),
                    const Expanded(
                      child: Text('Your profile', style: AppTextStyles.heading),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ProfileCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.primarySage,
                            foregroundColor: AppColors.textOnPrimary,
                            child: initials.isEmpty
                                ? const Icon(Icons.person_outline)
                                : FittedBox(child: Text(initials)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isEmpty ? 'Day-Balance account' : name,
                                  style: AppTextStyles.title,
                                ),
                                if (user != null)
                                  Text(
                                    user.email,
                                    style: AppTextStyles.caption12,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('YOUR DAY', style: AppTextStyles.eyebrow),
                const SizedBox(height: 10),
                _ProfileCard(
                  children: [
                    _ProfileRow(
                      icon: Icons.schedule,
                      title: 'Schedule',
                      detail: schedule,
                    ),
                    _ProfileRow(
                      icon: Icons.wb_twilight,
                      title: 'Routines',
                      detail: routine == null
                          ? 'No routine time to show'
                          : '${_duration(routine)} set aside each day',
                    ),
                    _ProfileRow(
                      icon: Icons.category_outlined,
                      title: 'Categories',
                      detail: today.items.isEmpty
                          ? 'No categories in today’s plan'
                          : '${today.items.length} in today’s plan',
                    ),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.setupAccent,
                      ),
                      title: const Text('Timer notifications'),
                      subtitle: const Text(
                        'Alert when time is up · this session',
                      ),
                      value: notifications,
                      onChanged: (enabled) => ref
                          .read(timerNotificationsProvider.notifier)
                          .setEnabled(enabled),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('ACCOUNT', style: AppTextStyles.eyebrow),
                const SizedBox(height: 10),
                _ProfileCard(
                  children: [
                    const _ProfileRow(
                      icon: Icons.lock_outline,
                      title: 'Change password',
                      detail: 'Coming later',
                    ),
                    _ProfileRow(
                      icon: Icons.logout,
                      title: 'Log out',
                      onTap: user == null || auth.isLoading
                          ? null
                          : () => _logout(context, ref),
                    ),
                    const _ProfileRow(
                      icon: Icons.delete_outline,
                      title: 'Delete account',
                      detail: 'Coming later',
                      color: AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Day-Balance · Version 1.0',
                  style: AppTextStyles.caption12,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.paper,
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/today');
          if (index == 1) context.go('/summary');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            label: 'Today',
          ),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.divider),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    this.detail,
    this.onTap,
    this.color = AppColors.text,
  });
  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.setupAccent),
    title: Text(title, style: TextStyle(color: color)),
    subtitle: detail == null
        ? null
        : Text(detail!, style: AppTextStyles.caption12),
    trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
