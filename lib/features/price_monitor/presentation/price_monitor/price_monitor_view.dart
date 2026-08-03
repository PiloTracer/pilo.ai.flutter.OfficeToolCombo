import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:office_tool_combo/core/theme/app_radii.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/core/theme/app_status_tone.dart';
import 'package:office_tool_combo/core/widgets/state_panel.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_sample.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_l10n.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_ui_state.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_view_model.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/widgets/watch_editor_dialog.dart';
import 'package:office_tool_combo/features/shell/presentation/tool_shell_scaffold.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

class PriceMonitorView extends ConsumerStatefulWidget {
  const PriceMonitorView({super.key});

  @override
  ConsumerState<PriceMonitorView> createState() => _PriceMonitorViewState();
}

class _PriceMonitorViewState extends ConsumerState<PriceMonitorView> {
  var _loadedInitialState = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    ref
        .read(priceMonitorViewModelProvider.notifier)
        .configureAlertPresentation(
          titleBuilder: (alert) =>
              l10n.priceMonitorAlertTitle(alert.watch.label),
          bodyBuilder: (alert) => l10n.priceMonitorAlertBody(
            alert.price.toString(),
            alert.watch.threshold.toString(),
          ),
          includeSystemSettingsHint: Platform.isMacOS,
        );
    if (!_loadedInitialState) {
      _loadedInitialState = true;
      unawaited(
        ref.read(priceMonitorViewModelProvider.notifier).loadInitialState(),
      );
    }
  }

  Future<void> _openEditor({PriceWatch? watch}) async {
    await showWatchEditorDialog(context, ref, watch: watch);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceMonitorViewModelProvider);
    final viewModel = ref.read(priceMonitorViewModelProvider.notifier);
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return ToolShellScaffold(
      title: l10n.toolPriceMonitorTitle,
      body: switch (state.status) {
        PriceMonitorStatus.loading => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              spacing.gapMd,
              Text(l10n.priceMonitorLoading),
            ],
          ),
        ),
        PriceMonitorStatus.error => StatePanel(
          icon: Icons.error_outline,
          iconColor: AppStatusTone.errorForegroundOf(context),
          iconBackgroundColor: AppStatusTone.errorBackgroundOf(context),
          title: l10n.priceMonitorLoadErrorTitle,
          message: l10n.priceMonitorFailureMessage(state.errorCode ?? ''),
          action: FilledButton.icon(
            onPressed: viewModel.tryAgain,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.priceMonitorTryAgain),
          ),
        ),
        PriceMonitorStatus.ready => ListView(
          children: [
            Text(
              l10n.toolPriceMonitorTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            spacing.gapSm,
            Text(
              l10n.priceMonitorIntro,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            spacing.gapLg,
            if (state.isOffline) ...[const _OfflineBadge(), spacing.gapMd],
            if (state.banner != null) ...[
              _AlertBanner(
                banner: state.banner!,
                onDismiss: viewModel.dismissBanner,
              ),
              spacing.gapMd,
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: Text(l10n.priceMonitorAddWatch),
              ),
            ),
            spacing.gapMd,
            if (state.watches.isEmpty)
              StatePanel(
                icon: Icons.watch_off_outlined,
                title: l10n.priceMonitorEmptyTitle,
                message: l10n.priceMonitorEmptyMessage,
              )
            else
              ...state.watches.map(
                (watch) => Padding(
                  padding: EdgeInsets.only(bottom: spacing.sm),
                  child: _WatchCard(
                    watch: watch,
                    sample: state.samples[watch.id],
                    isOffline: state.isOffline,
                    onToggle: (enabled) => viewModel.setEnabled(watch, enabled),
                    onEdit: () => _openEditor(watch: watch),
                    onRetry: () => viewModel.retryNow(watch),
                  ),
                ),
              ),
            spacing.gapLg,
          ],
        ),
      },
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radii = context.radii;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      liveRegion: true,
      label: l10n.priceMonitorOfflineSemantics,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppStatusTone.warningBackgroundOf(context),
          borderRadius: radii.smAll,
        ),
        child: Padding(
          padding: spacing.cardPadding,
          child: Row(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                color: AppStatusTone.warningForegroundOf(context),
                semanticLabel: '',
              ),
              spacing.gapMd,
              Expanded(
                child: Text(
                  l10n.priceMonitorOfflineBadge,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppStatusTone.warningForegroundOf(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.banner, required this.onDismiss});

  final PriceBannerAlert banner;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radii = context.radii;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppStatusTone.warningBackgroundOf(context),
          borderRadius: radii.smAll,
        ),
        child: Padding(
          padding: spacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: AppStatusTone.warningForegroundOf(context),
                semanticLabel: '',
              ),
              spacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppStatusTone.warningForegroundOf(context),
                      ),
                    ),
                    spacing.gapXs,
                    Text(
                      banner.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppStatusTone.warningForegroundOf(context),
                      ),
                    ),
                    if (banner.showSystemSettingsHint) ...[
                      spacing.gapXs,
                      Text(
                        l10n.priceMonitorMacNotifyHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppStatusTone.warningForegroundOf(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              spacing.gapSm,
              TextButton(
                onPressed: onDismiss,
                child: Text(l10n.priceMonitorDismiss),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchCard extends StatelessWidget {
  const _WatchCard({
    required this.watch,
    required this.sample,
    required this.isOffline,
    required this.onToggle,
    required this.onEdit,
    required this.onRetry,
  });

  final PriceWatch watch;
  final PriceSample? sample;
  final bool isOffline;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    final direction = watch.direction == PriceWatchDirection.above
        ? l10n.priceMonitorAbove
        : l10n.priceMonitorBelow;
    final priceText = sample?.price?.toString() ?? l10n.priceMonitorNotFetched;
    final updatedText = sample == null
        ? l10n.priceMonitorNotFetched
        : l10n.priceMonitorUpdated(
            DateFormat.yMd(locale).add_jm().format(sample!.fetchedAt.toLocal()),
          );

    return Semantics(
      label: l10n.priceMonitorRowSemantics(
        watch.label,
        priceText,
        updatedText,
        direction,
        watch.threshold.toString(),
        watch.enabled
            ? l10n.priceMonitorStateEnabled
            : l10n.priceMonitorStateDisabled,
      ),
      child: Card(
        child: Padding(
          padding: spacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      watch.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: watch.enabled ? null : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (isOffline && watch.enabled)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.cloud_off_outlined, size: 16),
                      label: Text(l10n.priceMonitorOfflineChip),
                    ),
                  Semantics(
                    label: l10n.priceMonitorToggleSemantics(watch.label),
                    child: Switch(value: watch.enabled, onChanged: onToggle),
                  ),
                ],
              ),
              spacing.gapSm,
              if (sample != null &&
                  sample!.status == PriceSampleStatus.failed) ...[
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      size: 18,
                      color: AppStatusTone.warningForegroundOf(context),
                      semanticLabel: '',
                    ),
                    SizedBox(width: spacing.xs),
                    Expanded(
                      child: Text(
                        '${l10n.priceMonitorFetchFailed} — '
                        '${l10n.priceMonitorParseFailed}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppStatusTone.warningForegroundOf(context),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: watch.enabled && !isOffline ? onRetry : null,
                      child: Text(l10n.priceMonitorRetryNow),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  priceText,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                spacing.gapXs,
                Text(
                  updatedText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              spacing.gapSm,
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.priceMonitorAlertLine(
                        direction,
                        watch.threshold.toString(),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.priceMonitorEdit),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
