import '../../master/widgets/master_ui.dart';
import 'package:flutter/material.dart';

import 'package:mineral/l10n/ui_localization.dart';
import 'package:mineral/shared/data/demo_store.dart';
import 'package:mineral/shared/widgets/ui.dart';

class BrigadeMembersScreen extends StatelessWidget {
  const BrigadeMembersScreen({
    super.key,
    required this.store,
    required this.brigade,
  });
  final DemoStore store;
  final String brigade;

  @override
  Widget build(BuildContext context) => MasterScaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: Text(uiText(context, brigade))),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            strings(context).brigadeMembers,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          BrigadeChoice(brigade: brigade, store: store),
          const SizedBox(height: 24),
          for (final member in store.brigadeMembers(brigade)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: lightBlue,
                    child: Text(
                      member.initials,
                      style: const TextStyle(color: brand),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: EmployeeChoice(employee: member, store: store),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: border),
          ],
        ],
      ),
    ),
  );
}
