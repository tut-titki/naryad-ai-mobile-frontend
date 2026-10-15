import 'package:flutter/material.dart';
import '../../../shared/widgets/employee_profile_layout.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/api/api_services.dart';
import '../../../l10n/ui_localization.dart';
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
    return EmployeeProfileLayout(
      name: name,
      initials: initials,
      subtitle: uiText(context, 'Мастер смены'),
      onShift: onShift,
      statusLabel: user == null ? '—' : null,
      showAccountActions: session != null,
      showLogout: session != null,
      loggingOut: widget.loggingOut || _confirmingLogout,
      onLogout: _confirmLogout,
      identityDetails: _brigades != null || (user?.grade ?? 0) > 0
          ? Row(
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
                            ProfileIdentityDetail(
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
                    child: ProfileIdentityDetail(
                      LucideIcons.award,
                      uiText(context, 'Разряд'),
                      '${user!.grade}',
                    ),
                  ),
              ],
            )
          : null,
    );
  }
}
