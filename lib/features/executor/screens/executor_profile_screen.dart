import '../models/executor_rating_period.dart';
import 'package:mineral/core/utils/enterprise_time.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/app_refresh_indicator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mineral/features/auth/screens/change_password_screen.dart';
import 'package:mineral/features/auth/widgets/auth_scope.dart';
import 'package:mineral/features/auth/widgets/logout_confirmation_sheet.dart';
import 'package:mineral/features/auth/data/auth_session.dart';
import 'package:mineral/features/executor/data/executor_repository.dart';
import 'package:mineral/features/executor/models/execution_assessment.dart';
import 'package:mineral/l10n/language_switcher.dart';
import 'package:mineral/l10n/ui_localization.dart';

class ExecutorProfileScreen extends StatefulWidget {
  const ExecutorProfileScreen({
    super.key,
    required this.store,
    required this.employeeId,
  });
  final ExecutorRepository store;
  final int employeeId;
  @override
  State<ExecutorProfileScreen> createState() => _ExecutorProfileScreenState();
}

class _ExecutorProfileScreenState extends State<ExecutorProfileScreen> {
  ExecutorRepository get store => widget.store;
  int get employeeId => widget.employeeId;
  late Future<ExecutorRating?> _ratingLoad;
  ExecutorRatingPeriod _period = const ExecutorRatingPeriod();
  DateTimeRange? _customRange;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _ratingLoad = store.loadExecutorRating(employeeId, period: _period);
  }

  Future<void> _refreshRating() async {
    final future = store.loadExecutorRating(employeeId, period: _period);
    setState(() {
      _ratingLoad = future;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error and keeps the last successful rating.
    }
  }

  String _periodLabel(BuildContext context) {
    final s = strings(context);
    return switch (_period.period) {
      'shift' => s.ratingPeriodShift,
      'day' => s.ratingPeriodDay,
      'week' => s.ratingPeriodWeek,
      'custom' => '${_date(_customRange!.start)} – ${_date(_customRange!.end)}',
      _ => s.ratingPeriodMonth,
    };
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  Future<void> _selectPeriod(String? value) async {
    if (value == null) return;
    ExecutorRatingPeriod next;
    if (value == 'custom') {
      final now = enterpriseTime(store.now);
      final today = DateTime(now.year, now.month, now.day);
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: today,
        initialDateRange: _customRange,
        helpText: strings(context).ratingPeriodCustom,
      );
      if (!mounted) return;
      if (range == null) return;
      _customRange = range;
      DateTime midnight(DateTime date) => DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).subtract(const Duration(hours: 5));
      next = ExecutorRatingPeriod.custom(
        midnight(range.start),
        midnight(range.end)
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1)),
      );
    } else {
      next = ExecutorRatingPeriod(value);
    }
    if (!mounted) return;
    setState(() {
      _period = next;
      _ratingLoad = store.loadExecutorRating(employeeId, period: next);
    });
  }

  Future<void> _showPeriodPicker() async {
    final s = strings(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  s.ratingPeriodLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final item in [
                ('shift', s.ratingPeriodShift),
                ('day', s.ratingPeriodDay),
                ('week', s.ratingPeriodWeek),
                ('month', s.ratingPeriodMonth),
                ('custom', s.ratingPeriodCustom),
              ])
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selected: _period.period == item.$1,
                  selectedColor: _blue,
                  selectedTileColor: const Color(0xFFEAF2FE),
                  leading: Icon(
                    item.$1 == 'custom'
                        ? LucideIcons.calendarDays
                        : LucideIcons.clock,
                    size: 20,
                  ),
                  title: Text(item.$2),
                  trailing: _period.period == item.$1
                      ? const Icon(LucideIcons.check, size: 20)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, item.$1),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) await _selectPeriod(selected);
  }

  Widget _periodSelector(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Material(
      color: const Color(0xFFF1F6FD),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: const ValueKey('executor-rating-period'),
        onTap: _showPeriodPicker,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.calendarDays, size: 14, color: _blue),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _periodLabel(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _blue,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronDown, size: 14, color: _blue),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  static const _blue = Color(0xFF01408B);
  static const _gradient = LinearGradient(
    colors: [Color(0xFF01408B), Color(0xFF0A57A3)],
  );

  @override
  Widget build(BuildContext context) {
    final employee = store.employee(employeeId);
    return AppRefreshIndicator(
      onRefresh: _refreshRating,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
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
                        employee.initials,
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
                            employee.name,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            uiText(context, employee.specialty),
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
                              color: employee.onShift
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
                                  color: employee.onShift
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF7A8597),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    uiText(
                                      context,
                                      employee.onShift
                                          ? 'На смене'
                                          : 'Не на смене',
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: employee.onShift
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF7A8597),
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _identityDetail(
                        LucideIcons.users,
                        uiText(context, 'Бригада'),
                        uiText(context, employee.brigade),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _identityDetail(
                        LucideIcons.award,
                        uiText(context, 'Разряд'),
                        employee.grade?.toString() ?? '—',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(gradient: _gradient),
            child: Material(
              color: const Color(0xFFF5F7FB),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<ExecutorRating?>(
                      future: _ratingLoad,
                      builder: (context, snapshot) => _rating(
                        context,
                        store.executorRating(employeeId, period: _period),
                        loading:
                            snapshot.connectionState != ConnectionState.done,
                        error: snapshot.hasError
                            ? snapshot.error is ApiException
                                  ? (snapshot.error as ApiException).message
                                  : strings(context).refreshFailed
                            : null,
                      ),
                    ),
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
                          if (AuthScope.maybeOf(context) != null) ...[
                            const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Color(0xFFE8EDF4),
                            ),
                            InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const ChangePasswordScreen(),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    _settingIcon(LucideIcons.lockKeyhole),
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
                      onPressed: _loggingOut ? null : () => _logout(context),
                      icon: const Icon(LucideIcons.logOut, size: 20),
                      label: Row(
                        children: [
                          Expanded(child: Text(uiText(context, 'Выйти'))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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

  Widget _settingIcon(IconData icon) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2FE),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Icon(icon, size: 19, color: _blue),
  );

  Widget _rating(
    BuildContext context,
    ExecutorRating? rating, {
    bool loading = false,
    String? error,
  }) {
    final s = strings(context);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE8F0FC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: rating == null ? null : () => _showRating(context, rating),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _settingIcon(LucideIcons.award),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          uiText(context, 'Мой рейтинг'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _periodSelector(context),
                        if (rating == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              loading
                                  ? '…'
                                  : uiText(context, 'Пока нет оценки'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7A8597),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (rating != null) ...[
                    const SizedBox(width: 12),
                    Tooltip(
                      message: s.ratingCalculation,
                      child: SizedBox(
                        width: 62,
                        height: 62,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: rating.score / 100,
                                strokeWidth: 3,
                                strokeCap: StrokeCap.round,
                                backgroundColor: const Color(0xFFEAF3FC),
                                color: _blue,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      rating.score.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        height: 1.1,
                                        fontWeight: FontWeight.w700,
                                        color: _blue,
                                      ),
                                    ),
                                    const Text(
                                      '/ 100',
                                      style: TextStyle(
                                        fontSize: 10,
                                        height: 1.2,
                                        color: Color(0xFF7A8597),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  uiText(context, error),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF7A8597),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRating(BuildContext context, ExecutorRating rating) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: const Color(0xFFF4F7FB),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings(sheetContext).ratingCalculation,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF172033),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          sheetContext,
                        ).closeButtonTooltip,
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(LucideIcons.x, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: _gradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _periodLabel(sheetContext),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFC8DDF5),
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${rating.score.toStringAsFixed(1)} / 100',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    height: 1.15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: rating.score / 100,
                                  minHeight: 5,
                                  color: const Color(0xFFB8DEFF),
                                  backgroundColor: const Color(0x33FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0x20FFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.award600,
                            size: 30,
                            color: Color(0xFFEAF3FC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE6EDF5)),
                    ),
                    child: _metrics(sheetContext, rating),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _ratingExplanation(sheetContext, rating),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  String _ratingNumber(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  Widget _ratingExplanation(BuildContext context, ExecutorRating rating) {
    final s = strings(context);
    final p = rating.points;
    final items = <(String, String)>[
      if (rating.quality != null && p['quality'] != null)
        (
          s.quality,
          s.ratingQualityExplanation(
            _ratingNumber(rating.quality!),
            _ratingNumber(p['quality']!),
          ),
        ),
      if (rating.onTimePercent != null && p['onTime'] != null)
        (
          s.onTime,
          s.ratingTimingExplanation(
            _ratingNumber(rating.onTimePercent!),
            _ratingNumber(p['onTime']!),
          ),
        ),
      if (rating.noReturnPercent != null && p['noReturns'] != null)
        (
          s.ratingReliability,
          s.ratingReliabilityExplanation(
            _ratingNumber(rating.noReturnPercent!),
            _ratingNumber(p['noReturns']!),
          ),
        ),
      if (rating.completedCount != null && p['volume'] != null)
        (
          s.closedOrders,
          s.ratingVolumeExplanation(
            '${rating.completedCount}',
            _ratingNumber(p['volume']!),
          ),
        ),
      if (p['complexity'] != null)
        (
          s.ratingComplexity,
          s.ratingComplexityExplanation(_ratingNumber(p['complexity']!)),
        ),
      if (rating.unjustifiedRejects != null &&
          p['rejects'] != null &&
          p['rejects']! < 0)
        (
          s.ratingRejects,
          s.ratingRejectsExplanation(
            '${rating.unjustifiedRejects}',
            _ratingNumber(p['rejects']!.abs()),
          ),
        ),
    ];
    if (items.isEmpty) {
      return Text(
        s.ratingHelp,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: Color(0xFF526079),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          Text(
            items[i].$1,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            items[i].$2,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF526079),
            ),
          ),
        ],
      ],
    );
  }

  Widget _metrics(BuildContext context, ExecutorRating rating) {
    final s = strings(context);
    final items = [
      (
        LucideIcons.shieldCheck,
        s.historyAverageScore,
        rating.quality == null
            ? '—'
            : '${rating.quality!.toStringAsFixed(1)} / 5',
      ),
      (
        LucideIcons.clock,
        s.ratingOnTimeOrders,
        rating.onTimePercent == null
            ? '—'
            : '${rating.onTimePercent!.toStringAsFixed(0)}%',
      ),
      (
        LucideIcons.clipboardPen,
        s.ratingReworkedOrders,
        rating.reworkPercent == null
            ? '—'
            : '${rating.reworkPercent!.toStringAsFixed(0)}%',
      ),
      (
        LucideIcons.circleCheck,
        s.closedOrders,
        rating.completedCount?.toString() ?? '—',
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Color(0xFFEEF2F7)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(items[i].$1, size: 17, color: _blue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i].$2,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: Color(0xFF526079),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  items[i].$3,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    if (_loggingOut) return;
    final session = AuthScope.maybeOf(context);
    setState(() => _loggingOut = true);
    try {
      final confirmed = await showLogoutConfirmation(context);
      if (!context.mounted || !confirmed) return;
      if (session == null) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        return;
      }
      await session.logout();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings(context).authNetworkError)),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }
}
