import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Numeric quantity field adjusted with keyboard arrows and +/− keys.
class QuantityStepperField extends StatefulWidget {
  const QuantityStepperField({
    super.key,
    required this.controller,
    this.focusNode,
    this.label = 'Quantity',
    this.helperText,
    this.errorText,
    this.min = 0,
    this.max = 999999,
    this.onChanged,
    this.onEnter,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? helperText;
  final String? errorText;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  /// Called when Enter is pressed without Shift. Defaults to moving focus forward.
  final VoidCallback? onEnter;

  @override
  State<QuantityStepperField> createState() => _QuantityStepperFieldState();
}

class _QuantityStepperFieldState extends State<QuantityStepperField> {
  FocusNode? _ownedNode;
  FocusNode? _attachedNode;
  FocusOnKeyEventCallback? _previousOnKeyEvent;
  FocusOnKeyEventCallback? _installedHandler;

  /// The node actually in use: the caller's when provided, else a lazily
  /// created one owned (and disposed) by this state.
  FocusNode get _effectiveNode =>
      widget.focusNode ?? (_ownedNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _attach(_effectiveNode);
  }

  @override
  void didUpdateWidget(covariant QuantityStepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _effectiveNode;
    if (_attachedNode != next) {
      _detach();
      _attach(next);
    }
    if (widget.focusNode != null && _ownedNode != null) {
      // The previously owned node is unused now that the caller supplied one.
      _ownedNode!.dispose();
      _ownedNode = null;
    }
  }

  /// Installs our key handling *around* any handler the node already has
  /// instead of clobbering it: keys we don't consume fall through to the
  /// previous handler.
  void _attach(FocusNode node) {
    _attachedNode = node;
    _previousOnKeyEvent = node.onKeyEvent;
    node.onKeyEvent = _installedHandler = (node, event) {
      final result = _handleKeyEvent(node, event);
      if (result != KeyEventResult.ignored) {
        return result;
      }
      return _previousOnKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
    };
  }

  void _detach() {
    final node = _attachedNode;
    // Restore only when our wrapper is still the installed handler — a
    // handler someone else installed afterwards must not be stomped.
    if (node != null && identical(node.onKeyEvent, _installedHandler)) {
      node.onKeyEvent = _previousOnKeyEvent;
    }
    _attachedNode = null;
    _previousOnKeyEvent = null;
    _installedHandler = null;
  }

  @override
  void dispose() {
    _detach();
    _ownedNode?.dispose();
    super.dispose();
  }

  int get _value {
    final parsed = int.tryParse(widget.controller.text.trim());
    return parsed ?? widget.min;
  }

  void _setValue(int next) {
    final clamped = next.clamp(widget.min, widget.max);
    widget.controller.text = '$clamped';
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    widget.onChanged?.call(clamped);
    setState(() {});
  }

  void _increment() => _setValue(_value + 1);

  void _decrement() => _setValue(_value - 1);

  bool _isIncrementKey(KeyDownEvent event) {
    final key = event.logicalKey;
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.numpadAdd ||
        (key == LogicalKeyboardKey.equal &&
            HardwareKeyboard.instance.isShiftPressed);
  }

  bool _isDecrementKey(KeyDownEvent event) {
    final key = event.logicalKey;
    return key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (_isIncrementKey(event)) {
      _increment();
      return KeyEventResult.handled;
    }

    if (_isDecrementKey(event)) {
      _decrement();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        FocusScope.of(context).previousFocus();
      } else if (widget.onEnter != null) {
        widget.onEnter!();
      } else {
        FocusScope.of(context).nextFocus();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _effectiveNode,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        errorText: widget.errorText,
        border: const OutlineInputBorder(),
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
    );
  }
}
