import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:office_tool_combo/core/theme/app_spacing.dart';

/// Shared scaffold for tool routes — consistent back navigation and layout.
class ToolShellScaffold extends StatelessWidget {
  const ToolShellScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: 'Back to home',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: actions,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(padding: spacing.screenPadding, child: body),
        ),
      ),
    );
  }
}
