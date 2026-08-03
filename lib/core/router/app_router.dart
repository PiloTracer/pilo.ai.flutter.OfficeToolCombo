import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:office_tool_combo/core/widgets/state_panel.dart';
import 'package:office_tool_combo/features/barcode_inventory/presentation/inventory/inventory_view.dart';
import 'package:office_tool_combo/features/home/presentation/home/home_view.dart';
import 'package:office_tool_combo/features/report_consolidator/presentation/consolidator/consolidator_view.dart';
import 'package:office_tool_combo/features/shell/presentation/tool_placeholder_view.dart';
import 'package:office_tool_combo/l10n/generated/app_localizations.dart';

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
        builder: (context, state) => const InventoryView(),
      ),
      GoRoute(
        path: '/tools/document-factory',
        name: 'document_factory',
        builder: (context, state) => ToolPlaceholderView(
          title: AppLocalizations.of(context).toolDocumentFactoryTitle,
          toolId: 'document_factory',
          icon: Icons.picture_as_pdf_outlined,
        ),
      ),
      GoRoute(
        path: '/tools/price-monitor',
        name: 'price_monitor',
        builder: (context, state) => ToolPlaceholderView(
          title: AppLocalizations.of(context).toolPriceMonitorTitle,
          toolId: 'price_monitor',
          icon: Icons.notifications_active_outlined,
        ),
      ),
      GoRoute(
        path: '/tools/scheduled-backup',
        name: 'scheduled_backup',
        builder: (context, state) => ToolPlaceholderView(
          title: AppLocalizations.of(context).toolScheduledBackupTitle,
          toolId: 'scheduled_backup',
          icon: Icons.backup_outlined,
        ),
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n.routerPageNotFoundTitle)),
        body: Center(
          child: StatePanel(
            icon: Icons.search_off_outlined,
            title: l10n.routerPageNotFoundHeading,
            message: state.error?.toString() ?? l10n.routerPageNotFoundFallback,
            action: FilledButton(
              onPressed: () => context.go('/'),
              child: Text(l10n.backToHomeTooltip),
            ),
          ),
        ),
      );
    },
  );
});
