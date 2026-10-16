import 'package:go_router/go_router.dart';

import '../features/onboarding/screens/language_screen.dart';
import '../features/onboarding/screens/notification_permission_screen.dart';
import '../features/onboarding/screens/store_basics_screen.dart';
import '../features/onboarding/screens/data_source_screen.dart';
import '../features/onboarding/screens/onboarding_done_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/reorder/screens/reorder_list_screen.dart';
import '../features/overstock/screens/overstock_screen.dart';
import '../features/item_detail/screens/item_detail_screen.dart';
import '../features/export/screens/distributor_export_screen.dart';
import '../features/feedback/screens/feedback_prompt_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/sales_entry/screens/manual_entry_screen.dart';
import '../features/items/screens/item_catalog_screen.dart';
import '../features/items/screens/add_item_screen.dart';
import '../shared/widgets/app_shell.dart';

/// App router with deep-link support for push notification navigation.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    routes: [
      // ─── Auth ───
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ─── Onboarding Flow ───
      GoRoute(
        path: '/onboarding/language',
        name: 'onboarding-language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/onboarding/notifications',
        name: 'onboarding-notifications',
        builder: (context, state) => const NotificationPermissionScreen(),
      ),
      GoRoute(
        path: '/onboarding/store-basics',
        name: 'onboarding-store-basics',
        builder: (context, state) => const StoreBasicsScreen(),
      ),
      GoRoute(
        path: '/onboarding/data-source',
        name: 'onboarding-data-source',
        builder: (context, state) => const DataSourceScreen(),
      ),
      GoRoute(
        path: '/onboarding/done',
        name: 'onboarding-done',
        builder: (context, state) => const OnboardingDoneScreen(),
      ),

      // ─── Main App (with bottom nav shell) ───
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/items',
            name: 'items',
            builder: (context, state) => const ItemCatalogScreen(),
          ),
          GoRoute(
            path: '/reorder',
            name: 'reorder',
            builder: (context, state) => const ReorderListScreen(),
          ),
          GoRoute(
            path: '/overstock',
            name: 'overstock',
            builder: (context, state) => const OverstockScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // ─── Detail & Action Screens (outside shell) ───
      GoRoute(
        path: '/item/:itemId',
        name: 'item-detail',
        builder: (context, state) =>
            ItemDetailScreen(itemId: state.pathParameters['itemId']!),
      ),
      GoRoute(
        path: '/export',
        name: 'export',
        builder: (context, state) => const DistributorExportScreen(),
      ),
      GoRoute(
        path: '/feedback/:recId',
        name: 'feedback',
        builder: (context, state) => FeedbackPromptScreen(
          recommendationId: state.pathParameters['recId']!,
        ),
      ),
      GoRoute(
        path: '/items/add',
        name: 'items-add',
        builder: (context, state) => const AddItemScreen(),
      ),
      GoRoute(
        path: '/sales/add',
        name: 'sales-add',
        builder: (context, state) => const ManualEntryScreen(),
      ),
    ],
  );
}
