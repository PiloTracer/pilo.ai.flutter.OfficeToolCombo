import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// F0 placeholder for a tool route. Product behaviour arrives in F1–F5.
class ToolPlaceholderView extends StatelessWidget {
  const ToolPlaceholderView({
    super.key,
    required this.title,
    required this.toolId,
  });

  final String title;
  final String toolId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: 'Back to home',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$title is not implemented yet.\n'
            'Skeleton route for $toolId (milestone F0).',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
