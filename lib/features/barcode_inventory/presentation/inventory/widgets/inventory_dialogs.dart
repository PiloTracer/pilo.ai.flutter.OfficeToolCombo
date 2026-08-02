import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/widgets/quantity_stepper_field.dart';

typedef CreateItemResult = ({String name, int quantity, String description});

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

  void _submit() {
    final name = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim());
    final description = _descriptionController.text.trim();
    _nameError = name.isEmpty ? 'Enter an item name' : null;
    _qtyError = qty == null || qty < 0 || qty > 999999
        ? 'Enter a valid quantity'
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
    return AlertDialog(
      title: Semantics(label: 'New item dialog', child: const Text('New item')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Barcode / identifier',
                helperText: widget.barcode,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: InputDecoration(
                labelText: 'Item name',
                errorText: _nameError,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _qtyFocusNode.requestFocus(),
            ),
            const SizedBox(height: 12),
            QuantityStepperField(
              controller: _qtyController,
              focusNode: _qtyFocusNode,
              label: 'Starting quantity',
              helperText:
                  '↑/↓ or +/− to adjust · Enter for next · Shift+Enter for previous',
              errorText: _qtyError,
              onEnter: () => _descriptionFocusNode.requestFocus(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional notes (size, location, supplier…)',
                alignLabelWithHint: true,
              ),
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),
            if (widget.errorMessage != null) ...[
              const SizedBox(height: 12),
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
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add item')),
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

  void _submit() {
    final qty = int.tryParse(_qtyController.text.trim());
    _qtyError = qty == null || qty < 0 || qty > 999999
        ? 'Enter a valid quantity'
        : null;
    if (_qtyError != null) {
      setState(() {});
      return;
    }
    Navigator.of(context).pop(qty);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set counted quantity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Identifier: ${widget.barcode}'),
          const SizedBox(height: 12),
          QuantityStepperField(
            controller: _qtyController,
            focusNode: _qtyFocusNode,
            label: 'Quantity on hand',
            helperText: '↑/↓ or +/− to adjust · Enter to confirm',
            errorText: _qtyError,
            onEnter: _submit,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Set quantity')),
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
    return AlertDialog(
      title: const Text('Edit item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: const InputDecoration(labelText: 'Item name'),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _descriptionFocusNode.requestFocus(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _qtyFocusNode.requestFocus(),
            ),
            const SizedBox(height: 12),
            QuantityStepperField(
              controller: _qtyController,
              focusNode: _qtyFocusNode,
              label: 'Quantity on hand',
              helperText:
                  '↑/↓ or +/− to adjust · Enter for next · Shift+Enter for previous',
              onEnter: () => FocusScope.of(context).nextFocus(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
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

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Enter a barcode or identifier');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter identifier manually'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Barcode / SKU / alphanumeric ID',
            hintText: 'Type or paste an identifier',
            errorText: _error,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\x20-\x7E]+')),
          ],
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Submit')),
      ],
    );
  }
}
