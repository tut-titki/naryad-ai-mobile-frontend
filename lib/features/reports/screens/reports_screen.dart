import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_services.dart';
import '../../../core/api/backend_document.dart';
import '../../../core/utils/enterprise_time.dart';
import '../../../l10n/ui_localization.dart';
import '../../../shared/models/models.dart' show dateLabel;
import '../../../shared/widgets/backend_section.dart';
import '../../../shared/widgets/ui.dart';
import '../../orders/widgets/master_scope_filters.dart';
import '../widgets/rating_report_view.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api, this.onExportingChanged});

  final ApiServices api;
  final ValueChanged<bool>? onExportingChanged;

  @override
  State<ReportsScreen> createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen> {
  static const _blue = Color(0xFF01408B);
  static const _background = Color(0xFFF5F7FB);
  static const _ink = Color(0xFF172B4D);
  static const _muted = Color(0xFF637B9E);
  static const _border = Color(0xFFE6EDF5);
  static const _lightBlue = Color(0xFFEAF2FE);

  DateTimeRange? selectedPeriod;

  String preset = 'today';
  String report = 'shift';
  String groupBy = 'material';

  Map<String, int> scope = {};

  bool exporting = false;

  // ============================================================
  // PERIOD & FILTERS
  // ============================================================

  DateTime get today {
    final now = enterpriseTime(DateTime.now());

    return DateTime(now.year, now.month, now.day);
  }

  DateTimeRange? get period => switch (preset) {
    'shift' || 'all' => null,
    'week' => DateTimeRange(
      start: today.subtract(const Duration(days: 6)),
      end: today,
    ),
    'month' => DateTimeRange(
      start: today.subtract(const Duration(days: 29)),
      end: today,
    ),
    'custom' => selectedPeriod,
    _ => DateTimeRange(start: today, end: today),
  };

  DateTime utcDay(DateTime date) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).subtract(const Duration(hours: 5));

  Map<String, dynamic> get filters => {
    ...scope,
    if (['shift', 'week', 'month'].contains(preset)) 'period': preset,
    if (preset == 'today' || preset == 'custom' || preset == 'all') ...{
      'from': utcDay(
        preset == 'all' ? DateTime(2000) : period!.start,
      ).toIso8601String(),
      'to': utcDay(preset == 'all' ? today : period!.end)
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1))
          .toIso8601String(),
    },
    if (report == 'materials') 'groupBy': groupBy,
  };

  Future<void> export(String format) async {
    if (exporting) return;

    setState(() => exporting = true);
    widget.onExportingChanged?.call(true);

    try {
      final pdf = format == 'pdf';

      final bytes = await widget.api.reports.export(
        pdf: pdf,
        report: report == 'brigade-ratings' ? 'brigades' : report,
        filters: filters,
      );

      if (!mounted) return;

      final saved = await FileSaver.instance.saveAs(
        name: 'mineral-$report',
        bytes: bytes,
        fileExtension: pdf ? 'pdf' : 'xlsx',
        mimeType: pdf ? MimeType.pdf : MimeType.microsoftExcel,
      );

      if (mounted && saved != null) {
        showMessage(
          context,
          backendText(context, 'Отчёт сохранён', 'Есеп сақталды'),
        );
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, backendError(context, error));
      }
    } finally {
      widget.onExportingChanged?.call(false);
      if (mounted) {
        setState(() => exporting = false);
      }
    }
  }

  double number(Object? value) {
    final parsed = double.tryParse('$value');
    return parsed != null && parsed.isFinite ? parsed : 0;
  }

  // ============================================================
  // COMMON UI
  // ============================================================

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  Widget _sectionTitle(String title, {IconData? icon, Widget? trailing}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 19, color: _blue),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  InputDecoration _inputDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted, fontSize: 13),
      prefixIcon: icon == null ? null : Icon(icon, color: _blue, size: 19),
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _blue, width: 1.4),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Future<void> _openFilters() async {
    var draftPreset = preset;
    var draftReport = report;
    var draftGroup = groupBy;
    var draftScope = Map<String, int>.from(scope);
    var draftRange = selectedPeriod;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .85,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    backendText(sheetContext, 'Фильтры', 'Сүзгілер'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle(
                    backendText(sheetContext, 'Период', 'Кезең'),
                    icon: LucideIcons.calendarDays,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final choice in [
                        ('shift', backendText(sheetContext, 'Смена', 'Ауысым')),
                        ('today', strings(sheetContext).todayPeriod),
                        ('week', strings(sheetContext).weekPeriod),
                        ('month', strings(sheetContext).monthPeriod),
                        ('all', strings(sheetContext).allTimePeriod),
                      ])
                        ChoiceChip(
                          label: Text(choice.$2),
                          selected: draftPreset == choice.$1,
                          onSelected: (_) =>
                              updateSheet(() => draftPreset = choice.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(LucideIcons.calendarRange, size: 18),
                    label: Text(
                      draftPreset == 'custom' && draftRange != null
                          ? '${dateLabel(draftRange!.start)} — ${dateLabel(draftRange!.end)}'
                          : strings(sheetContext).selectPeriod,
                    ),
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: sheetContext,
                        firstDate: DateTime(2000),
                        lastDate: today,
                        currentDate: today,
                        initialDateRange: draftRange,
                        helpText: strings(sheetContext).selectPeriod,
                      );
                      if (range != null && sheetContext.mounted) {
                        updateSheet(() {
                          draftRange = range;
                          draftPreset = 'custom';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    key: ValueKey('report-type-$draftReport'),
                    initialValue: draftReport,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      label: backendText(
                        sheetContext,
                        'Тип отчёта',
                        'Есеп түрі',
                      ),
                    ),
                    items: [
                      for (final choice in [
                        ('shift', 'Отчёт по смене', 'Ауысым есебі'),
                        (
                          'ratings',
                          'Рейтинг исполнителей',
                          'Орындаушылар рейтингі',
                        ),
                        (
                          'brigade-ratings',
                          'Рейтинг бригад',
                          'Бригадалар рейтингі',
                        ),
                        (
                          'materials',
                          'Списанные материалы',
                          'Жұмсалған материалдар',
                        ),
                        (
                          'downtime',
                          'Простои оборудования',
                          'Жабдықтың тоқтап тұруы',
                        ),
                        (
                          'anomalies',
                          'Аномалии и зависимости',
                          'Аномалиялар мен байланыстар',
                        ),
                      ])
                        DropdownMenuItem(
                          value: choice.$1,
                          child: Text(
                            backendText(sheetContext, choice.$2, choice.$3),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) updateSheet(() => draftReport = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  MasterScopeFilters(
                    api: widget.api,
                    value: draftScope,
                    onChanged: (value) => updateSheet(() => draftScope = value),
                  ),
                  if (draftReport == 'materials') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('group-$draftGroup'),
                      initialValue: draftGroup,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        label: backendText(
                          sheetContext,
                          'Группировка',
                          'Топтастыру',
                        ),
                      ),
                      items: [
                        for (final choice in [
                          ('material', 'Материал', 'Материал'),
                          ('area', 'Участок', 'Учаске'),
                          ('equipment', 'Оборудование', 'Жабдық'),
                          ('executor', 'Исполнитель', 'Орындаушы'),
                        ])
                          DropdownMenuItem(
                            value: choice.$1,
                            child: Text(
                              backendText(sheetContext, choice.$2, choice.$3),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          updateSheet(() => draftGroup = value);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext, false),
                          child: Text(
                            backendText(sheetContext, 'Отмена', 'Бас тарту'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(sheetContext, true),
                          child: Text(uiText(sheetContext, 'Применить')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (applied != true || !mounted) return;
    setState(() {
      preset = draftPreset;
      report = draftReport;
      groupBy = draftGroup;
      scope = draftScope;
      selectedPeriod = draftRange;
    });
  }

  Widget _shiftResults(BuildContext context, BackendDocument data) {
    final map = data.value as Map;

    final metrics = [
      (
        'issued',
        backendText(context, 'Выдано нарядов', 'Берілген нарядтар'),
        LucideIcons.clipboardList,
        _blue,
      ),
      (
        'completed',
        backendText(context, 'Выполнено', 'Орындалды'),
        LucideIcons.badgeCheck,
        const Color(0xFF059669),
      ),
      (
        'overdue',
        backendText(context, 'Просрочено', 'Мерзімі өткен'),
        LucideIcons.timer,
        const Color(0xFFDC2626),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 480;

            if (compact) {
              return Column(
                children: [
                  for (final metric in metrics) ...[
                    _metricCard(
                      title: metric.$2,
                      value: '${map[metric.$1] ?? '—'}',
                      icon: metric.$3,
                      color: metric.$4,
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  Expanded(
                    child: _metricCard(
                      title: metrics[i].$2,
                      value: '${map[metrics[i].$1] ?? '—'}',
                      icon: metrics[i].$3,
                      color: metrics[i].$4,
                    ),
                  ),
                  if (i < metrics.length - 1) const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _card(
          child: BackendDocumentView(
            document: BackendDocument.fromJson({
              for (final entry in map.entries)
                if (!{'issued', 'completed', 'overdue'}.contains(entry.key))
                  entry.key
                      .toString(): entry.key == 'load' && entry.value is List
                      ? (entry.value as List).where((employee) {
                          if (employee is! Map) return false;
                          final assigned =
                              num.tryParse('${employee['assigned']}') ?? 0;
                          final completed =
                              num.tryParse('${employee['completed']}') ?? 0;
                          final executorId = scope['executorId'];
                          return (assigned > 0 || completed > 0) &&
                              (executorId == null ||
                                  '${employee['id']}' == '$executorId');
                        }).toList()
                      : entry.value,
            }),
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _card(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RATINGS
  // ============================================================

  Widget _ratingResults(BuildContext context, BackendDocument data) {
    if (data.value is! List || (data.value as List).isEmpty) {
      return _card(child: BackendDocumentView(document: data));
    }

    final entries = (data.value as List).whereType<Map>().toList()
      ..sort((a, b) => number(b['score']).compareTo(number(a['score'])));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RatingReportView(
          entries: entries,
          brigades: report == 'brigade-ratings',
          onDetails: (item, position) => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            backgroundColor: _background,
            builder: (sheetContext) => SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _ratingCard(sheetContext, item, position),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ratingCard(BuildContext context, Map item, int position) {
    final score = number(item['score']);

    final scoreColor = score >= 80
        ? const Color(0xFF059669)
        : score >= 50
        ? _blue
        : const Color(0xFFEA580C);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: position <= 3 ? const Color(0xFFFFF4D6) : _lightBlue,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: position <= 3
                    ? const Icon(
                        LucideIcons.award,
                        size: 20,
                        color: Color(0xFFB86A08),
                      )
                    : Text(
                        '$position',
                        style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${item['fullName'] ?? item['name'] ?? '—'}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item['score'] ?? '—'}/100',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: _lightBlue,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          if (item['points'] is Map) ...[
            const SizedBox(height: 16),
            for (final part in [
              ('quality', 'Качество', 'Сапа'),
              ('onTime', 'В срок', 'Уақытында'),
              ('noReturns', 'Без возвратов', 'Қайтарусыз'),
              ('volume', 'Объём работ', 'Жұмыс көлемі'),
              ('complexity', 'Сложность', 'Күрделілік'),
            ])
              if ((item['points'] as Map).containsKey(part.$1))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              backendText(context, part.$2, part.$3),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '${item['points'][part.$1]}',
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: (number(item['points'][part.$1]) / 100).clamp(
                            0.0,
                            1.0,
                          ),
                          minHeight: 5,
                          backgroundColor: _lightBlue,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
          if (item['points'] is Map && item['points']['rejects'] != null) ...[
            const Divider(color: _border),
            Row(
              children: [
                const Icon(
                  LucideIcons.alertTriangle,
                  size: 16,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${backendText(context, 'Штраф за отказы', 'Бас тарту үшін айып')}: ${item['points']['rejects']}',
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          BackendDocumentView(
            document: BackendDocument.fromJson({
              for (final entry in item.entries)
                if (!{
                  'id',
                  'fullName',
                  'name',
                  'score',
                  'points',
                  'brigadeId',
                }.contains(entry.key))
                  entry.key.toString(): entry.value,
            }),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULTS
  // ============================================================

  Widget _result(BuildContext context, BackendDocument data) {
    if (report == 'ratings' || report == 'brigade-ratings') {
      return _ratingResults(context, data);
    }

    if (report == 'shift' && data.value is Map) {
      return _shiftResults(context, data);
    }

    return _card(child: BackendDocumentView(document: data));
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final query = filters;
    return ColoredBox(
      color: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _openFilters,
              icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
              label: Text(uiText(context, 'Фильтры')),
            ),
          ),
          const SizedBox(height: 20),
          BackendSection<BackendDocument>(
            key: ValueKey('$report-$query'),
            load: () => widget.api.reports.getReport(report, filters: query),
            changes: widget.api.realtime.changes,
            builder: (context, data) => _result(context, data),
          ),
        ],
      ),
    );
  }
}
