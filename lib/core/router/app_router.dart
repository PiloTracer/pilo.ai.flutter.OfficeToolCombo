import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:office_tool_combo/features/home/presentation/home/home_view.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_view.dart';
import 'package:office_tool_combo/features/shell/presentation/tool_placeholder_view.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/tools/report-consolidator',
        name: 'report_consolidator',
        builder: (context, state) => const ConsolidatorView(),
      ),
      GoRoute(
        path: '/tools/barcode-inventory',
        name: 'barcode_inventory',
        builder: (context, state) => const ToolPlaceholderView(
          title: 'Barcode inventory',
          toolId: 'barcode_inventory',
        ),
      ),
      GoRoute(
        path: '/tools/document-factory',
        name: 'document_factory',
        builder: (context, state) => const ToolPlaceholderView(
          title: 'Document factory',
          toolId: 'document_factory',
        ),
      ),
      GoRoute(
        path: '/tools/price-monitor',
        name: 'price_monitor',
        builder: (context, state) => const ToolPlaceholderView(
          title: 'Price monitor',
          toolId: 'price_monitor',
        ),
      ),
      GoRoute(
        path: '/tools/scheduled-backup',
        name: 'scheduled_backup',
        builder: (context, state) => const ToolPlaceholderView(
          title: 'Scheduled backup',
          toolId: 'scheduled_backup',
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text(state.error?.toString() ?? 'Route not found')),
    ),
  );
});
