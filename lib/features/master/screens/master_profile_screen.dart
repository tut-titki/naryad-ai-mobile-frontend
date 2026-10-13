import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/api/api_services.dart';
import '../../../l10n/language_switcher.dart';
import '../../../l10n/ui_localization.dart';
import '../../auth/screens/change_password_screen.dart';
import '../../auth/widgets/auth_scope.dart';
import '../../auth/widgets/logout_confirmation_sheet.dart';
import '../../orders/data/references_api.dart';
import '../../../shared/widgets/backend_refresh_view.dart';
import '../../../shared/widgets/backend_section.dart';

class MasterProfileScreen extends StatefulWidget {
  const MasterProfileScreen({
    super.key,
    required this.api,
    required this.onLogout,
    required this.loggingOut,
  });
  final ApiServices api;
  final VoidCallback onLogout;
  final bool loggingOut;
  @override
  State<MasterProfileScreen> createState() => _MasterProfileScreenState();
}

class _MasterProfileScreenState extends State<MasterProfileScreen> {
  static const _blue = Color(0xFF01408B);
  static const _gradient = AppColors.profileHeaderGradient;
  int? _brigadeId;
  Future<List<BrigadeReference>>? _brigades;
  BackendRefreshController? _refreshController;
  bool _confirmingLogout = false;

  Future<void> _confirmLogout() async {
    if (_confirmingLogout || widget.loggingOut) return;
    setState(() => _confirmingLogout = true);
    try {
      final confirmed = await showLogoutConfirmation(context);
      if (mounted && confirmed && !widget.loggingOut) widget.onLogout();
    } finally {
      if (mounted) setState(() => _confirmingLogout = false);
    }
  }

  Future<void> _refreshProfile() async {
    final session = AuthScope.maybeOf(context);
    try {
      await session?.refreshUser();
      if (!mounted) return;
      _brigadeId = session?.user?.brigadeId;
      final future = _brigadeId == null
          ? null
          : widget.api.references.getBrigades(refresh: true);
      setState(() => _brigades = future);
      await future;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(backendError(context, error))));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = BackendRefreshScope.maybeOf(context);
    if (controller != _refreshController) {
      _refreshController?.unregister(_refreshProfile);
      _refreshController = controller;
      _refreshController?.register(_refreshProfile);
    }
    final brigadeId = AuthScope.maybeOf(context)?.user?.brigadeId;
    if (_brigadeId != brigadeId) {
      _brigadeId = brigadeId;
      _brigades = brigadeId == null
          ? null
          : widget.api.references.getBrigades();
    }
  }

  @override
  void dispose() {
    _refreshController?.unregister(_refreshProfile);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.maybeOf(context);
    final user = session?.user;
    final name = user?.fullName ?? uiText(context, 'Мастер смены');
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
    final onShift = user?.isOnShift ?? false;
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
                          uiText(context, 'Мастер смены'),
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
                                  user == null
                                      ? '—'
                                      : uiText(
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
              if (_brigades != null || (user?.grade ?? 0) > 0) ...[
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_brigades != null)
                      Expanded(
                        child: FutureBuilder<List<BrigadeReference>>(
                          future: _brigades,
                          builder: (context, snapshot) {
                            final brigade = snapshot.data
                                ?.where((brigade) => brigade.id == _brigadeId)
                                .firstOrNull;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _identityDetail(
                                  LucideIcons.users,
                                  uiText(context, 'Бригада'),
                                  brigade == null
                                      ? '—'
                                      : uiText(context, brigade.name),
                                ),
                                if (snapshot.hasError)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => setState(
                                      () => _brigades = widget.api.references
                                          .getBrigades(),
                                    ),
                                    icon: const Icon(Icons.replay, size: 18),
                                    label: Text(uiText(context, 'Повторить')),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    if (_brigades != null && (user?.grade ?? 0) > 0)
                      const SizedBox(width: 10),
                    if ((user?.grade ?? 0) > 0)
                      Expanded(
                        child: _identityDetail(
                          LucideIcons.award,
                          uiText(context, 'Разряд'),
                          '${user!.grade}',
                        ),
                      ),
                  ],
                ),
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
                        if (session != null) ...[
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
                  if (session != null) ...[
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
                      onPressed: widget.loggingOut || _confirmingLogout
                          ? null
                          : _confirmLogout,
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

  Widget _identityDetail(IconData icon, String label, String value) =>
      Container(
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFC8DDF5),
                    ),
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
