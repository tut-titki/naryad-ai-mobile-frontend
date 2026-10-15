import 'package:mineral/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:mineral/l10n/ui_localization.dart';

class ExecutorMaterialTile extends StatelessWidget {
  const ExecutorMaterialTile({
    super.key,
    required this.name,
    required this.quantity,
    required this.onChanged,
    required this.onRemove,
  });
  final String name;
  final double quantity;
  final ValueChanged<double> onChanged;
  final VoidCallback onRemove;
  bool get _pieces => name.endsWith('шт');
  double get _step => _pieces ? 1 : .1;
  double _round(double value) => (value * 1000).round() / 1000;

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(text: quantity.toString());
    final form = GlobalKey<FormState>();
    final result = await showAppBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                uiText(context, name),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller,
                autofocus: true,
                selectAllOnFocus: true,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: !_pieces,
                ),
                decoration: InputDecoration(
                  labelText: strings(context).quantity,
                ),
                validator: (value) {
                  final n = double.tryParse((value ?? '').replaceAll(',', '.'));
                  if (n == null || !n.isFinite || n <= 0) {
                    return strings(context).positiveQuantity;
                  }
                  return _pieces && n != n.roundToDouble()
                      ? strings(context).wholePieceQuantity
                      : null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                ),
                onPressed: () {
                  if (form.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      double.parse(controller.text.replaceAll(',', '.')),
                    );
                  }
                },
                child: Text(strings(context).confirm),
              ),
            ],
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (result != null && context.mounted) onChanged(result);
  }

  Future<void> _remove(BuildContext context) async {
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings(context).removeMaterialQuestion,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(uiText(context, name)),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings(context).removeMaterial),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings(context).cancel),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) onRemove();
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F9FC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE5EAF2)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                uiText(context, name),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: strings(context).removeMaterial,
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              onPressed: () => _remove(context),
              icon: const Icon(
                Icons.delete_outline,
                size: 24,
                color: Color(0xFF687385),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _button(
              context,
              Icons.remove,
              strings(context).decrease,
              quantity > _step
                  ? () => onChanged(_round(quantity - _step))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed: () => _edit(context),
                child: Text(
                  quantity == quantity.roundToDouble()
                      ? '${quantity.toInt()}'
                      : '$quantity',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _button(
              context,
              Icons.add,
              strings(context).increase,
              () => onChanged(_round(quantity + _step)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _button(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) => SizedBox(
    width: 60,
    height: 60,
    child: IconButton.filledTonal(
      tooltip: label,
      onPressed: onTap,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 28),
    ),
  );
}
