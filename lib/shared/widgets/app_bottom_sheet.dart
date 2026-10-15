import 'package:flutter/material.dart';

const _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
);

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool enableDrag = true,
  bool isDismissible = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: true,
  showDragHandle: true,
  enableDrag: enableDrag,
  isDismissible: isDismissible,
  backgroundColor: const Color(0xFFF5F7FB),
  shape: _sheetShape,
  clipBehavior: Clip.antiAlias,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: builder,
);

ModalBottomSheetRoute<T> appBottomSheetRoute<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => ModalBottomSheetRoute<T>(
  builder: builder,
  capturedThemes: InheritedTheme.capture(
    from: context,
    to: Navigator.of(context).context,
  ),
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: const Color(0xFFF5F7FB),
  shape: _sheetShape,
  clipBehavior: Clip.antiAlias,
  constraints: const BoxConstraints(maxWidth: 640),
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
);

/// Shared layout for confirmation, input and detail sheets.
class AppSheetContent extends StatelessWidget {
  const AppSheetContent({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF01408B),
                fontWeight: FontWeight.w700,
              ),
              child: title,
            ),
            const SizedBox(height: 20),
            Flexible(child: SingleChildScrollView(child: content)),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 24),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 12,
                overflowSpacing: 8,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
}) {
  var selected = DateUtils.dateOnly(initialDate);
  final labels = MaterialLocalizations.of(context);
  return showAppBottomSheet<DateTime>(
    context: context,
    builder: (context) => AppSheetContent(
      title: Text(helpText ?? labels.datePickerHelpText),
      content: SizedBox(
        width: double.maxFinite,
        child: CalendarDatePicker(
          initialDate: selected,
          firstDate: firstDate,
          lastDate: lastDate,
          onDateChanged: (value) => selected = value,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText ?? labels.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, selected),
          child: Text(confirmText ?? labels.okButtonLabel),
        ),
      ],
    ),
  );
}

Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? helpText,
  String? cancelText,
  String? confirmText,
}) {
  var selected = initialTime;
  final labels = MaterialLocalizations.of(context);
  return showAppBottomSheet<TimeOfDay>(
    context: context,
    builder: (context) => AppSheetContent(
      title: Text(helpText ?? labels.timePickerDialHelpText),
      content: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: selected.hour,
              decoration: InputDecoration(
                labelText: labels.timePickerHourLabel,
              ),
              items: [
                for (var i = 0; i < 24; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(i.toString().padLeft(2, '0')),
                  ),
              ],
              onChanged: (value) {
                if (value != null) selected = selected.replacing(hour: value);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: selected.minute,
              decoration: InputDecoration(
                labelText: labels.timePickerMinuteLabel,
              ),
              items: [
                for (var i = 0; i < 60; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(i.toString().padLeft(2, '0')),
                  ),
              ],
              onChanged: (value) {
                if (value != null) selected = selected.replacing(minute: value);
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText ?? labels.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, selected),
          child: Text(confirmText ?? labels.okButtonLabel),
        ),
      ],
    ),
  );
}

Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  DateTimeRange? initialDateRange,
  String? helpText,
}) {
  final labels = MaterialLocalizations.of(context);
  DateTime clamp(DateTime value) {
    final date = DateUtils.dateOnly(value);
    return date.isBefore(firstDate)
        ? firstDate
        : date.isAfter(lastDate)
        ? lastDate
        : date;
  }

  var start = clamp(initialDateRange?.start ?? currentDate ?? DateTime.now());
  var end = clamp(initialDateRange?.end ?? start);
  var editingEnd = false;
  return showAppBottomSheet<DateTimeRange>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => AppSheetContent(
        title: Text(helpText ?? labels.dateRangePickerHelpText),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => update(() => editingEnd = false),
                    child: Text(
                      '${labels.dateRangeStartLabel}: ${labels.formatCompactDate(start)}',
                      style: TextStyle(
                        fontWeight: !editingEnd
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => update(() => editingEnd = true),
                    child: Text(
                      '${labels.dateRangeEndLabel}: ${labels.formatCompactDate(end)}',
                      style: TextStyle(
                        fontWeight: editingEnd
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            CalendarDatePicker(
              key: ValueKey(editingEnd),
              initialDate: editingEnd ? end : start,
              currentDate: currentDate,
              firstDate: editingEnd ? start : firstDate,
              lastDate: lastDate,
              onDateChanged: (value) => update(() {
                if (editingEnd) {
                  end = value;
                } else {
                  start = value;
                  if (end.isBefore(start)) end = start;
                  editingEnd = true;
                }
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(labels.cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, DateTimeRange(start: start, end: end)),
            child: Text(labels.saveButtonLabel),
          ),
        ],
      ),
    ),
  );
}
