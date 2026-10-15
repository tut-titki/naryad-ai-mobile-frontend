import '../../master/widgets/master_ui.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/api/api_services.dart';
import '../../../l10n/ui_localization.dart';
import '../../../shared/widgets/backend_refresh_view.dart';
import '../../../shared/widgets/backend_section.dart';

class MasterChatScreen extends StatefulWidget {
  const MasterChatScreen({super.key, required this.api});
  final ApiServices api;

  @override
  State<MasterChatScreen> createState() => _MasterChatScreenState();
}

class _ChatMessage {
  const _ChatMessage(this.text, {required this.fromMaster});
  final String text;
  final bool fromMaster;
}

class _MasterChatScreenState extends State<MasterChatScreen> {
  final _input = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _historyScroll = ScrollController();
  List<_ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _validateInput = false;
  Object? _historyError;
  Object? _sendError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _historyScroll.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (_sending) return;
    setState(() {
      _loading = true;
      _historyError = null;
    });
    try {
      final history = await widget.api.assistant.getHistory();
      final value = history.value;
      if (value is! List) throw const FormatException('Invalid chat history');
      final messages = <_ChatMessage>[];
      // The API returns up to 100 messages, newest first.
      for (final item in value.reversed.whereType<Map>()) {
        final role = item['role'];
        final content = item['content'] ?? item['message'] ?? item['text'];
        if ((role == 'user' || role == 'assistant') &&
            content is String &&
            content.trim().isNotEmpty) {
          messages.add(_ChatMessage(content, fromMaster: role == 'user'));
        }
      }
      if (mounted) setState(() => _messages = messages);
    } catch (error) {
      if (mounted) setState(() => _historyError = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_sending || _loading) return;
    setState(() => _validateInput = true);
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    final message = _input.text.trim();
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final reply = await widget.api.assistant.chat(message);
      if (!mounted) return;
      setState(() {
        _messages.addAll([
          _ChatMessage(message, fromMaster: true),
          _ChatMessage(reply.answer, fromMaster: false),
        ]);
        _validateInput = false;
        _input.clear();
      });
      _scrollToLatest();
    } catch (error) {
      if (mounted) setState(() => _sendError = error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _historyScroll.hasClients) {
        _historyScroll.animateTo(
          _historyScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: BackendRefreshView(
          onRefresh: _loadHistory,
          isLoading: _loading && _messages.isEmpty,
          scrollController: _historyScroll,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MasterIntro(
                title: 'Ассистент мастера',
                icon: LucideIcons.messageCircle,
                subtitle: backendText(
                  context,
                  'Задайте вопрос о нарядах, исполнителях или итогах смены.',
                  'Нарядтар, орындаушылар немесе ауысым қорытындысы туралы сұрақ қойыңыз.',
                ),
              ),
              const SizedBox(height: 16),
              if (_historyError != null) ...[
                BackendError(
                  message: backendError(context, _historyError!),
                  onRetry: _loadHistory,
                ),
                const SizedBox(height: 12),
              ],
              if (!_loading && _historyError == null && _messages.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    backendText(
                      context,
                      'Начните диалог с ассистентом',
                      'Ассистентпен диалогты бастаңыз',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final message in _messages) _bubble(context, message),
              if (_sending)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    backendText(
                      context,
                      'Ассистент печатает…',
                      'Ассистент жазып жатыр…',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: SafeArea(
          top: false,
          child: Form(
            key: _form,
            autovalidateMode: _validateInput
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_sendError != null) ...[
                  Text(
                    backendError(context, _sendError!),
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                ],
                TextFormField(
                  key: const ValueKey('chat-input'),
                  controller: _input,
                  enabled: !_sending,
                  minLines: 1,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    hintText: uiText(context, 'Например: кто сейчас свободен?'),
                    border: const OutlineInputBorder(),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        key: const ValueKey('chat-send'),
                        onPressed: _sending || _loading ? null : _send,
                        color: const Color(0xFF01408B),
                        icon: const Icon(LucideIcons.send, size: 20),
                        tooltip: backendText(
                          context,
                          _sendError == null ? 'Отправить' : 'Повторить',
                          _sendError == null ? 'Жіберу' : 'Қайталау',
                        ),
                      ),
                    ),
                  ),
                  validator: (text) {
                    final length = text?.trim().length ?? 0;
                    return length >= 2 && length <= 1000
                        ? null
                        : backendText(
                            context,
                            'Введите от 2 до 1000 символов',
                            '2-ден 1000-ға дейін таңба енгізіңіз',
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
  Widget _bubble(BuildContext context, _ChatMessage message) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: message.fromMaster
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!message.fromMaster) ...[
          const CircleAvatar(
            radius: 15,
            backgroundColor: MasterColors.tint,
            child: Icon(
              LucideIcons.sparkles,
              size: 16,
              color: MasterColors.blue,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: message.fromMaster ? MasterColors.blue : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(message.fromMaster ? 14 : 4),
                bottomRight: Radius.circular(message.fromMaster ? 4 : 14),
              ),
              border: message.fromMaster
                  ? null
                  : Border.all(color: MasterColors.line),
            ),
            child: SelectableText(
              message.text,
              style: TextStyle(
                color: message.fromMaster ? Colors.white : MasterColors.ink,
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ),
        ),
        if (message.fromMaster) const SizedBox(width: 4),
      ],
    ),
  );
}
