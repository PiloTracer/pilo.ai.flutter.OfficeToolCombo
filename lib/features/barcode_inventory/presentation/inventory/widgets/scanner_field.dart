import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Always-ready scan field for USB/Bluetooth HID wedge readers.
///
/// When [captureFocus] is true, the field stays ready for wedge input but
/// yields to any other text entry on the screen (search boxes, dialogs, etc.).
class ScannerField extends StatefulWidget {
  const ScannerField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmitted,
    this.captureFocus = true,
    this.label = 'Barcode scan field',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool captureFocus;
  final Future<void> Function(String value) onSubmitted;
  final String label;

  @override
  State<ScannerField> createState() => _ScannerFieldState();
}

class _ScannerFieldState extends State<ScannerField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
    if (widget.captureFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFocus());
    }
  }

  @override
  void didUpdateWidget(covariant ScannerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.captureFocus &&
        widget.enabled &&
        (!oldWidget.enabled || !oldWidget.captureFocus)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFocus());
    }
    if (!widget.captureFocus && oldWidget.captureFocus) {
      widget.focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  /// Whether another text-entry widget currently owns primary focus.
  static bool anotherTextInputHasFocus(FocusNode scannerFocusNode) {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null || primary == scannerFocusNode) {
      return false;
    }
    return isTextEntryFocus(primary);
  }

  static bool isTextEntryFocus(FocusNode node) {
    final context = node.context;
    if (context == null) {
      return false;
    }
    if (context.widget is EditableText) {
      return true;
    }
    return context.findAncestorWidgetOfExactType<TextField>() != null ||
        context.findAncestorWidgetOfExactType<TextFormField>() != null;
  }

  void _handleFocusChange() {
    if (!widget.enabled || !widget.captureFocus || widget.focusNode.hasFocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _refocusIfIdle());
  }

  void _refocusIfIdle() {
    if (!mounted ||
        !widget.enabled ||
        !widget.captureFocus ||
        widget.focusNode.hasFocus) {
      return;
    }
    if (anotherTextInputHasFocus(widget.focusNode)) {
      return;
    }
    widget.focusNode.requestFocus();
  }

  void _ensureFocus() {
    if (!widget.enabled || !widget.captureFocus || widget.focusNode.hasFocus) {
      return;
    }
    if (anotherTextInputHasFocus(widget.focusNode)) {
      return;
    }
    widget.focusNode.requestFocus();
  }

  Future<void> _handleSubmit(String value) async {
    await widget.onSubmitted(value);
    if (!mounted) {
      return;
    }
    widget.controller.clear();
    if (!widget.captureFocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _refocusIfIdle());
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      textField: true,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        autofocus: widget.captureFocus,
        decoration: const InputDecoration(
          labelText: 'Scan barcode',
          hintText: 'Scan barcode…',
          prefixIcon: Icon(Icons.qr_code_scanner_outlined),
          border: OutlineInputBorder(),
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: _handleSubmit,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\x20-\x7E]+')),
        ],
      ),
    );
  }
}
