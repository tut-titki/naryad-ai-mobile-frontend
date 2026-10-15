import '../../master/widgets/master_ui.dart';
import 'package:flutter/material.dart';
import '../../../core/api/api_services.dart';
import '../../orders/data/references_api.dart';
import '../../../l10n/ui_localization.dart';
import '../../../shared/widgets/backend_section.dart';
import '../../../shared/widgets/backend_refresh_view.dart';
import '../../../shared/widgets/ui.dart';

class BackendEmployeeCard extends StatelessWidget {
  const BackendEmployeeCard({super.key, required this.executor});
  final ExecutorReference executor;
  @override
  Widget build(BuildContext context) => MasterSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: lightBlue,
            child: Text(
              executor.fullName
                  .split(' ')
                  .where((p) => p.isNotEmpty)
                  .take(2)
                  .map((p) => p[0])
                  .join(),
            ),
          ),
          title: Text(
            executor.fullName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(uiText(context, executor.qualification)),
        ),
        StatusTag(
          executor.statusLabel,
          color: executor.isOnShift
              ? executor.employeeStatus.color
              : EmployeeStatus.offShift.color,
        ),
        const SizedBox(height: 12),
        Text(
          backendText(
            context,
            'Назначено нарядов: ${executor.assignedOrders}',
            'Тағайындалған нарядтар: ${executor.assignedOrders}',
          ),
        ),
      ],
    ),
  );
}

class _TeamData {
  const _TeamData(this.executors, this.brigades);
  final List<ExecutorReference> executors;
  final List<BrigadeReference> brigades;
}

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key, required this.api});
  final ApiServices api;
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  String search = '';
  bool onlyFree = false;
  Future<_TeamData> _load() async {
    final results = await Future.wait<Object>([
      widget.api.references.getExecutors(),
      widget.api.references.getBrigades(refresh: true),
    ]);
    return _TeamData(
      results[0] as List<ExecutorReference>,
      results[1] as List<BrigadeReference>,
    );
  }

  bool _matches(ExecutorReference e) =>
      (!onlyFree ||
          (e.isOnShift && e.employeeStatus == EmployeeStatus.available)) &&
      '${e.fullName} ${e.qualification} ${uiText(context, e.qualification)}'
          .toLowerCase()
          .contains(search.trim().toLowerCase());

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const MasterIntro(
        title: 'Команда',
        icon: Icons.groups_outlined,
        subtitle: 'Загрузка исполнителей, специальности и доступность',
      ),
      const SizedBox(height: 12),
      TextField(
        onChanged: (text) => setState(() => search = text),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: strings(context).teamBrigadeSearch,
        ),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: FilterChip(
          label: Text(uiText(context, 'Только свободные')),
          selected: onlyFree,
          onSelected: (value) => setState(() => onlyFree = value),
        ),
      ),
      BackendSection<_TeamData>(
        load: _load,
        changes: widget.api.realtime.changes,
        builder: (context, data) {
          final byId = {for (final e in data.executors) e.id: e};
          final grouped = data.brigades
              .expand((b) => b.members)
              .map((m) => m.id)
              .toSet();
          final brigades = data.brigades
              .where(
                (b) =>
                    (b.name.toLowerCase().contains(search.toLowerCase()) &&
                        (!onlyFree ||
                            b.members.any(
                              (m) =>
                                  byId[m.id]?.isOnShift == true &&
                                  byId[m.id]?.employeeStatus ==
                                      EmployeeStatus.available,
                            ))) ||
                    b.members.any(
                      (m) => byId[m.id] != null && _matches(byId[m.id]!),
                    ),
              )
              .toList();
          final ungrouped = data.executors
              .where((e) => !grouped.contains(e.id) && _matches(e))
              .toList();
          if (brigades.isEmpty && ungrouped.isEmpty) {
            return Panel(
              child: Text(uiText(context, 'Исполнители не найдены')),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final brigade in brigades) ...[
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: lightBlue,
                    child: Icon(Icons.groups_outlined, color: brand),
                  ),
                  title: Text(uiText(context, brigade.name)),
                  subtitle: Text(
                    backendText(
                      context,
                      'Участников: ${brigade.members.length}',
                      'Қатысушылар: ${brigade.members.length}',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => BackendBrigadeMembersScreen(
                        api: widget.api,
                        brigadeId: brigade.id,
                        title: brigade.name,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: border),
              ],
              if (ungrouped.isNotEmpty) ...[
                const SizedBox(height: 16),
                AdaptiveGrid(
                  minWidth: 260,
                  children: [
                    for (final e in ungrouped) BackendEmployeeCard(executor: e),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    ],
  );
}

class BackendBrigadeMembersScreen extends StatelessWidget {
  const BackendBrigadeMembersScreen({
    super.key,
    required this.api,
    required this.brigadeId,
    required this.title,
  });
  final ApiServices api;
  final int brigadeId;
  final String title;
  @override
  Widget build(BuildContext context) => MasterScaffold(
    appBar: AppBar(title: Text(uiText(context, title))),
    body: BackendRefreshView(
      padding: const EdgeInsets.all(24),
      child: BackendSection<_TeamData>(
        changes: api.realtime.changes,
        load: () async {
          final values = await Future.wait<Object>([
            api.references.getExecutors(),
            api.references.getBrigades(refresh: true),
          ]);
          return _TeamData(
            values[0] as List<ExecutorReference>,
            values[1] as List<BrigadeReference>,
          );
        },
        builder: (context, data) {
          final brigade = data.brigades
              .where((b) => b.id == brigadeId)
              .firstOrNull;
          if (brigade == null || brigade.members.isEmpty) {
            return Text(
              backendText(
                context,
                'В бригаде нет участников',
                'Бригадада қатысушылар жоқ',
              ),
            );
          }
          final executors = {for (final e in data.executors) e.id: e};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeading(strings(context).brigadeMembers),
              for (final member in brigade.members)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: executors[member.id] == null
                      ? Panel(
                          child: ListTile(
                            title: Text(member.fullName),
                            subtitle: Text(
                              uiText(context, member.specialty ?? '—'),
                            ),
                          ),
                        )
                      : BackendEmployeeCard(executor: executors[member.id]!),
                ),
            ],
          );
        },
      ),
    ),
  );
}
