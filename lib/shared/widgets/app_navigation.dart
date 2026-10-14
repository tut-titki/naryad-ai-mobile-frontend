import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mineral/core/theme/app_theme.dart';
import 'package:mineral/l10n/ui_localization.dart';

abstract final class AppNavigationItems {
  static const executor = [
    (LucideIcons.clipboardList, "Наряды"),
    (LucideIcons.calendarClock, "История"),
    (LucideIcons.userRound, "Профиль"),
  ];

  static const master = [
    (LucideIcons.layoutDashboard, 'Смена'),
    (LucideIcons.clipboardList, 'Наряды'),
    (LucideIcons.chartColumn, 'Отчёты'),
    (LucideIcons.messagesSquare, 'Чат'),
    (LucideIcons.userRound, 'Профиль'),
  ];
}

class AppNavigation extends StatelessWidget {
  final List<(IconData, String)> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.muted,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.muted,
            ),
          ),
        ),
        child: NavigationBar(
          height: 72,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          animationDuration: Duration(milliseconds: 400),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final item in items)
              NavigationDestination(
                label: uiText(context, item.$2),
                icon: Icon(item.$1),
                selectedIcon: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(item.$1),
                    Positioned(
                      top: -12,
                      child: Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
