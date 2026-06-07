import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_screen.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'edit_profile_page.dart';
import 'models/user_profile.dart';
import 'orders_page.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'widgets/initials_avatar.dart';
import 'wishlist_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  late final Stream<UserProfile> _profileStream = _profileService
      .currentUserProfileStream();

  Future<void> _openEditProfile(UserProfile profile) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(profile: profile)),
    );
  }

  void _openOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrdersPage()),
    );
  }

  void _openWishlist() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            foregroundColor: AppColors.backgroundDark,
            title: Text(
              'Wishlist',
              style: AppTextStyles.label.copyWith(
                color: AppColors.backgroundDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: const WishlistPage(),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  String _valueOrEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Not added yet' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<UserProfile>(
        stream: _profileStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _ProfileStateMessage(
              title: 'Unable to load profile',
              message: 'Please try again in a moment.',
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!;
          final authEmail =
              FirebaseAuth.instance.currentUser?.email ?? profile.email;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.md +
                  kBottomNavigationBarHeight +
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Profile',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.backgroundDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ProfileSummary(
                      nameInitialsSource: profile.name,
                      name: _valueOrEmpty(profile.name),
                      email: authEmail,
                      phoneNumber: _valueOrEmpty(profile.phoneNumber),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _InfoSection(
                      title: 'Address Information',
                      rows: [
                        _InfoRowData(
                          label: 'Address',
                          value: _valueOrEmpty(profile.address),
                        ),
                        _InfoRowData(
                          label: 'City',
                          value: _valueOrEmpty(profile.city),
                        ),
                        _InfoRowData(
                          label: 'Postal Code',
                          value: _valueOrEmpty(profile.postalCode),
                        ),
                        _InfoRowData(
                          label: 'Country',
                          value: _valueOrEmpty(profile.country),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ActionSection(
                      onEditProfile: () => _openEditProfile(profile),
                      onOrders: _openOrders,
                      onWishlist: _openWishlist,
                      onLogout: _logout,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.nameInitialsSource,
    required this.name,
    required this.email,
    required this.phoneNumber,
  });

  final String nameInitialsSource;
  final String name;
  final String email;
  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _sectionDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InitialsAvatar(name: nameInitialsSource, size: 88),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.backgroundDark,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InlineValue(icon: Icons.mail_outline, text: email),
          const SizedBox(height: AppSpacing.xs),
          _InlineValue(icon: Icons.phone_outlined, text: phoneNumber),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _sectionDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.backgroundDark,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...rows.map((row) => _InfoRow(row: row)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.row});

  final _InfoRowData row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              row.label,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              row.value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.onEditProfile,
    required this.onOrders,
    required this.onWishlist,
    required this.onLogout,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onOrders;
  final VoidCallback onWishlist;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: _sectionDecoration(),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: onEditProfile,
          ),
          _ActionTile(
            icon: Icons.receipt_long_outlined,
            label: 'My Orders',
            onTap: onOrders,
          ),
          _ActionTile(
            icon: Icons.favorite_border,
            label: 'Wishlist',
            onTap: onWishlist,
          ),
          _ActionTile(
            icon: Icons.logout,
            label: 'Logout',
            destructive: true,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.backgroundDark;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: destructive
          ? null
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

class _InlineValue extends StatelessWidget {
  const _InlineValue({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _InfoRowData {
  const _InfoRowData({required this.label, required this.value});

  final String label;
  final String value;
}

class _ProfileStateMessage extends StatelessWidget {
  const _ProfileStateMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _sectionDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
