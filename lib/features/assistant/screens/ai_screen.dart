import '../../master/widgets/master_ui.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_services.dart';
import '../../../core/api/backend_document.dart';
import '../../orders/models/work_order_api_models.dart';
import '../../orders/screens/orders_screen.dart';
import '../../../l10n/ui_localization.dart';
import '../../../shared/widgets/backend_section.dart';
import '../data/assistant_api.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key, required this.api, required this.onOrder});

  final ApiServices api;
  final ValueChanged<WorkOrderApiModel> onOrder;

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  static const _blue = Color(0xFF01408B);
  static const _blueEnd = Color(0xFF0A57A3);
  static const _ink = Color(0xFF172B4D);
  static const _muted = Color(0xFF637B9E);
  static const _line = Color(0xFFE6EDF5);
  static const _background = Color(0xFFF5F7FB);
  static const _lightBlue = Color(0xFFEAF1FC);

  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool sending = false;
  Object? sendError;
  int historyVersion = 0;
  AssistantReply? reply;
  String? submittedMessage;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (sending || !(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final message = controller.text.trim();

    setState(() {
      sending = true;
      sendError = null;
    });

    try {
      final response = await widget.api.assistant.chat(message);

      if (!mounted) return;

      setState(() {
        reply = response;
        submittedMessage = message;
        controller.clear();
        historyVersion++;
      });
    } catch (error) {
      if (mounted) {
        setState(() => sendError = error);
      }
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hero(context),
          const SizedBox(height: 22),

          _sectionHeading('Контроль нарядов', LucideIcons.clipboardList),
          const SizedBox(height: 12),

          BackendSection<List<WorkOrderApiModel>>(
            load: widget.api.workOrders.getAllWorkOrders,
            changes: widget.api.realtime.changes,
            builder: (context, orders) {
              final overdue = orders.where((order) => order.isOverdue).toList();

              final review = orders
                  .where((order) => order.waitingForMasterReview)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _orderGroup(
                    context,
                    title: 'Просроченные наряды',
                    icon: LucideIcons.timer,
                    color: const Color(0xFFDC2626),
                    orders: overdue,
                    emptyText: 'Нет просроченных нарядов',
                  ),
                  const SizedBox(height: 14),
                  _orderGroup(
                    context,
                    title: 'Проверка выполнения',
                    icon: LucideIcons.badgeCheck,
                    color: _blue,
                    orders: review,
                    emptyText: 'Нет нарядов на проверке',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          _sectionHeading('Мониторинг оборудования', LucideIcons.activity),
          const SizedBox(height: 12),

          _surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _smallHeading(
                  'Аномалии оборудования',
                  LucideIcons.alertTriangle,
                ),
                const SizedBox(height: 14),
                BackendSection<BackendDocument>(
                  load: widget.api.analytics.getAnomalies,
                  changes: widget.api.realtime.changes,
                  builder: (context, data) =>
                      BackendDocumentView(document: data),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _sectionHeading('Ассистент мастера', LucideIcons.messageCircle),
          const SizedBox(height: 12),

          _assistantPanel(context),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_blue, _blueEnd],
        ),
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(LucideIcons.bot, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uiText(context, 'ИИ-контроль'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  uiText(
                    context,
                    'Контроль сроков, проверка работ и помощь мастеру',
                  ),
                  style: const TextStyle(
                    color: Color(0xFFDDEBFF),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      size: 15,
                      color: Color(0xFF8AF0CB),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        uiText(context, 'Финальное решение принимает мастер'),
                        style: const TextStyle(
                          color: Color(0xFFDDEBFF),
                          fontSize: 11,
                        ),
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

  Widget _orderGroup(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<WorkOrderApiModel> orders,
    required String emptyText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                uiText(context, title),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${orders.length}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          _surface(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.badgeCheck,
                  size: 18,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    uiText(context, emptyText),
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          for (final order in orders) ...[
            ApiOrderCard(order: order, onTap: () => widget.onOrder(order)),
            const SizedBox(height: 9),
          ],
      ],
    );
  }

  Widget _assistantPanel(BuildContext context) {
    return _surface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.bot, color: _blue, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        uiText(context, 'Цифровой помощник'),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        uiText(context, 'Задайте вопрос по производству'),
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: _line),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackendSection<BackendDocument>(
                  key: ValueKey(historyVersion),
                  load: widget.api.assistant.getHistory,
                  builder: (context, data) =>
                      BackendDocumentView(document: data),
                ),

                if (reply != null && submittedMessage != null) ...[
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: const BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        submittedMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _lightBlue,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          LucideIcons.bot,
                          color: _blue,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableText(
                          reply!.answer,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 13,
                            height: 1.65,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: _line),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: controller,
                    enabled: !sending,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 1000,
                    style: const TextStyle(color: _ink, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: uiText(
                        context,
                        'Например: кто сейчас свободен?',
                      ),
                      hintStyle: const TextStyle(color: _muted, fontSize: 12),
                      prefixIcon: const Icon(
                        LucideIcons.messageCircle,
                        size: 19,
                        color: _muted,
                      ),
                      filled: true,
                      fillColor: _background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _blue),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (text) {
                      final length = text?.trim().length ?? 0;
                      if (length < 2 || length > 1000) {
                        return backendText(
                          context,
                          'Введите от 2 до 1000 символов',
                          '2–1000 таңба енгізіңіз',
                        );
                      }
                      return null;
                    },
                  ),

                  if (sendError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.alertCircle,
                            color: Color(0xFFDC2626),
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              backendError(context, sendError!),
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: sending ? null : _send,
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 46),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: sending
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.send, size: 18),
                      label: Text(
                        backendText(
                          context,
                          sendError == null ? 'Отправить' : 'Повторить',
                          sendError == null ? 'Жіберу' : 'Қайталау',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 19, color: _blue),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            uiText(context, title),
            style: const TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _smallHeading(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _blue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            uiText(context, title),
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _surface({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  }) => MasterSurface(padding: padding, child: child);
}
