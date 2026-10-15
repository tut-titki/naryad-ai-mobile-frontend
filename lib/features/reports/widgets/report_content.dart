import 'package:flutter/material.dart';

import '../../../core/api/backend_document.dart';
import '../../../core/utils/enterprise_time.dart';
import '../../../l10n/ui_localization.dart';
import '../../../shared/widgets/backend_section.dart';
import '../../master/widgets/master_ui.dart';

/// Presentation of report snapshots; totals and percentages come from the API.
class ReportContent extends StatelessWidget {
  const ReportContent({
    super.key,
    required this.report,
    required this.data,
    this.executorId,
  });

  final String report;
  final Object? data;
  final int? executorId;

  // Zero and false are report values, not missing data. IDs alone are not content.
  static bool hasData(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.any(hasData);
    if (value is Map) {
      return value.entries.any(
        (entry) =>
            entry.key != 'id' &&
            !entry.key.toString().endsWith('Id') &&
            entry.key != 'rawResponse' &&
            hasData(entry.value),
      );
    }
    return true;
  }

  Object? _prune(Object? value) {
    if (!hasData(value)) return null;
    if (value is List) return value.where(hasData).map(_prune).toList();
    if (value is Map) {
      return {
        for (final entry in value.entries)
          if (hasData(entry.value)) entry.key: _prune(entry.value),
      };
    }
    return value;
  }

  static const _labels = <String, (String, String)>{
    'from': ('Начало периода', 'Кезеңнің басталуы'),
    'to': ('Конец периода', 'Кезеңнің аяқталуы'),
    'closed': ('Закрыто', 'Жабылды'),
    'rejected': ('Отклонено', 'Қабылданбады'),
    'cancelled': ('Отменено', 'Бас тартылды'),
    'inProgress': ('В работе', 'Орындалуда'),
    'assigned': ('Назначено', 'Тағайындалды'),
    'completed': ('Выполнено', 'Орындалды'),
    'activeNow': ('Сейчас в работе', 'Қазір орындалуда'),
    'specialty': ('Специальность', 'Мамандық'),
    'employeeStatus': ('Статус сотрудника', 'Қызметкер мәртебесі'),
    'isOnShift': ('На смене', 'Ауысымда'),
    'executorsOnShift': ('На смене', 'Ауысымда'),
    'busy': ('Заняты', 'Бос емес'),
    'free': ('Свободны', 'Бос'),
    'equipmentInDowntimeNow': (
      'Оборудование в простое',
      'Тоқтап тұрған жабдық',
    ),
    'orders': ('Нарядов с простоем', 'Тоқтап тұру нарядтары'),
    'minutes': ('Простой, мин', 'Тоқтап тұру, мин'),
    'plannedMinutes': ('Плановый, мин', 'Жоспарлы, мин'),
    'unplannedMinutes': ('Внеплановый, мин', 'Жоспардан тыс, мин'),
    'plannedShare': ('Доля планового простоя', 'Жоспарлы тоқтап тұру үлесі'),
    'unplannedShare': (
      'Доля внепланового простоя',
      'Жоспардан тыс тоқтап тұру үлесі',
    ),
    'ongoing': ('Продолжается', 'Жалғасуда'),
    'quantity': ('Расход', 'Шығын'),
    'count': ('Количество нарядов', 'Нарядтар саны'),
    'normQuantity': ('По нормативу', 'Норматив бойынша'),
    'deviationPercent': ('Отклонение от нормы', 'Нормадан ауытқу'),
    'overNormCount': ('Превышений нормы', 'Нормадан асып кету'),
  };

  String _label(BuildContext context, String key) {
    final pair = _labels[key];
    return pair == null ? key : backendText(context, pair.$1, pair.$2);
  }

  String _value(BuildContext context, Object? value, String key) {
    if (!hasData(value)) {
      return backendText(context, 'Нет данных', 'Деректер жоқ');
    }
    if (value is bool) {
      return backendText(context, value ? 'Да' : 'Нет', value ? 'Иә' : 'Жоқ');
    }
    if (value is String) {
      final date = DateTime.tryParse(value);
      if (date != null && value.contains('T')) {
        return enterpriseDateTimeLabel(date);
      }
    }
    if (key == 'deviationPercent') return '$value%';
    return '$value';
  }

  String _name(BuildContext context, Object? value) {
    final name = value is Map ? value['name'] ?? value['fullName'] : value;
    return hasData(name)
        ? uiText(context, '$name')
        : backendText(context, 'Нет данных', 'Деректер жоқ');
  }

  List<Map> _rows(Object? value) =>
      value is List ? value.whereType<Map>().toList() : [];

  Widget _section(
    BuildContext context,
    String ru,
    String kk,
    IconData icon,
    List<Widget> children, {
    bool collapsible = false,
  }) {
    final heading = Row(
      children: [
        Icon(icon, size: 19, color: MasterColors.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            backendText(context, ru, kk),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (collapsible)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: heading,
              childrenPadding: const EdgeInsets.only(top: 8),
              shape: const Border(),
              collapsedShape: const Border(),
              children: children,
            )
          else ...[
            heading,
            const SizedBox(height: 8),
            ...children,
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: MasterColors.line),
        ],
      ),
    );
  }

  Widget _fields(BuildContext context, Map values, Iterable<String> keys) {
    final present = keys.where((key) => hasData(values[key])).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final key in present)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _label(context, key),
                    style: const TextStyle(
                      color: MasterColors.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    _value(context, values[key], key),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: MasterColors.ink,
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _extras(Map values, Set<String> handled) {
    final rest = {
      for (final entry in values.entries)
        if (!handled.contains('${entry.key}')) '${entry.key}': entry.value,
    };
    if (!hasData(rest)) return const SizedBox.shrink();
    return BackendDocumentView(
      document: BackendDocument.fromJson(_prune(rest)),
    );
  }

  Widget _entry(
    BuildContext context,
    String title,
    String? subtitle,
    Widget child, {
    Color color = MasterColors.blue,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: MasterColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 14,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: MasterColors.muted),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );

  List<Widget> _period(BuildContext context, Map map) => [
    if (map.containsKey('from') || map.containsKey('to'))
      _section(
        context,
        'Период отчёта',
        'Есеп кезеңі',
        Icons.date_range_outlined,
        [
          _fields(context, map, ['from', 'to']),
        ],
      ),
  ];

  Widget _shift(BuildContext context, Map map) {
    final employees = _rows(map['load']).where((employee) {
      final assigned = num.tryParse('${employee['assigned']}') ?? 0;
      final completed = num.tryParse('${employee['completed']}') ?? 0;
      return (assigned > 0 || completed > 0) &&
          (executorId == null || '${employee['id']}' == '$executorId');
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._period(context, map),
        if ([
          'closed',
          'rejected',
          'cancelled',
          'inProgress',
        ].any(map.containsKey))
          _section(
            context,
            'Итоги нарядов',
            'Нарядтар қорытындысы',
            Icons.assignment_outlined,
            [
              _fields(context, map, [
                'closed',
                'inProgress',
                'rejected',
                'cancelled',
              ]),
            ],
          ),
        if (map['workload'] is Map)
          _section(
            context,
            'Команда на смене',
            'Ауысымдағы команда',
            Icons.groups_outlined,
            [
              _fields(context, map['workload'], [
                'executorsOnShift',
                'busy',
                'free',
              ]),
              _extras(map['workload'], {'executorsOnShift', 'busy', 'free'}),
            ],
          ),
        if (map['downtime'] is Map)
          _section(
            context,
            'Простои за смену',
            'Ауысымдағы тоқтап тұру',
            Icons.timer_outlined,
            [
              _fields(context, map['downtime'], [
                'equipmentInDowntimeNow',
                'orders',
                'minutes',
              ]),
              _extras(map['downtime'], {
                'equipmentInDowntimeNow',
                'orders',
                'minutes',
              }),
            ],
          ),
        if (map['aiSummary'] != null)
          _section(
            context,
            'AI-сводка',
            'AI қорытындысы',
            Icons.auto_awesome_outlined,
            [
              if (map['aiSummary'] is String)
                SelectableText(
                  map['aiSummary'],
                  style: const TextStyle(height: 1.6, color: MasterColors.ink),
                )
              else
                BackendDocumentView(
                  document: BackendDocument(map['aiSummary']),
                ),
            ],
          ),
        if (map.containsKey('load'))
          _section(
            context,
            'Загрузка сотрудников',
            'Қызметкерлердің жүктемесі',
            Icons.badge_outlined,
            [
              if (employees.isEmpty)
                Text(
                  backendText(
                    context,
                    'Нет сотрудников с нарядами за период',
                    'Кезеңде наряды бар қызметкерлер жоқ',
                  ),
                ),
              for (final employee in employees)
                _entry(
                  context,
                  '${employee['fullName'] ?? '—'}',
                  employee['specialty'] == null
                      ? null
                      : uiText(context, '${employee['specialty']}'),
                  Column(
                    children: [
                      _fields(context, employee, [
                        'assigned',
                        'completed',
                        'activeNow',
                        'isOnShift',
                      ]),
                      _extras(employee, {
                        'id',
                        'fullName',
                        'specialty',
                        'assigned',
                        'completed',
                        'activeNow',
                        'isOnShift',
                      }),
                    ],
                  ),
                ),
            ],
            collapsible: true,
          ),
        _extras(map, {
          'issued',
          'completed',
          'overdue',
          'from',
          'to',
          'closed',
          'rejected',
          'cancelled',
          'inProgress',
          'workload',
          'downtime',
          'aiSummary',
          'load',
        }),
      ],
    );
  }

  Widget _materials(BuildContext context, List<Map> rows) => _section(
    context,
    'Расход материалов',
    'Материалдар шығыны',
    Icons.inventory_2_outlined,
    [
      for (final item in rows)
        _entry(
          context,
          _name(context, item['material']),
          item['group'] == null ? null : _name(context, item['group']),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                hasData(item['quantity'])
                    ? '${item['quantity']} ${uiText(context, '${item['unit'] ?? ''}')}'
                          .trim()
                    : backendText(
                        context,
                        'Нет данных о расходе',
                        'Шығын туралы деректер жоқ',
                      ),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: MasterColors.blue,
                ),
              ),
              const SizedBox(height: 12),
              _fields(context, item, [
                'count',
                'normQuantity',
                'deviationPercent',
                'overNormCount',
              ]),
              _extras(item, {
                'material',
                'group',
                'quantity',
                'unit',
                'count',
                'normQuantity',
                'deviationPercent',
                'overNormCount',
              }),
            ],
          ),
          color: (num.tryParse('${item['deviationPercent']}') ?? 0) > 0
              ? const Color(0xFFB45309)
              : MasterColors.blue,
        ),
    ],
  );

  Widget _downtime(BuildContext context, Map map) {
    final totals = map['totals'] is Map ? map['totals'] as Map : const {};
    final planned = num.tryParse('${totals['plannedMinutes']}');
    final unplanned = num.tryParse('${totals['unplannedMinutes']}');
    const keys = [
      'minutes',
      'plannedMinutes',
      'unplannedMinutes',
      'plannedShare',
      'unplannedShare',
      'ongoing',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._period(context, map),
        if (hasData(totals))
          _section(
            context,
            'Баланс простоев',
            'Тоқтап тұру қорытындысы',
            Icons.timelapse,
            [
              if (planned != null &&
                  unplanned != null &&
                  planned >= 0 &&
                  unplanned >= 0 &&
                  planned + unplanned > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: planned / (planned + unplanned),
                    minHeight: 12,
                    color: MasterColors.blue,
                    backgroundColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  backendText(
                    context,
                    'Синий — плановый · Оранжевый — внеплановый',
                    'Көк — жоспарлы · Қызғылт сары — жоспардан тыс',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: MasterColors.muted,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _fields(context, totals, keys),
              _extras(totals, keys.toSet()),
            ],
          ),
        if (map.containsKey('byEquipment'))
          _section(
            context,
            'По оборудованию',
            'Жабдық бойынша',
            Icons.precision_manufacturing_outlined,
            [
              for (final item in _rows(map['byEquipment']))
                _entry(
                  context,
                  _name(context, item['equipment']),
                  _name(context, item['area']),
                  Column(
                    children: [
                      _fields(context, item, [...keys, 'count']),
                      _extras(item, {'equipment', 'area', ...keys, 'count'}),
                    ],
                  ),
                ),
            ],
          ),
        if (map.containsKey('items'))
          _section(
            context,
            'Случаи простоя',
            'Тоқтап тұру оқиғалары',
            Icons.history,
            [BackendDocumentView(document: BackendDocument(map['items']))],
            collapsible: true,
          ),
        _extras(map, {'from', 'to', 'totals', 'byEquipment', 'items'}),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (report == 'shift' &&
        hasData(data) &&
        data is Map &&
        !hasData({
          for (final entry in (data as Map).entries)
            if (!{'issued', 'completed', 'overdue'}.contains(entry.key))
              entry.key: entry.value,
        })) {
      return const SizedBox.shrink();
    }
    return MasterSurface(child: _content(context));
  }

  Widget _content(BuildContext context) {
    final snapshot = _prune(data);
    if (snapshot == null) {
      return _section(
        context,
        'Нет данных за выбранный период',
        'Таңдалған кезеңде деректер жоқ',
        Icons.inbox_outlined,
        [
          Text(
            backendText(
              context,
              'Измените период или фильтры отчёта.',
              'Есеп кезеңін немесе сүзгілерін өзгертіңіз.',
            ),
          ),
        ],
      );
    }
    if (report == 'shift' && snapshot is Map) return _shift(context, snapshot);
    if (report == 'materials' && snapshot is List) {
      return _materials(context, _rows(snapshot));
    }
    if (report == 'downtime' && snapshot is Map) {
      return _downtime(context, snapshot);
    }
    return BackendDocumentView(document: BackendDocument(snapshot));
  }
}
