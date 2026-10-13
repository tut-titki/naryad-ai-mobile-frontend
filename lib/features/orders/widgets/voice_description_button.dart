import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:record/record.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_services.dart';
import '../../../shared/widgets/backend_section.dart';
import '../../../shared/widgets/ui.dart';
import '../data/voice_transcription_response.dart';

Uint8List voiceWav(Uint8List pcm) {
  final result = Uint8List(44 + pcm.length);
  final header = ByteData.sublistView(result);
  void text(int offset, String value) =>
      result.setRange(offset, offset + value.length, value.codeUnits);
  text(0, 'RIFF');
  header.setUint32(4, 36 + pcm.length, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, 16000, Endian.little);
  header.setUint32(28, 32000, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  text(36, 'data');
  header.setUint32(40, pcm.length, Endian.little);
  result.setRange(44, result.length, pcm);
  return result;
}

/// The server's WAF rejects multipart parts whose `content-type` header comes
/// before `content-disposition` (the order package:http emits) and replies
/// HTTP 200 with an HTML error page. Reorder the part headers, same length.
class _VoiceUploadRequest extends http.MultipartRequest {
  _VoiceUploadRequest(super.method, super.url);

  @override
  http.ByteStream finalize() {
    final stream = super.finalize();
    return http.ByteStream(
      Stream.fromFuture(
        stream.toBytes().then((bytes) {
          final end = _indexOfHeaderEnd(bytes);
          if (end < 0) return bytes;
          final lines = latin1.decode(bytes.sublist(0, end)).split('\r\n');
          // lines[0] is the boundary delimiter.
          final headers = lines.sublist(1)
            ..sort((a, b) {
              int rank(String h) =>
                  h.toLowerCase().startsWith('content-disposition') ? 0 : 1;
              return rank(a).compareTo(rank(b));
            });
          final head = latin1.encode([lines.first, ...headers].join('\r\n'));
          return Uint8List.fromList([...head, ...bytes.sublist(end)]);
        }),
      ),
    );
  }

  static int _indexOfHeaderEnd(Uint8List bytes) {
    for (var i = 0; i + 3 < bytes.length; i++) {
      if (bytes[i] == 13 &&
          bytes[i + 1] == 10 &&
          bytes[i + 2] == 13 &&
          bytes[i + 3] == 10) {
        return i;
      }
    }
    return -1;
  }
}

Future<String> transcribeVoice(ApiServices api, Uint8List audio) async {
  if (audio.length > 25 * 1024 * 1024) {
    throw const ApiException(
      statusCode: 413,
      message: 'Аудио должно быть не больше 25 МБ',
    );
  }
  final request =
      _VoiceUploadRequest('POST', Uri.parse('${api.baseUrl}/api/ai/transcribe'))
        // POST 303 redirects switch to GET and lose the recorded audio.
        // The documented API must return a transcript at this exact endpoint.
        ..followRedirects = false
        ..files.add(
          http.MultipartFile.fromBytes(
            'audio',
            audio,
            filename: 'description.wav',
            contentType: MediaType('audio', 'wav'),
          ),
        );
  try {
    final response = await api.client.sendMultipart(request);
    return readVoiceTranscript(response, requestUri: request.url);
  } on ApiException catch (error) {
    if ({301, 302, 303, 307, 308}.contains(error.statusCode)) {
      debugPrint(
        'Voice transcription redirect: POST '
        '${request.url.origin}${request.url.path}, HTTP ${error.statusCode}',
      );
      throw ApiException(
        statusCode: error.statusCode,
        message:
            'Сервер перенаправил запрос распознавания. Проверьте адрес API',
      );
    }
    rethrow;
  }
}

class VoiceDescriptionButton extends StatefulWidget {
  const VoiceDescriptionButton({
    super.key,
    required this.api,
    required this.onText,
    this.enabled = true,
    this.onBusyChanged,
    this.idleLabel,
  });
  final ApiServices api;
  final ValueChanged<String> onText;
  final bool enabled;
  final ValueChanged<bool>? onBusyChanged;
  final String? idleLabel;
  @override
  State<VoiceDescriptionButton> createState() => _VoiceDescriptionButtonState();
}

class _VoiceDescriptionButtonState extends State<VoiceDescriptionButton> {
  AudioRecorder? recorder;
  StreamSubscription<Uint8List>? subscription;
  StreamSubscription<RecordState>? stateSubscription;
  Completer<void>? streamDone;
  bool recordingFailed = false;
  Timer? timer;
  BytesBuilder audio = BytesBuilder(copy: false);
  bool recording = false, busy = false;
  @override
  void dispose() {
    timer?.cancel();
    subscription?.cancel();
    stateSubscription?.cancel();
    recorder?.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    if (busy) return;
    widget.onBusyChanged?.call(true);
    setState(() => busy = true);
    var transcribing = false;
    try {
      if (!recording) {
        recorder ??= AudioRecorder();
        if (!await recorder!.hasPermission()) {
          if (mounted) {
            showMessage(
              context,
              backendText(
                context,
                'Разрешите доступ к микрофону или введите текст.',
                'Микрофонға рұқсат беріңіз немесе мәтін енгізіңіз.',
              ),
            );
          }
          return;
        }
        audio = BytesBuilder(copy: false);
        recordingFailed = false;
        streamDone = Completer<void>();
        await stateSubscription?.cancel();
        stateSubscription = recorder!.onStateChanged().listen(
          (_) {},
          onError: (Object error, StackTrace stack) {
            debugPrint('Voice recording failed: $error');
            debugPrintStack(stackTrace: stack);
            recordingFailed = true;
            unawaited(cancelRecording(error));
          },
        );
        final stream = await recorder!.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );
        if (!mounted) {
          await recorder!.stop();
          return;
        }
        subscription = stream.listen(
          audio.add,
          onError: (Object error) {
            recordingFailed = true;
            unawaited(cancelRecording(error));
          },
          onDone: () {
            if (!streamDone!.isCompleted) streamDone!.complete();
          },
        );
        if (recordingFailed) return;
        setState(() => recording = true);
        // Keep the request below the documented 25 MB limit.
        timer = Timer(const Duration(minutes: 5), () => unawaited(toggle()));
      } else {
        timer?.cancel();
        await recorder!.stop();
        await streamDone?.future;
        await subscription?.cancel();
        subscription = null;
        if (!mounted) return;
        setState(() => recording = false);
        if (recordingFailed) return;
        final pcm = audio.takeBytes();
        if (pcm.isEmpty) {
          showMessage(
            context,
            backendText(
              context,
              'Микрофон не записал звук. Повторите запись.',
              'Микрофон дыбысты жазбады. Қайта жазыңыз.',
            ),
          );
          return;
        }
        transcribing = true;
        final text = await transcribeVoice(widget.api, voiceWav(pcm));
        if (mounted) widget.onText(text);
      }
    } catch (error, stack) {
      debugPrint(
        'Voice ${transcribing ? 'transcription' : 'recording'} failed: $error',
      );
      debugPrintStack(stackTrace: stack);
      await discardRecording();
      if (mounted) {
        setState(() => recording = false);
        showMessage(
          context,
          error is ApiException
              ? '${backendError(context, error)} ${transcribing ? '(HTTP ${error.statusCode}) ' : ''}${backendText(context, 'Можно повторить запись или ввести текст.', 'Қайта жазуға немесе мәтін енгізуге болады.')}'
              : backendText(
                  context,
                  transcribing
                      ? 'Не удалось отправить голос на распознавание. Проверьте соединение и повторите.'
                      : 'Не удалось включить микрофон. Проверьте разрешение и повторите запись.',
                  transcribing
                      ? 'Дауыс тануға жіберілмеді. Қосылымды тексеріп, қайталаңыз.'
                      : 'Микрофон қосылмады. Рұқсатты тексеріп, қайта жазыңыз.',
                ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        widget.onBusyChanged?.call(recording);
      }
    }
  }

  Future<void> discardRecording() async {
    timer?.cancel();
    try {
      await recorder?.cancel();
    } catch (error) {
      debugPrint('Voice recorder cleanup failed: $error');
    }
    await subscription?.cancel();
    subscription = null;
  }

  Future<void> cancelRecording(Object error) async {
    recordingFailed = true;
    await discardRecording();
    if (mounted) {
      widget.onBusyChanged?.call(false);
      setState(() {
        recording = false;
        busy = false;
      });
      showMessage(
        context,
        backendText(
          context,
          'Запись прервана. Повторите или введите текст.',
          'Жазу үзілді. Қайталаңыз немесе мәтін енгізіңіз.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: OutlinedButton.icon(
      onPressed: busy || !widget.enabled ? null : toggle,
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(recording ? Icons.stop : Icons.mic_none),
      label: Text(
        !busy && !recording && widget.idleLabel != null
            ? widget.idleLabel!
            : backendText(
                context,
                busy
                    ? 'Обработка голоса…'
                    : recording
                    ? 'Остановить и распознать'
                    : 'Голосовое описание',
                busy
                    ? 'Дауыс өңделуде…'
                    : recording
                    ? 'Тоқтату және тану'
                    : 'Дауыспен сипаттау',
              ),
      ),
    ),
  );
}
