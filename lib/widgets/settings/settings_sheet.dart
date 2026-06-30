import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../screens/appearance_screen.dart';
import '../../screens/labels_screen.dart';
import '../../screens/notifications_settings_screen.dart';
import '../../screens/profile_screen.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../app_sheet.dart';
import '../pressable.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx, rootNavigator: true).pop(),
        child: const SettingsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final bottomClearance = view.padding.bottom / view.devicePixelRatio + AppSpacing.lg;

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.68],
      builder: (_, ctrl) => GestureDetector(
        onTap: () {},
        child: Material(
          color: AppColors.surface,
          borderRadius: AppRadius.sheetTop,
          child: Column(
            children: [
              const AppSheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Configurações', style: appSheetTitleStyle(context)),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    bottomClearance,
                  ),
                  children: [
                    _ProfileCard(onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                      );
                    }),
                    const SizedBox(height: AppSpacing.lg),
                    _settingSection('Preferências'),
                    _settingsCard([
                      _SettingItem(
                        hugeIcon: HugeIcons.strokeRoundedNotification01,
                        label: 'Notificações',
                        onTap: () {
                          showAppSheet(
                            context: context,
                            title: 'Notificações',
                            scrollable: true,
                            child: const NotificationsSettingsContent(),
                          );
                        },
                      ),
                      _SettingItem(
                        hugeIcon: HugeIcons.strokeRoundedPaintBoard,
                        label: 'Aparência',
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                          );
                        },
                      ),
                      _SettingItem(
                        hugeIcon: HugeIcons.strokeRoundedGlobe02,
                        label: 'Idioma',
                        onTap: () {},
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.lg),
                    _settingSection('Organização'),
                    _settingsCard([
                      _SettingItem(
                        hugeIcon: HugeIcons.strokeRoundedTag01,
                        label: 'Gerenciar Etiquetas',
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(builder: (_) => const LabelsScreen()),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                          AuthService().signOut();
                        },
                        icon: const HugeIcon(icon: HugeIcons.strokeRoundedLogout01, size: 16),
                        label: const Text('Sair da conta'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.priorityHigh,
                          side: const BorderSide(color: AppColors.priorityHigh),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md - 2),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _settingSection(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  static Widget _settingsCard(List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(height: 1, indent: 46, color: AppColors.surface),
          ],
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final email = user?.email ?? '';
    final meta = user?.userMetadata ?? {};
    final apelido = (meta['apelido'] as String? ?? '').trim();
    final nome = (meta['nome'] as String? ?? '').trim();
    final avatarPath = meta['avatar_url'] as String?;
    final hasPhoto = avatarPath != null && avatarPath.startsWith('http');
    final displayName = apelido.isNotEmpty
        ? apelido
        : nome.isNotEmpty
            ? nome
            : email
                .split('@')
                .first
                .split('.')
                .map((s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1))
                .join(' ');
    final display = apelido.isNotEmpty ? apelido : nome.isNotEmpty ? nome : email.split('@').first;
    final parts = display.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : display.substring(0, display.length.clamp(0, 2)).toUpperCase();

    return Semantics(
      button: true,
      label: 'Perfil, $displayName',
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md - 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.15),
                  image: hasPhoto
                      ? DecorationImage(image: NetworkImage(avatarPath), fit: BoxFit.cover)
                      : null,
                ),
                child: hasPhoto
                    ? null
                    : Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 18, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final List<List<dynamic>> hugeIcon;
  final String label;
  final VoidCallback? onTap;
  const _SettingItem({required this.hugeIcon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 2, vertical: AppSpacing.md - 1),
          child: Row(
            children: [
              HugeIcon(icon: hugeIcon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 16, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
