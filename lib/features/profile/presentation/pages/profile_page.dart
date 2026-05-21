import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(profileStatsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    ref.listen(profileNotifierProvider, (_, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(profileNotifierProvider.notifier).clearStatus();
      }
      if (next.hasError && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(profileNotifierProvider.notifier).clearStatus();
      }
    });

    if (user == null) {
      return const _UnauthenticatedView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditDialog(context, ref, user.displayName),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          _AvatarSection(
            displayName: user.displayName,
            email: user.email,
          ),
          const SizedBox(height: 24),
          _StatsRow(
            orderCount: stats.orderCount,
            favoriteCount: stats.favoriteCount,
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'Account'),
          _ProfileTile(
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            onTap: () => context.go(AppRoutes.orders),
          ),
          _ProfileTile(
            icon: Icons.favorite_outline,
            title: 'My Favorites',
            onTap: () => context.go(AppRoutes.favorites),
          ),
          const SizedBox(height: 8),
          _SectionLabel(label: 'Preferences'),
          SwitchListTile(
            secondary: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            ),
            title: const Text('Dark Mode'),
            value: isDark,
            onChanged: (_) =>
                ref.read(themeModeProvider.notifier).toggle(),
          ),
          const SizedBox(height: 8),
          _SectionLabel(label: 'Security'),
          _ProfileTile(
            icon: Icons.lock_reset_outlined,
            title: 'Reset Password',
            onTap: () => _showResetPasswordDialog(context, ref, user.email),
          ),
          const SizedBox(height: 8),
          _SectionLabel(label: 'Session'),
          _ProfileTile(
            icon: Icons.logout,
            title: 'Sign Out',
            iconColor: Theme.of(context).colorScheme.error,
            titleColor: Theme.of(context).colorScheme.error,
            onTap: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
      BuildContext context,
      WidgetRef ref,
      String? currentName,
      ) async {
    final controller = TextEditingController(text: currentName ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Display name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref
                    .read(profileNotifierProvider.notifier)
                    .updateDisplayName(controller.text);
                ctx.pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _showResetPasswordDialog(
      BuildContext context,
      WidgetRef ref,
      String? email,
      ) async {
    if (email == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'A password reset link will be sent to $email.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(authNotifierProvider.notifier)
          .sendPasswordReset(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(profileNotifierProvider.notifier).signOut();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.displayName,
    required this.email,
  });

  final String? displayName;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initials = _initials(displayName ?? email);

    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            initials,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          displayName ?? 'No Name',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  String _initials(String? value) {
    if (value == null || value.isEmpty) return '?';
    final parts = value.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return value[0].toUpperCase();
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.orderCount,
    required this.favoriteCount,
  });

  final int orderCount;
  final int favoriteCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.receipt_long_outlined,
              label: 'Orders',
              value: '$orderCount',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.favorite_outline,
              label: 'Favorites',
              value: '$favoriteCount',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 72,
                color: theme.colorScheme.onSurface.withOpacity(0.25),
              ),
              const SizedBox(height: 16),
              Text(
                'You are not signed in',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.login),
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}