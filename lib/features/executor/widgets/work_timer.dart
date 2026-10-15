import 'package:mineral/l10n/ui_localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mineral/features/executor/data/executor_repository.dart';
import 'package:mineral/shared/models/models.dart';

class WorkTimer extends StatefulWidget {
  const WorkTimer({super.key, required this.order, required this.store});
  final WorkOrder order;
  final ExecutorRepository store;
  @override
  State<WorkTimer> createState() => _WorkTimerState();
}

class _WorkTimerState extends State<WorkTimer> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.order.status == OrderStatus.working) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.order.workDuration(widget.store.now);
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final kk = Localizations.localeOf(context).languageCode == 'kk';
    final time = [
      if (days > 0) '$days ${kk ? 'күн' : 'д'}',
      if (days > 0 || hours > 0) '$hours ${kk ? 'сағ' : 'ч'}',
      '$minutes мин',
    ].join(' ');
    return Semantics(
      label: strings(context).workTimeValue(time),
      child: Text(
        time,
        style: const TextStyle(
          color: Color(0xFF01408B),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
