import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user_profile.dart';
import '../../providers/admin_provider.dart';

class AdminUsers extends ConsumerStatefulWidget {
  const AdminUsers({super.key});

  @override
  ConsumerState<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends ConsumerState<AdminUsers> {
  final _searchController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _canChangeRole(UserProfile user, String currentUid) {
    if (user.uid == currentUid) return false;
    if (user.role.toLowerCase() == 'superadmin') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('User management', style: AppTextStyles.headingMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Promote trusted staff to admin and manage user roles safely.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search users',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = users
                    .where((user) {
                      if (query.isEmpty) return true;
                      return user.name.toLowerCase().contains(query) ||
                          user.email.toLowerCase().contains(query) ||
                          user.role.toLowerCase().contains(query);
                    })
                    .toList(growable: false);

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No users match the search.',
                      style: AppTextStyles.body,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final role = user.role.toLowerCase();
                    final isAdmin = role == 'admin' || role == 'superadmin';
                    final canChange = _canChangeRole(user, currentUid);
                    final targetRole = isAdmin ? 'user' : 'admin';
                    final actionLabel = isAdmin ? 'Set user' : 'Promote admin';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(user.email, style: AppTextStyles.body),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Joined: ${user.createdAt?.toLocal().toString().split(' ').first ?? 'Unknown'}',
                                    style: AppTextStyles.label,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: role == 'admin'
                                        ? AppColors.accentSoft
                                        : role == 'superadmin'
                                        ? AppColors.success.withAlpha(38)
                                        : AppColors.backgroundLight,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Text(
                                    user.role.toUpperCase(),
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextButton(
                                  onPressed: canChange && !_saving
                                      ? () => _changeRole(user, targetRole)
                                      : null,
                                  child: Text(actionLabel),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Unable to load users: ${error.toString()}',
                  style: AppTextStyles.body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeRole(UserProfile user, String targetRole) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final roleValue = ref
        .read(roleProvider)
        .maybeWhen(data: (role) => role.name, orElse: () => 'unknown');
    final isAdmin = roleValue == 'admin' || roleValue == 'superadmin';
    ref
        .read(adminDebugLogsProvider.notifier)
        .add(
          'Role change requested for ${user.uid} to $targetRole by uid=$uid role=$roleValue isAdmin=$isAdmin',
        );
    setState(() => _saving = true);
    try {
      await ref.read(adminServiceProvider).updateUserRole(user.uid, targetRole);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Role updated to $targetRole.')));
      }
    } catch (error) {
      ref
          .read(adminDebugLogsProvider.notifier)
          .add('Role update failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
