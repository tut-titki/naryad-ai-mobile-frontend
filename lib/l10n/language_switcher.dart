import 'package:mineral/shared/widgets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:mineral/l10n/app_locale.dart';
import 'package:mineral/l10n/ui_localization.dart';

class ProfileLanguageTile extends StatelessWidget {
  const ProfileLanguageTile({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  });

  final EdgeInsetsGeometry padding;

  Future<void> _chooseLanguage(BuildContext context) async {
    final selected = Localizations.localeOf(context).languageCode;
    final locale = await showAppBottomSheet<Locale>(
      context: context,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings(context).language,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF01408B),
                ),
              ),
              const SizedBox(height: 20),
              for (final entry in const {
                'ru': 'Русский',
                'kk': 'Қазақша',
              }.entries) ...[
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: selected == entry.key
                          ? const Color(0xFF01408B)
                          : const Color(0xFFDCE4EE),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: selected == entry.key
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF5FAFF), Color(0xFFE3EEFC)],
                            )
                          : null,
                    ),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, Locale(entry.key)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3EEFC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                entry.key.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF01408B),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF172033),
                                ),
                              ),
                            ),
                            if (selected == entry.key)
                              const Icon(
                                LucideIcons.circleCheck,
                                color: Color(0xFF01408B),
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (entry.key == 'ru') const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
    if (locale != null) appLocale.value = locale;
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: strings(context).language,
    child: InkWell(
      onTap: () => _chooseLanguage(context),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            const Icon(LucideIcons.globe, size: 22, color: Color(0xFF01408B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings(context).language,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              Localizations.localeOf(context).languageCode == 'kk'
                  ? 'Қазақша'
                  : 'Русский',
              style: const TextStyle(color: Color(0xFF7A8597), fontSize: 13),
            ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: Color(0xFF7A8597),
            ),
          ],
        ),
      ),
    ),
  );
}
