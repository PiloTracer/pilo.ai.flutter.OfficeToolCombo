import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/features/price_monitor/domain/entities/price_watch.dart';
import 'package:office_tool_combo/features/price_monitor/domain/repositories/price_monitor_repository.dart';
import 'package:office_tool_combo/features/price_monitor/domain/validation/watch_validator.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_l10n.dart';
import 'package:office_tool_combo/features/price_monitor/presentation/price_monitor/price_monitor_view_model.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

/// Opens the watch editor (SPEC §5 — modal dialog). Pass [watch] to edit,
/// or null to create. Save/delete go through the view model so the list
/// refreshes in place.
Future<void> showWatchEditorDialog(
  BuildContext context,
  WidgetRef ref, {
  PriceWatch? watch,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _WatchEditorDialog(watch: watch, ref: ref),
  );
}

class _WatchEditorDialog extends StatefulWidget {
  const _WatchEditorDialog({required this.watch, required this.ref});

  final PriceWatch? watch;
  final WidgetRef ref;

  @override
  State<_WatchEditorDialog> createState() => _WatchEditorDialogState();
}

class _WatchEditorDialogState extends State<_WatchEditorDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _urlController;
  late final TextEditingController _thresholdController;
  late final FocusNode _labelFocus;
  late final FocusNode _urlFocus;
  late final FocusNode _thresholdFocus;

  late PriceWatchDirection _direction;
  late bool _enabled;
  var _dirty = false;

  String? _labelErrorCode;
  String? _urlErrorCode;
  String? _thresholdErrorCode;

  bool get _isEditing => widget.watch != null;

  @override
  void initState() {
    super.initState();
    final watch = widget.watch;
    _labelController = TextEditingController(text: watch?.label ?? '');
    _urlController = TextEditingController(text: watch?.url ?? '');
    _thresholdController = TextEditingController(
      text: watch?.threshold.toString() ?? '',
    );
    _labelFocus = FocusNode();
    _urlFocus = FocusNode();
    _thresholdFocus = FocusNode();
    _direction = watch?.direction ?? PriceWatchDirection.above;
    _enabled = watch?.enabled ?? true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _urlController.dispose();
    _thresholdController.dispose();
    _labelFocus.dispose();
    _urlFocus.dispose();
    _thresholdFocus.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final labelCode = WatchValidator.validateLabel(_labelController.text);
    final urlCode = WatchValidator.validateUrl(_urlController.text);
    final thresholdCode = WatchValidator.validateThreshold(
      _thresholdController.text,
    );
    setState(() {
      _labelErrorCode = labelCode;
      _urlErrorCode = urlCode;
      _thresholdErrorCode = thresholdCode;
    });
    // SPEC §12 — invalid field receives focus on failed save.
    if (labelCode != null) {
      _labelFocus.requestFocus();
      return;
    }
    if (urlCode != null) {
      _urlFocus.requestFocus();
      return;
    }
    if (thresholdCode != null) {
      _thresholdFocus.requestFocus();
      return;
    }

    final existing = widget.watch;
    final watch = PriceWatch(
      id: existing?.id ?? PriceWatchIdGenerator.nextId(),
      label: _labelController.text.trim(),
      url: _urlController.text.trim(),
      threshold: Decimal.parse(_thresholdController.text.trim()),
      direction: _direction,
      enabled: _enabled,
    );
    final result = await widget.ref
        .read(priceMonitorViewModelProvider.notifier)
        .saveWatch(watch);
    if (!mounted) return;
    result.when(
      success: (_) => Navigator.of(context).pop(),
      failure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.priceMonitorFailureMessage(failure.message)),
          ),
        );
      },
    );
  }

  Future<void> _cancel() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    // SPEC §4.6 — dirty cancel asks before discarding.
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: Text(l10n.priceMonitorDiscardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmContext).pop(false),
            child: Text(l10n.priceMonitorKeepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.of(confirmContext).pop(true),
            child: Text(l10n.priceMonitorDiscard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final watch = widget.watch;
    if (watch == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    // SPEC §4.2 — delete always confirms first.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: Text(l10n.priceMonitorDeleteConfirmTitle),
        content: Text(l10n.priceMonitorDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmContext).pop(false),
            child: Text(l10n.priceMonitorCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(confirmContext).pop(true),
            child: Text(l10n.priceMonitorDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await widget.ref
        .read(priceMonitorViewModelProvider.notifier)
        .deleteWatch(watch.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        _isEditing
            ? l10n.priceMonitorEditorTitleEdit
            : l10n.priceMonitorEditorTitleNew,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _labelController,
                focusNode: _labelFocus,
                maxLength: PriceWatch.maxLabelLength,
                decoration: InputDecoration(
                  labelText: l10n.priceMonitorFieldLabel,
                  errorText: _labelErrorCode == null
                      ? null
                      : l10n.priceMonitorFailureMessage(_labelErrorCode!),
                ),
                onChanged: (_) => _markDirty(),
              ),
              spacing.gapSm,
              TextField(
                controller: _urlController,
                focusNode: _urlFocus,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.priceMonitorFieldUrl,
                  errorText: _urlErrorCode == null
                      ? null
                      : l10n.priceMonitorFailureMessage(_urlErrorCode!),
                ),
                onChanged: (_) => _markDirty(),
              ),
              spacing.gapSm,
              TextField(
                controller: _thresholdController,
                focusNode: _thresholdFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.priceMonitorFieldThreshold,
                  errorText: _thresholdErrorCode == null
                      ? null
                      : l10n.priceMonitorFailureMessage(_thresholdErrorCode!),
                ),
                onChanged: (_) => _markDirty(),
              ),
              spacing.gapMd,
              Text(
                l10n.priceMonitorNotifyWhen,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              spacing.gapSm,
              SegmentedButton<PriceWatchDirection>(
                segments: [
                  ButtonSegment(
                    value: PriceWatchDirection.above,
                    label: Text(l10n.priceMonitorAbove),
                  ),
                  ButtonSegment(
                    value: PriceWatchDirection.below,
                    label: Text(l10n.priceMonitorBelow),
                  ),
                ],
                selected: {_direction},
                onSelectionChanged: (selection) {
                  setState(() => _direction = selection.first);
                  _markDirty();
                },
              ),
              spacing.gapSm,
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.priceMonitorEnabled),
                value: _enabled,
                onChanged: (value) {
                  setState(() => _enabled = value);
                  _markDirty();
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton(onPressed: _delete, child: Text(l10n.priceMonitorDelete)),
        TextButton(onPressed: _cancel, child: Text(l10n.priceMonitorCancel)),
        FilledButton(onPressed: _save, child: Text(l10n.priceMonitorSave)),
      ],
    );
  }
}
