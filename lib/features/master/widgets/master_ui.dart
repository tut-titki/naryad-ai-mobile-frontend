import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/ui_localization.dart';
import '../../executor/widgets/order_section.dart';

/// Visual tokens taken from ExecutorGreeting and ExecutorOrderScreen.
abstract final class MasterColors {
  static const blue = Color(0xFF01408B);
  static const background = Color(0xFFF5F7FB);
  static const ink = Color(0xFF17243B);
  static const muted = Color(0xFF687385);
  static const line = Color(0xFFE5EEFC);
  static const tint = Color(0xFFE6F1FF);
  static const gradient = LinearGradient(
    colors: [blue, Color(0xFF0A57A3)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class MasterTheme extends StatelessWidget {
  const MasterTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: MasterColors.background,
        expansionTileTheme: ExpansionTileThemeData(
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          textColor: MasterColors.ink,
          collapsedTextColor: MasterColors.ink,
          iconColor: MasterColors.blue,
          collapsedIconColor: MasterColors.muted,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: MasterColors.line),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: MasterColors.line),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: MasterColors.line),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: MasterColors.background,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MasterColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MasterColors.blue, width: 1.5),
          ),
        ),
      ),
      child: child,
    );
  }
}

class MasterScaffold extends StatelessWidget {
  const MasterScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.backgroundColor = MasterColors.background,
    this.enabled = true,
  });
  final AppBar? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final bar = appBar;
    final scaffold = Scaffold(
      backgroundColor: backgroundColor,
      appBar: !enabled || bar == null
          ? bar
          : AppBar(
              title: bar.title,
              actions: bar.actions,
              leading: bar.leading,
              automaticallyImplyLeading: bar.automaticallyImplyLeading,
              bottom: bar.bottom,
              titleSpacing: 16,
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: MasterColors.blue,
              foregroundColor: Colors.white,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              flexibleSpace: const DecoratedBox(
                decoration: BoxDecoration(gradient: MasterColors.gradient),
              ),
            ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
    return enabled ? MasterTheme(child: scaffold) : scaffold;
  }
}

class MasterSurface extends StatelessWidget {
  const MasterSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: MasterColors.line),
    ),
    child: child,
  );
}

class MasterSection extends StatelessWidget {
  const MasterSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => MasterSurface(
    child: OrderSection(icon: icon, title: title, child: child),
  );
}

class MasterMetric extends StatelessWidget {
  const MasterMetric({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => MasterSurface(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          uiText(context, title),
          style: const TextStyle(
            color: MasterColors.muted,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}

class MasterIntro extends StatelessWidget {
  const MasterIntro({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });
  final String title, subtitle;
  final IconData icon;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => MasterSurface(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MasterColors.tint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: MasterColors.blue, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                uiText(context, title),
                style: const TextStyle(
                  color: MasterColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                uiText(context, subtitle),
                style: const TextStyle(
                  color: MasterColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    ),
  );
}
