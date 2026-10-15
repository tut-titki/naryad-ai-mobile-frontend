import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/language_switcher.dart';
import '../../l10n/ui_localization.dart';
import '../../features/auth/screens/change_password_screen.dart';

/// Shared appearance for employee profiles; role-specific data stays in screens.
class EmployeeProfileLayout extends StatelessWidget {
  const EmployeeProfileLayout({
    super.key,
    required this.name,
    required this.initials,
    required this.subtitle,
    required this.onShift,
    required this.showAccountActions,
    required this.loggingOut,
    required this.onLogout,
    this.showLogout = true,
    this.statusLabel,
    this.identityDetails,
    this.beforeSettings,
  });
  final String name;
  final String initials;
  final String subtitle;
  final bool onShift;
  final bool showAccountActions;
  final bool loggingOut;
  final VoidCallback onLogout;
  final bool showLogout;
  final String? statusLabel;
  final Widget? identityDetails;
  final Widget? beforeSettings;
  static const _blue = Color(0xFF01408B);
  static const _gradient = AppColors.profileHeaderGradient;
  @override
  Widget build(BuildContext context) {
    final statusColor = onShift
        ? const Color(0xFF15803D)
        : const Color(0xFF7A8597);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: const BoxDecoration(gradient: _gradient),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.white,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFC8DDF5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: onShift
                                ? const Color(0xFFDDF5E7)
                                : const Color(0xFFE8EDF4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.circle,
                                size: 7,
                                color: statusColor,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  statusLabel ??
                                      uiText(
                                        context,
                                        onShift ? 'На смене' : 'Не на смене',
                                      ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (identityDetails != null) ...[
                const SizedBox(height: 18),
                identityDetails!,
              ],
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(gradient: _gradient),
          child: Material(
            color: const Color(0xFFF5F7FB),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?beforeSettings,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 22, 8, 10),
                    child: Text(
                      uiText(context, 'Настройки'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A8597),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        const ProfileLanguageTile(),
                        if (showAccountActions) ...[
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Color(0xFFE8EDF4),
                          ),
                          InkWell(
                            onTap: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF2FE),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(
                                      LucideIcons.lockKeyhole,
                                      size: 19,
                                      color: _blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      strings(context).changePasswordTitle,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    LucideIcons.chevronRight,
                                    size: 18,
                                    color: Color(0xFF7A8597),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showLogout) ...[
                    const SizedBox(height: 14),
                    TextButton.icon(
                      key: const ValueKey('profile-logout'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: const Color(0xFFFFECEE),
                        foregroundColor: const Color(0xFFB42318),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: loggingOut ? null : onLogout,
                      icon: const Icon(LucideIcons.logOut, size: 20),
                      label: Row(
                        children: [
                          Expanded(child: Text(uiText(context, 'Выйти'))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileIdentityDetail extends StatelessWidget {
  const ProfileIdentityDetail(this.icon, this.label, this.value, {super.key});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0x20FFFFFF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFFDDEBFF)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFFC8DDF5)),
              ),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? '—' : value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
