import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:office_tool_combo/features/report_consolidator/domain/entities/spreadsheet_file_result.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_ui_state.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_view_model.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/widgets/failure_list.dart';

class ConsolidatorView extends ConsumerWidget {
  const ConsolidatorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consolidatorViewModelProvider);
    final viewModel = ref.read(consolidatorViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report consolidator'),
        leading: IconButton(
          tooltip: 'Back to home',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select a folder of Excel (.xlsx) reports. '
              'The app merges them into one workbook and lists any files that failed.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: state.phase == ConsolidatorPhase.loading
                  ? null
                  : viewModel.pickFolderAndMerge,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose folder and merge'),
            ),
            const SizedBox(height: 24),
            Expanded(child: _StateBody(state: state)),
          ],
        ),
      ),
    );
  }
}

class _StateBody extends StatelessWidget {
  const _StateBody({required this.state});

  final ConsolidatorUiState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      ConsolidatorPhase.loading => _LoadingBody(progress: state.progress),
      ConsolidatorPhase.empty => const _MessageBody(
        icon: Icons.inbox_outlined,
        title: 'No spreadsheets found',
        message:
            'That folder did not contain any .xlsx files to merge. '
            'Choose a different folder.',
      ),
      ConsolidatorPhase.partial => _SuccessBody(
        state: state,
        title: 'Merged with some failures',
      ),
      ConsolidatorPhase.error => _MessageBody(
        icon: Icons.error_outline,
        title: 'Merge failed',
        message: state.errorMessage ?? 'Something went wrong during merge.',
      ),
      ConsolidatorPhase.offline => _SuccessBody(
        state: state,
        title: 'Merge complete',
      ),
      ConsolidatorPhase.success => _SuccessBody(
        state: state,
        title: 'Merge complete',
      ),
    };
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Merging spreadsheets… ${(progress * 100).round()}%'),
        ],
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.state, required this.title});

  final ConsolidatorUiState state;
  final String title;

  @override
  Widget build(BuildContext context) {
    final failures =
        state.lastBatch?.files
            .where((f) => f.parseStatus == SpreadsheetParseStatus.failed)
            .toList(growable: false) ??
        const <SpreadsheetFileResult>[];

    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: Text(title),
          subtitle: Text(
            state.outputFileName == null
                ? 'Output saved in the selected folder.'
                : 'Saved as ${state.outputFileName}',
          ),
        ),
        if (failures.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Failed files', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FailureList(failures: failures),
        ],
      ],
    );
  }
}
