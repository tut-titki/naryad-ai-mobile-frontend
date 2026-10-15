import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/core/utils/enterprise_time.dart';
import 'package:mineral/shared/models/models.dart';

void main() {
  test(
    'picked enterprise deadline keeps its wall time, including midnight',
    () {
      final picked = enterpriseWallTimeToUtc(DateTime(2026, 10, 15), 0, 14);
      expect(picked, DateTime.utc(2026, 10, 14, 19, 14));
      expect(enterpriseDateTimeLabel(picked), '00:14 15.10.2026');
      final evening = enterpriseWallTimeToUtc(DateTime(2026, 10, 15), 21, 14);
      expect(enterpriseDateTimeLabel(evening), '21:14 15.10.2026');
    },
  );
  test('UTC+5 formatting crosses midnight without changing the instant', () {
    final instant = DateTime.parse('2026-10-07T21:32:00Z');
    expect(timeLabel(instant), '02:32');
    expect(dateLabel(instant), '08.10.2026');
    expect(instant.hour, 21);
    expect(enterpriseDateTimeLabel(instant), '02:32 08.10.2026');
  });
  test('equivalent offsets and device-local values have identical labels', () {
    final utc = DateTime.parse('2026-10-07T05:32:00Z');
    final offset = DateTime.parse('2026-10-07T10:32:00+05:00');
    expect(timeLabel(utc), '10:32');
    expect(timeLabel(offset), timeLabel(utc));
    expect(timeLabel(utc.toLocal()), timeLabel(utc));
    expect(enterpriseDateTimeLabel(offset), '10:32 07.10.2026');
    expect(
      enterpriseDateTimeLabel(utc.toLocal()),
      enterpriseDateTimeLabel(utc),
    );
    expect(
      enterpriseTime(
        utc,
      ).difference(enterpriseTime(utc.add(const Duration(minutes: 47)))),
      const Duration(minutes: -47),
    );
  });
}
