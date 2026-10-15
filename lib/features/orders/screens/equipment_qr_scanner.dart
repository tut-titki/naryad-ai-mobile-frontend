import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../shared/widgets/backend_section.dart';

class EquipmentQrScanner extends StatefulWidget {
  const EquipmentQrScanner({super.key});
  @override
  State<EquipmentQrScanner> createState() => _EquipmentQrScannerState();
}

class _EquipmentQrScannerState extends State<EquipmentQrScanner> {
  bool _detected = false;
  bool _emptyInput = false;
  final _input = TextEditingController();
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _complete(String value) {
    if (_detected) return;
    if (value.trim().isEmpty) {
      setState(() => _emptyInput = true);
      return;
    }
    _detected = true;
    Navigator.pop(context, value.trim());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(backendText(context, 'QR оборудования', 'Жабдық QR коды')),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = math.min(
                  280.0,
                  math.min(constraints.maxWidth, constraints.maxHeight) * .78,
                );
                final scanWindow = Rect.fromCenter(
                  center: Offset(
                    constraints.maxWidth / 2,
                    constraints.maxHeight / 2,
                  ),
                  width: side,
                  height: side,
                );
                return MobileScanner(
                  scanWindow: scanWindow,
                  overlayBuilder: (context, constraints) => IgnorePointer(
                    child: CustomPaint(
                      painter: _ScanWindowPainter(scanWindow),
                      size: Size.infinite,
                    ),
                  ),
                  onDetect: (capture) {
                    for (final code in capture.barcodes) {
                      if (code.format == BarcodeFormat.qrCode &&
                          code.rawValue != null) {
                        _complete(code.rawValue!);
                        break;
                      }
                    }
                  },
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        backendText(
                          context,
                          'Камера недоступна. Разрешите доступ в настройках или вставьте ссылку из QR ниже.',
                          'Камера қолжетімсіз. Баптауларда рұқсат беріңіз немесе QR сілтемесін төменге енгізіңіз.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          /*Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  backendText(
                    context,
                    'Отсканируйте QR или введите текст из него ниже',
                    'QR кодын сканерлеңіз немесе оның мәтінін төменге енгізіңіз',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _input,
                  onChanged: (_) => setState(() => _emptyInput = false),
                  decoration: InputDecoration(
                    errorText: _emptyInput
                        ? backendText(
                            context,
                            'Введите текст из QR',
                            'QR мәтінін енгізіңіз',
                          )
                        : null,
                    labelText: backendText(
                      context,
                      'Текст или ссылка из QR',
                      'QR мәтіні немесе сілтемесі',
                    ),
                  ),
                  onSubmitted: _complete,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _input.text.trim().isEmpty
                      ? null
                      : () => _complete(_input.text),
                  child: Text(
                    backendText(context, 'Найти оборудование', 'Жабдықты табу'),
                  ),
                ),
              ],
            ),
          ),*/
        ],
      ),
    ),
  );
}

class _ScanWindowPainter extends CustomPainter {
  const _ScanWindowPainter(this.window);
  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(window, const Radius.circular(12));
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(frame);
    canvas.drawPath(mask, Paint()..color = Colors.black.withValues(alpha: .6));
    canvas.drawRRect(
      frame,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_ScanWindowPainter oldDelegate) =>
      oldDelegate.window != window;
}
