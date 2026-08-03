import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/merge_history_entry.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

class MergeHistoryList extends StatefulWidget {
  const MergeHistoryList({
    super.key,
    required this.entries,
    required this.onOpen,
  });

  final List<MergeHistoryEntry> entries;
  final ValueChanged<String> onOpen;

  @override
  State<MergeHistoryList> createState() => _MergeHistoryListState();
}

class _MergeHistoryListState extends State<MergeHistoryList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(localeName).add_jm();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: spacing.cardPadding,
            child: Text(
              l10n.consolidatorRecentMerges,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: spacing.cardPadding,
                      child: Text(
                        l10n.consolidatorHistoryEmpty,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: widget.entries.length > 4,
                    child: ListView.separated(
                      controller: _scrollController,
                      primary: false,
                      padding: EdgeInsets.zero,
                      itemCount: widget.entries.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = widget.entries[index];
                        return _MergeHistoryTile(
                          entry: entry,
                          formattedTime: dateFormat.format(entry.mergedAt),
                          onOpen: () => widget.onOpen(entry.outputPath),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MergeHistoryTile extends StatelessWidget {
  const _MergeHistoryTile({
    required this.entry,
    required this.formattedTime,
    required this.onOpen,
  });

  final MergeHistoryEntry entry;
  final String formattedTime;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isPartial = entry.status == 'partial';

    return Semantics(
      label: l10n.consolidatorMergedSemantics(entry.fileName, formattedTime),
      child: ListTile(
        leading: Icon(
          isPartial ? Icons.warning_amber_outlined : Icons.table_chart_outlined,
          color: isPartial ? scheme.tertiary : scheme.onSurfaceVariant,
        ),
        title: Text(
          entry.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          formattedTime,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: l10n.consolidatorOpenFileLocation,
          icon: const Icon(Icons.open_in_new),
          onPressed: onOpen,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.xs,
        ),
      ),
    );
  }
}
