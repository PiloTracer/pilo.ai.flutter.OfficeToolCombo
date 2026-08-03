import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/quantity_stepper_field.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

typedef CreateItemResult = ({String name, int quantity, String description});

/// Confirmation before a CSV import, which replaces the whole inventory.
class ImportConfirmationDialog extends StatelessWidget {
  const ImportConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.inventoryImportConfirmTitle),
      content: Text(l10n.inventoryImportConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.inventoryCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.inventoryImportConfirmAction),
        ),
      ],
    );
  }
}

class CreateItemDialog extends StatefulWidget {
  const CreateItemDialog({super.key, required this.barcode, this.errorMessage});

  final String barcode;
  final String? errorMessage;

  @override
  State<CreateItemDialog> createState() => _CreateItemDialogState();
}

class _CreateItemDialogState extends State<CreateItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final TextEditingController _descriptionController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _qtyFocusNode;
  late final FocusNode _descriptionFocusNode;
  String? _nameError;
  String? _qtyError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _qtyController = TextEditingController(text: '1');
    _descriptionController = TextEditingController();
    _nameFocusNode = FocusNode();
    _qtyFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _qtyFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    final name = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim());
    final description = _descriptionController.text.trim();
    _nameError = name.isEmpty ? l10n.inventoryErrorEnterName : null;
    _qtyError = qty == null || qty < 0 || qty > 999999
        ? l10n.inventoryErrorInvalidQuantity
        : null;
    if (_nameError != null || _qtyError != null) {
      setState(() {});
      return;
    }
    Navigator.of(
      context,
    ).pop((name: name, quantity: qty, description: description));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    return AlertDialog(
      title: Semantics(
        label: l10n.inventoryNewItemSemantics,
        child: Text(l10n.inventoryNewItemTitle),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: l10n.inventoryBarcodeIdentifierLabel,
                helperText: widget.barcode,
              ),
            ),
            spacing.gapMd,
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: InputDecoration(
                labelText: l10n.inventoryItemNameLabel,
                errorText: _nameError,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _qtyFocusNode.requestFocus(),
            ),
            spacing.gapMd,
            QuantityStepperField(
              controller: _qtyController,
              focusNode: _qtyFocusNode,
              label: l10n.inventoryStartingQuantityLabel,
              helperText: l10n.inventoryQuantityHelperNavigation,
              errorText: _qtyError,
              onEnter: () => _descriptionFocusNode.requestFocus(),
            ),
            spacing.gapMd,
            TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              decoration: InputDecoration(
                labelText: l10n.inventoryDescriptionLabel,
                hintText: l10n.inventoryDescriptionHint,
                alignLabelWithHint: true,
              ),
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),
            if (widget.errorMessage != null) ...[
              spacing.gapMd,
              Text(
                widget.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inventoryCancel),
        ),
        FilledButton(
          onPressed: () => _submit(l10n),
          child: Text(l10n.inventoryAddItem),
        ),
      ],
    );
  }
}

class CountQuantityDialog extends StatefulWidget {
  const CountQuantityDialog({
    super.key,
    required this.barcode,
    required this.currentQuantity,
  });

  final String barcode;
  final int currentQuantity;

  @override
  State<CountQuantityDialog> createState() => _CountQuantityDialogState();
}

class _CountQuantityDialogState extends State<CountQuantityDialog> {
  late final TextEditingController _qtyController;
  late final FocusNode _qtyFocusNode;
  String? _qtyError;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '${widget.currentQuantity}');
    _qtyFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _qtyFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    final qty = int.tryParse(_qtyController.text.trim());
    _qtyError = qty == null || qty < 0 || qty > 999999
        ? l10n.inventoryErrorInvalidQuantity
        : null;
    if (_qtyError != null) {
      setState(() {});
      return;
    }
    Navigator.of(context).pop(qty);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    return AlertDialog(
      title: Text(l10n.inventoryCountQuantityTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.inventoryIdentifierLine(widget.barcode)),
          spacing.gapMd,
          QuantityStepperField(
            controller: _qtyController,
            focusNode: _qtyFocusNode,
            label: l10n.inventoryQuantityOnHandLabel,
            helperText: l10n.inventoryQuantityHelperConfirm,
            errorText: _qtyError,
            onEnter: () => _submit(l10n),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inventoryCancel),
        ),
        FilledButton(
          onPressed: () => _submit(l10n),
          child: Text(l10n.inventorySetQuantity),
        ),
      ],
    );
  }
}

class EditItemDialog extends StatefulWidget {
  const EditItemDialog({
    super.key,
    required this.name,
    required this.description,
    required this.quantity,
  });

  final String name;
  final String description;
  final int quantity;

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _qtyController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _descriptionFocusNode;
  late final FocusNode _qtyFocusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _descriptionController = TextEditingController(text: widget.description);
    _qtyController = TextEditingController(text: '${widget.quantity}');
    _nameFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    _qtyFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _qtyController.dispose();
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim());
    if (name.isEmpty || qty == null || qty < 0) {
      return;
    }
    Navigator.of(context).pop((
      name: name,
      description: _descriptionController.text.trim(),
      quantity: qty,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    return AlertDialog(
      title: Text(l10n.inventoryEditItem),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: InputDecoration(
                labelText: l10n.inventoryItemNameLabel,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _descriptionFocusNode.requestFocus(),
            ),
            spacing.gapMd,
            TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              decoration: InputDecoration(
                labelText: l10n.inventoryDescriptionLabel,
                alignLabelWithHint: true,
              ),
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _qtyFocusNode.requestFocus(),
            ),
            spacing.gapMd,
            QuantityStepperField(
              controller: _qtyController,
              focusNode: _qtyFocusNode,
              label: l10n.inventoryQuantityOnHandLabel,
              helperText: l10n.inventoryQuantityHelperNavigation,
              onEnter: () => FocusScope.of(context).nextFocus(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inventoryCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.inventorySave)),
      ],
    );
  }
}

class ManualEntryDialog extends StatefulWidget {
  const ManualEntryDialog({super.key});

  @override
  State<ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<ManualEntryDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = l10n.inventoryErrorEnterBarcode);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.inventoryManualEntryTitle),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: l10n.inventoryManualEntryLabel,
            hintText: l10n.inventoryManualEntryHint,
            errorText: _error,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\x20-\x7E]+')),
          ],
          onSubmitted: (_) => _submit(l10n),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inventoryCancel),
        ),
        FilledButton(
          onPressed: () => _submit(l10n),
          child: Text(l10n.inventorySubmit),
        ),
      ],
    );
  }
}
