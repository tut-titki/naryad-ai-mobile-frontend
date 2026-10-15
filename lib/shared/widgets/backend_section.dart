import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/enterprise_time.dart';
import '../../core/api/api_client.dart';
import '../../core/api/backend_document.dart';
import '../../l10n/ui_localization.dart';
import 'ui.dart';
import 'backend_refresh_view.dart';

String backendText(BuildContext context, String ru, String kk) =>
    Localizations.localeOf(context).languageCode == 'kk'
    ? kk
    : uiText(context, ru);

String backendError(BuildContext context, Object error) => error is ApiException
    ? uiText(context, error.message)
    : backendText(
        context,
        'Не удалось загрузить данные. Проверьте соединение и повторите.',
        'Деректерді жүктеу мүмкін болмады. Қосылымды тексеріп, қайталаңыз.',
      );

class BackendError extends StatelessWidget {
  const BackendError({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      children: [
        const Icon(Icons.cloud_off_outlined, color: Colors.red),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.replay),
          label: Text(backendText(context, 'Повторить', 'Қайталау')),
        ),
      ],
    ),
  );
}

class BackendSection<T> extends StatefulWidget {
  const BackendSection({
    super.key,
    required this.load,
    required this.builder,
    this.changes,
    this.refreshInterval,
  });
  final Future<T> Function() load;
  final Widget Function(BuildContext, T) builder;
  final Stream<void>? changes;
  final Duration? refreshInterval;
  @override
  State<BackendSection<T>> createState() => _BackendSectionState<T>();
}

class _BackendSectionState<T> extends State<BackendSection<T>> {
  T? data;
  Object? error;
  bool loading = true;
  int generation = 0;
  StreamSubscription<void>? subscription;
  Timer? refreshTimer;
  DateTime? lastRefresh;
  BackendRefreshController? refreshController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = BackendRefreshScope.maybeOf(context);
    if (controller == refreshController) return;
    refreshController?.unregister(refreshFromGesture);
    refreshController?.setInitialLoading(this, false);
    refreshController = controller;
    refreshController?.register(refreshFromGesture);
    refreshController?.setInitialLoading(this, loading && data == null);
  }

  @override
  void initState() {
    super.initState();
    subscription = widget.changes?.listen((_) {
      final interval = widget.refreshInterval;
      if (interval == null) {
        reload();
        return;
      }
      if (refreshTimer != null) return;
      final elapsed = lastRefresh == null
          ? interval
          : DateTime.now().difference(lastRefresh!);
      final delay = elapsed >= interval ? Duration.zero : interval - elapsed;
      refreshTimer = Timer(delay, () {
        refreshTimer = null;
        reload();
      });
    });
    reload();
  }

  @override
  void dispose() {
    refreshController?.unregister(refreshFromGesture);
    refreshController?.setInitialLoading(this, false);
    subscription?.cancel();
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> refreshFromGesture() async {
    refreshTimer?.cancel();
    refreshTimer = null;
    final interval = widget.refreshInterval;
    if (interval != null && lastRefresh != null) {
      final elapsed = DateTime.now().difference(lastRefresh!);
      if (elapsed < interval) await Future<void>.delayed(interval - elapsed);
    }
    if (mounted) await reload();
  }

  Future<void> reload() async {
    lastRefresh = DateTime.now();
    final current = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    refreshController?.setInitialLoading(this, data == null);
    try {
      final result = await widget.load();
      if (mounted && current == generation) {
        setState(() {
          data = result;
          loading = false;
        });
        refreshController?.setInitialLoading(this, false);
      }
    } catch (exception) {
      if (mounted && current == generation) {
        setState(() {
          error = exception;
          loading = false;
        });
        refreshController?.setInitialLoading(this, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (loading && data == null && refreshController == null)
        const Padding(
          padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator()),
        ),
      if (error != null)
        BackendError(message: backendError(context, error!), onRetry: reload)
      else if (data != null)
        widget.builder(context, data as T),
    ],
  );
}

/// Displays actual fields of responses whose nested schema is undocumented.
class BackendDocumentView extends StatelessWidget {
  const BackendDocumentView({super.key, required this.document});
  final BackendDocument document;
  @override
  Widget build(BuildContext context) => document.isEmpty
      ? Text(
          backendText(context, 'Нет данных', 'Деректер жоқ'),
          style: const TextStyle(color: muted),
        )
      : _render(context, document.value);

  Widget _render(BuildContext context, Object? value) {
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in value)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _render(context, item),
            ),
        ],
      );
    }
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in value.entries.where(
            (entry) =>
                entry.key != 'rawResponse' &&
                !_isIdentifier(entry.key.toString()),
          ))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: entry.value is Map || entry.value is List
                  ? ExpansionTile(
                      title: Text(_label(context, entry.key.toString())),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: _render(context, entry.value),
                        ),
                      ],
                    )
                  : Text(
                      '${_label(context, entry.key.toString())}: ${_scalar(context, entry.value, field: entry.key.toString())}',
                      style: const TextStyle(height: 1.5),
                    ),
            ),
        ],
      );
    }
    return SelectableText(_scalar(context, value));
  }

  String _scalar(BuildContext context, Object? value, {String? field}) {
    if (value == null) return '—';
    if (value is bool) {
      return backendText(context, value ? 'Да' : 'Нет', value ? 'Иә' : 'Жоқ');
    }
    if (value is String) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}').hasMatch(value)) {
        final date = DateTime.tryParse(value);
        if (date != null) return enterpriseDateTimeLabel(date);
      }
      if ({
        'status',
        'employeeStatus',
        'role',
        'priority',
        'type',
        'fromStatus',
        'toStatus',
        'action',
        'audience',
      }.contains(field)) {
        const enums = {
          'ISSUED': ('Выдан', 'Берілді'),
          'QUEUED': ('В очереди', 'Кезекте'),
          'ACCEPTED': ('Принят', 'Қабылданды'),
          'IN_PROGRESS': ('В работе', 'Орындалуда'),
          'PAUSED': ('Приостановлен', 'Тоқтатылды'),
          'COMPLETED': ('Выполнен', 'Орындалды'),
          'AI_REVIEW': ('На проверке', 'Тексеруде'),
          'REWORK': ('На доработке', 'Қайта орындауда'),
          'CLOSED': ('Закрыт', 'Жабылды'),
          'REJECTED': ('Отклонён', 'Қабылданбады'),
          'CANCELLED': ('Отменён', 'Бас тартылды'),
          'AVAILABLE': ('Свободен', 'Бос'),
          'BUSY': ('Занят', 'Жұмыста'),
          'OFF_SHIFT': ('Не на смене', 'Ауысымда емес'),
          'EXECUTOR': ('Исполнитель', 'Орындаушы'),
          'MASTER': ('Мастер смены', 'Ауысым шебері'),
          'MANAGER': ('Руководитель', 'Басшы'),
          'ADMIN': ('Администратор', 'Әкімші'),
          'EMERGENCY': ('Аварийный', 'Апаттық'),
          'HIGH': ('Высокий', 'Жоғары'),
          'NORMAL': ('Обычный', 'Қалыпты'),
          'PLANNED': ('Плановый', 'Жоспарлы'),
          'CREATE': ('Наряд создан', 'Наряд жасалды'),
          'ACCEPT': ('Наряд принят', 'Наряд қабылданды'),
          'QUEUE': ('Добавлен в очередь', 'Кезекке қосылды'),
          'REJECT': ('Наряд отклонён', 'Наряд қабылданбады'),
          'START': ('Работа начата', 'Жұмыс басталды'),
          'PAUSE': ('Работа приостановлена', 'Жұмыс тоқтатылды'),
          'RESUME': ('Работа продолжена', 'Жұмыс жалғастырылды'),
          'COMPLETE': ('Передан на проверку', 'Тексеруге жіберілді'),
          'SEND_TO_REWORK': (
            'Отправлен на доработку',
            'Қайта орындауға жіберілді',
          ),
          'CLOSE': ('Наряд закрыт', 'Наряд жабылды'),
          'CANCEL': ('Наряд отменён', 'Нарядтан бас тартылды'),
          'EDIT': ('Наряд изменён', 'Наряд өзгертілді'),
          'REASSIGN': ('Исполнитель изменён', 'Орындаушы өзгертілді'),
          'COMMENT': ('Добавлен комментарий', 'Түсініктеме қосылды'),
        };
        final label = enums[value];
        if (label != null) return backendText(context, label.$1, label.$2);
      }
      return uiText(context, value);
    }
    return value.toString();
  }

  bool _isIdentifier(String key) =>
      key.toLowerCase() == 'id' ||
      RegExp(r'(Id|ID|Ids|IDs|_id|_ids)$').hasMatch(key);

  String _label(BuildContext context, String key) {
    const labels = {
      'fullName': ('Имя', 'Аты'),
      'name': ('Название', 'Атауы'),
      'message': ('Сообщение', 'Хабарлама'),
      'answer': ('Ответ', 'Жауап'),
      'role': ('Роль', 'Рөлі'),
      'content': ('Текст', 'Мәтін'),
      'createdAt': ('Дата', 'Күні'),
      'updatedAt': ('Дата изменения', 'Өзгертілген күні'),
      'acceptedAt': ('Дата принятия', 'Қабылданған күні'),
      'pauseReason': ('Причина приостановки', 'Уақытша тоқтату себебі'),
      'rejectionReason': ('Причина отказа', 'Бас тарту себебі'),
      'equipment': ('Оборудование', 'Жабдық'),
      'executor': ('Исполнитель', 'Орындаушы'),
      'rating': ('Рейтинг', 'Рейтинг'),
      'score': ('Оценка', 'Баға'),
      'count': ('Количество', 'Саны'),
      'total': ('Всего', 'Барлығы'),
      'orders': ('Наряды', 'Нарядтар'),
      'quantity': ('Количество', 'Саны'),
      'unit': ('Единица', 'Өлшем бірлігі'),
      'description': ('Описание', 'Сипаттама'),
      'recommendation': ('Рекомендация', 'Ұсыныс'),
      'specialty': ('Специальность', 'Мамандық'),
      'status': ('Статус', 'Мәртебе'),
      'brigade': ('Бригада', 'Бригада'),
      'material': ('Материал', 'Материал'),
      'quality': ('Качество', 'Сапа'),
      'onTimeRate': (
        'Доля выполненных в срок',
        'Мерзімінде орындалғандар үлесі',
      ),
      'reworkRate': ('Доля доработок', 'Қайта орындаулар үлесі'),
      'returnRate': (
        'Доля возвратов в ремонт',
        'Қайта жөндеуге қайтарылғандар үлесі',
      ),
      'repeatFailureRate': (
        'Доля повторных поломок',
        'Қайталанған ақаулар үлесі',
      ),
      'closed': ('Закрыто нарядов', 'Жабылған нарядтар'),
      'points': ('Баллы по показателям', 'Көрсеткіштер бойынша ұпайлар'),
      'formula': ('Формула рейтинга', 'Рейтинг формуласы'),
      'explanation': ('Объяснение', 'Түсіндірме'),
      'productivity': ('Объём работы', 'Жұмыс көлемі'),
      'complexityBonus': ('Баллы за сложность', 'Күрделілік үшін ұпайлар'),
      'unjustifiedRejects': ('Необоснованные отказы', 'Негізсіз бас тартулар'),
      'onTime': ('В срок', 'Мерзімінде'),
      'noReturns': ('Без повторного ремонта', 'Қайта жөндеусіз'),
      'volume': ('Объём работы', 'Жұмыс көлемі'),
      'complexity': ('Сложность работ', 'Жұмыс күрделілігі'),
      'rejects': ('Отказы', 'Бас тартулар'),
      'from': ('Начало периода', 'Кезеңнің басталуы'),
      'to': ('Конец периода', 'Кезеңнің аяқталуы'),
      'issued': ('Выдано', 'Берілді'),
      'completed': ('Выполнено', 'Орындалды'),
      'overdue': ('Просрочено', 'Мерзімі өтті'),
      'rejected': ('Отклонено', 'Қабылданбады'),
      'cancelled': ('Отменено', 'Бас тартылды'),
      'inProgress': ('В работе', 'Орындалуда'),
      'load': ('Загрузка сотрудников', 'Қызметкерлердің жүктемесі'),
      'workload': ('Загрузка смены', 'Ауысым жүктемесі'),
      'assigned': ('Назначено нарядов', 'Тағайындалған нарядтар'),
      'activeNow': ('Активные сейчас', 'Қазір белсенді'),
      'executorsOnShift': ('Исполнителей на смене', 'Ауысымдағы орындаушылар'),
      'busy': ('Заняты', 'Жұмыста'),
      'free': ('Свободны', 'Бос'),
      'downtime': ('Простои', 'Тоқтап тұрулар'),
      'minutes': ('Минуты', 'Минуттар'),
      'aiSummary': ('Сводка ИИ', 'ЖИ жиынтығы'),
      'summary': ('Сводка', 'Жиынтық'),
      'recommendations': ('Рекомендации', 'Ұсыныстар'),
      'items': ('Записи', 'Жазбалар'),
      'members': ('Участники', 'Қатысушылар'),
      'totals': ('Итоги', 'Қорытындылар'),
      'byEquipment': ('По оборудованию', 'Жабдық бойынша'),
      'equipmentInDowntimeNow': (
        'Оборудование в простое',
        'Тоқтап тұрған жабдық',
      ),
      'plannedMinutes': ('Плановые простои, мин', 'Жоспарлы тоқтап тұру, мин'),
      'unplannedMinutes': (
        'Внеплановые простои, мин',
        'Жоспардан тыс тоқтап тұру, мин',
      ),
      'plannedShare': ('Доля плановых простоев', 'Жоспарлы тоқтап тұру үлесі'),
      'unplannedShare': (
        'Доля внеплановых простоев',
        'Жоспардан тыс тоқтап тұру үлесі',
      ),
      'ongoing': ('Продолжающиеся простои', 'Жалғасып жатқан тоқтап тұрулар'),
      'byFaultCode': ('По шифру неисправности', 'Ақау коды бойынша'),
      'code': ('Код', 'Код'),
      'reason': ('Причина', 'Себеп'),
      'startedAt': ('Начало', 'Басталуы'),
      'endedAt': ('Завершение', 'Аяқталуы'),
      'area': ('Участок', 'Учаске'),
      'normQuantity': ('Расход по нормативу', 'Норматив бойынша шығын'),
      'deviationPercent': ('Отклонение от нормы, %', 'Нормадан ауытқу, %'),
      'overNormCount': ('Превышений нормы', 'Нормадан асып кетулер'),
      'overNormOrders': (
        'Наряды с превышением нормы',
        'Нормадан асқан нарядтар',
      ),
      'probability': ('Вероятность', 'Ықтималдық'),
      'recentFailures': ('Последние поломки', 'Соңғы ақаулар'),
      'previousFailures': (
        'Поломки за предыдущий период',
        'Алдыңғы кезеңдегі ақаулар',
      ),
      'growth': ('Рост', 'Өсу'),
      'severity': ('Важность', 'Маңыздылық'),
      'evidence': ('Основания', 'Негіздемелер'),
      'title': ('Заголовок', 'Тақырып'),
      'type': ('Тип', 'Түрі'),
      'priority': ('Приоритет', 'Басымдық'),
      'employeeStatus': ('Статус сотрудника', 'Қызметкер мәртебесі'),
      'isOnShift': ('На смене', 'Ауысымда'),
      'number': ('Номер наряда', 'Наряд нөмірі'),
      'id': ('ID', 'ID'),
      'equipmentId': ('ID оборудования', 'Жабдық ID-і'),
      'executorId': ('ID исполнителя', 'Орындаушы ID-і'),
      'brigadeId': ('ID бригады', 'Бригада ID-і'),
      'workOrderId': ('ID наряда', 'Наряд ID-і'),
      'materialId': ('ID материала', 'Материал ID-і'),
      'faultCodeId': ('ID шифра неисправности', 'Ақау кодының ID-і'),
      'areaId': ('ID участка', 'Учаске ID-і'),
      'periodFrom': ('Начало периода', 'Кезеңнің басталуы'),
      'periodTo': ('Конец периода', 'Кезеңнің аяқталуы'),
      '_sum': ('Суммарные значения', 'Жиынтық мәндер'),
      '_count': ('Количество записей', 'Жазбалар саны'),
      'group': ('Группа', 'Топ'),
      'insights': ('Выводы', 'Қорытындылар'),
      'ai': ('Заключение ИИ', 'ЖИ қорытындысы'),
      'timing': ('Время выполнения', 'Орындау уақыты'),
      'actualHours': ('Фактическое время, ч', 'Нақты уақыт, сағ'),
      'normativeHours': ('Норматив, ч', 'Норматив, сағ'),
      'deadlineMet': ('Выполнено в срок', 'Мерзімінде орындалды'),
      'deadline': ('Срок выполнения', 'Орындау мерзімі'),
      'downtimeMinutes': ('Простой, мин', 'Тоқтап тұру, мин'),
      'chronology': ('История действий', 'Әрекеттер тарихы'),
      'action': ('Действие', 'Әрекет'),
      'at': ('Время', 'Уақыт'),
      'actor': ('Автор действия', 'Әрекет авторы'),
      'comment': ('Комментарий', 'Түсініктеме'),
      'fromStatus': ('Предыдущий статус', 'Алдыңғы мәртебе'),
      'toStatus': ('Новый статус', 'Жаңа мәртебе'),
      'audience': ('Получатель отчёта', 'Есеп алушы'),
      'finalScore': ('Итоговая оценка', 'Қорытынды баға'),
      'aiScore': ('Оценка ИИ', 'ЖИ бағасы'),
      'masterScore': ('Оценка мастера', 'Шебер бағасы'),
      'aiAssessment': ('ИИ-проверка', 'ЖИ тексеруі'),
      'completionText': ('Выполненные работы', 'Орындалған жұмыстар'),
      'actualDowntimeMinutes': (
        'Фактический простой, мин',
        'Нақты тоқтап тұру, мин',
      ),
      'needsMasterReview': (
        'Нужна проверка мастером',
        'Шебердің тексеруі қажет',
      ),
      'confidence': ('Уверенность', 'Сенімділік'),
      'photoScore': ('Оценка фото', 'Фото бағасы'),
      'completedAt': ('Выполнен', 'Орындалды'),
      'closedAt': ('Закрыт', 'Жабылды'),
      'vsNormativePercent': (
        'Время к нормативу, %',
        'Нормативке қатысты уақыт, %',
      ),
      'overdueMinutes': ('Просрочка, мин', 'Кешігу, мин'),
      'verdict': ('Результат проверки', 'Тексеру нәтижесі'),
      'strengths': ('Что сделано хорошо', 'Жақсы орындалған тұстар'),
      'improvements': ('Что улучшить', 'Жақсартуға болатын тұстар'),
      'masterComment': ('Комментарий мастера', 'Шебердің түсініктемесі'),
      'photoComment': ('Пояснение по фото', 'Фото бойынша түсіндірме'),
      'photosBefore': ('Фото до работ', 'Жұмысқа дейінгі фотолар'),
      'photosAfter': ('Фото после работ', 'Жұмыстан кейінгі фотолар'),
      'hours': ('Часы', 'Сағаттар'),
      'grade': ('Разряд', 'Разряд'),
      'statusText': ('Текущий статус', 'Ағымдағы мәртебе'),
      'inventoryNumber': ('Инвентарный номер', 'Түгендеу нөмірі'),
      'equipmentInDowntime': ('Оборудование в простое', 'Тоқтап тұрған жабдық'),
      'active': ('Активные наряды', 'Белсенді нарядтар'),
      'topEquipment': ('Частые поломки оборудования', 'Жабдықтың жиі ақаулары'),
      'topExecutors': ('Рейтинг исполнителей', 'Орындаушылар рейтингі'),
      'topAreas': ('Показатели участков', 'Учаске көрсеткіштері'),
    };
    final label = labels[key];
    return label == null ? key : backendText(context, label.$1, label.$2);
  }
}
