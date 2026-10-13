import 'package:flutter/material.dart';
import 'package:mineral/l10n/app_locale.dart';
import 'package:mineral/l10n/app_localizations.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
    this.onBack,
    this.step,
    this.showLogo = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;
  final VoidCallback? onBack;
  final int? step;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF01408B);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E8ED)),
    );
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.copyWith(
          bodyLarge: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontSize: 17),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F9FB),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          labelStyle: const TextStyle(color: Color(0xFF687385), fontSize: 16),
          helperStyle: const TextStyle(color: Color(0xFF687385), fontSize: 14),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: blue, width: 1.5),
          ),
          errorBorder: border.copyWith(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
          focusedErrorBorder: border.copyWith(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 1.5,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: blue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: blue,
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                child: _languageMenu(context),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 48).clamp(
                          0,
                          double.infinity,
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showLogo) ...[
                                Align(
                                  alignment: Alignment.center,
                                  child: Image.asset(
                                    'assets/logo_naryadAi.png',
                                    width: 220,
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                              if (onBack != null) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: onBack,
                                      tooltip: AppLocalizations.of(
                                        context,
                                      ).back,
                                      icon: const Icon(
                                        Icons.arrow_back_ios_new,
                                        size: 22,
                                      ),
                                      style: IconButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        alignment: Alignment.centerLeft,
                                      ),
                                    ),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      ).stepLabel(step!),
                                      style: const TextStyle(
                                        color: Color(0xFF687385),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 32,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF182230),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Color(0xFF687385),
                                ),
                              ),
                              const SizedBox(height: 32),
                              child,
                              const SizedBox(height: 16),
                              footer,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageMenu(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<String>(
        initialValue: Localizations.localeOf(context).languageCode,
        tooltip: 'Русский / Қазақша',
        offset: const Offset(0, 44),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (language) {
          appLocale.value = Locale(language);
        },
        itemBuilder: (context) {
          final current = Localizations.localeOf(context).languageCode;

          return [
            for (final language in [
              ('ru', '🇷🇺', 'Русский'),
              ('kk', '🇰🇿', 'Қазақша'),
            ])
              PopupMenuItem<String>(
                value: language.$1,
                child: Row(
                  children: [
                    Text(language.$2, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(
                      language.$3,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: current == language.$1
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: current == language.$1
                            ? const Color(0xFF01408B)
                            : const Color(0xFF182230),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (current == language.$1)
                      const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Color(0xFF01408B),
                      ),
                  ],
                ),
              ),
          ];
        },
        icon: const Icon(
          Icons.language_rounded,
          size: 30,
          color: Color(0xFF01408B),
        ),
      ),
    );
  }
}
