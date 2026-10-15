import '../../master/widgets/master_ui.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/backend_section.dart';

/// Chart and table share one filtered report snapshot and one ordering.
class RatingReportView extends StatelessWidget {
  const RatingReportView({
    super.key,
    required this.entries,
    required this.brigades,
    required this.onDetails,
  });

  final List<Map> entries;
  final bool brigades;
  final void Function(Map item, int position) onDetails;

  static double? _number(Object? value) {
    final parsed = double.tryParse('$value');
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  static String _label(Object? value) {
    final parsed = _number(value);
    if (parsed == null) return '—';
    return parsed.toStringAsFixed(parsed == parsed.roundToDouble() ? 0 : 1);
  }

  static String _name(Map item) => '${item['fullName'] ?? item['name'] ?? '—'}';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [_chart(context), const SizedBox(height: 16), _table(context)],
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _heading(String title, IconData icon) => Row(
    children: [
      Icon(icon, size: 19, color: AppColors.primary),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );

  Widget _chart(BuildContext context) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          backendText(context, 'Сравнение рейтингов', 'Рейтингтерді салыстыру'),
          LucideIcons.chartNoAxesCombined,
        ),
        const SizedBox(height: 6),
        Text(
          backendText(context, 'Баллы из 100', '100 ұпайдан'),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final nameWidth = constraints.maxWidth < 430 ? 90.0 : 180.0;
            return Column(
              children: [
                for (var i = 0; i < entries.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: nameWidth,
                          child: Text(
                            _name(entries[i]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            label: _name(entries[i]),
                            value: '${_label(entries[i]['score'])}/100',
                            child: SizedBox(
                              height: 32,
                              child: CustomPaint(
                                painter: const _RatingGridPainter(),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    key: ValueKey('rating-bar-$i'),
                                    widthFactor:
                                        ((_number(entries[i]['score']) ?? 0) /
                                                100)
                                            .clamp(0.0, 1.0),
                                    child: Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 58,
                          child: Text(
                            '${_label(entries[i]['score'])}/100',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(
                    left: nameWidth + 12,
                    right: 66,
                    top: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final tick in [0, 25, 50, 75, 100])
                        Text(
                          '$tick',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _table(BuildContext context) {
    final components = [
      ('quality', 'Качество', 'Сапа'),
      ('onTime', 'В срок', 'Уақытында'),
      ('noReturns', 'Без возвратов', 'Қайтарусыз'),
      ('volume', 'Объём работ', 'Жұмыс көлемі'),
      ('complexity', 'Сложность', 'Күрделілік'),
      ('rejects', 'Штраф за отказы', 'Бас тарту үшін айып'),
    ];
    if (MediaQuery.sizeOf(context).width < 600) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heading(
              backendText(
                context,
                'Составляющие рейтинга',
                'Рейтингтің құрамдас бөліктері',
              ),
              LucideIcons.table,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  key: ValueKey('rating-components-$i'),
                  color: MasterColors.background,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onDetails(entries[i], i + 1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _name(entries[i]),
                                  style: const TextStyle(
                                    color: MasterColors.blue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_label(entries[i]['score'])}/100',
                                style: const TextStyle(
                                  color: MasterColors.blue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) => Wrap(
                              spacing: 8,
                              runSpacing: 10,
                              children: [
                                for (final component in components)
                                  SizedBox(
                                    width: (constraints.maxWidth - 8) / 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          backendText(
                                            context,
                                            component.$2,
                                            component.$3,
                                          ),
                                          style: const TextStyle(
                                            color: MasterColors.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _label(
                                            entries[i]['points'] is Map
                                                ? entries[i]['points'][component
                                                      .$1]
                                                : null,
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: component.$1 == 'rejects'
                                                ? const Color(0xFFDC2626)
                                                : MasterColors.ink,
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
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(
            backendText(
              context,
              'Составляющие рейтинга',
              'Рейтингтің құрамдас бөліктері',
            ),
            LucideIcons.table,
          ),
          const SizedBox(height: 6),
          Text(
            backendText(
              context,
              'Составляющие показаны в баллах',
              'Құрамдас бөліктер ұпаймен көрсетілген',
            ),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            key: const ValueKey('rating-table-scroll'),
            scrollDirection: Axis.horizontal,
            child: DataTable(
              key: const ValueKey('rating-components-table'),
              headingRowColor: const WidgetStatePropertyAll(
                AppColors.lightBlue,
              ),
              headingTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              dataTextStyle: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
              ),
              headingRowHeight: 60,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 72,
              horizontalMargin: 12,
              columnSpacing: 20,
              columns: [
                DataColumn(
                  label: Text(
                    backendText(
                      context,
                      brigades ? 'Бригада' : 'Исполнитель',
                      brigades ? 'Бригада' : 'Орындаушы',
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(backendText(context, 'Итог', 'Қорытынды')),
                ),
                for (final component in components)
                  DataColumn(
                    numeric: true,
                    label: SizedBox(
                      width: 100,
                      child: Text(
                        backendText(context, component.$2, component.$3),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
              ],
              rows: [
                for (var i = 0; i < entries.length; i++)
                  DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Text(
                            _name(entries[i]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onTap: () => onDetails(entries[i], i + 1),
                      ),
                      DataCell(
                        Text(
                          _label(entries[i]['score']),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      for (final component in components)
                        DataCell(
                          Text(
                            _label(
                              entries[i]['points'] is Map
                                  ? entries[i]['points'][component.$1]
                                  : null,
                            ),
                            style: component.$1 == 'rejects'
                                ? const TextStyle(color: Color(0xFFDC2626))
                                : null,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingGridPainter extends CustomPainter {
  const _RatingGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var tick = 0; tick <= 4; tick++) {
      final x = size.width * tick / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_RatingGridPainter oldDelegate) => false;
}
