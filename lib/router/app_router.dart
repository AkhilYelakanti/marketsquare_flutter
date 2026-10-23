import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/datasync/data_sync_screen.dart';
import '../features/invoices/invoice_detail_screen.dart';
import '../features/invoices/invoice_list_screen.dart';
import '../features/invoices/invoice_pdf_screen.dart';
import '../features/backroom/backroom_inventory_screen.dart';
import '../features/backroom/reset_inventory_screen.dart';
import '../features/backroom/update_inventory_screen.dart';
import '../features/backroom/view_pull_list_screen.dart';
import '../features/help/debug_screen.dart';
import '../features/help/help_screen.dart';
import '../features/help/operational_guide_screen.dart';
import '../features/help/scan_debug_screen.dart';
import '../features/itemcatalog/catalog_list_screen.dart';
import '../features/itemcatalog/item_catalog_screen.dart';
import '../features/itemcatalog/item_filtered_list_screen.dart';
import '../features/itemcatalog/item_images_screen.dart';
import '../features/itemcatalog/saved_items_screen.dart';
import '../features/messages/messages_screen.dart';
import '../features/itemcatalog/item_detail_screen.dart';
import '../features/itemcatalog/item_search_screen.dart';
import '../features/refreshdata/refresh_data_screen.dart';
import '../features/repflow/choose_active_customer_screen.dart';
import '../features/revieworders/approval_order_detail_screen.dart';
import '../features/revieworders/approvals_list_screen.dart';
import '../features/revieworders/order_approval_screen.dart';
import '../features/revieworders/review_orders_screen.dart';
import '../features/revieworders/select_store_screen.dart';
import '../features/revieworders/store_order_detail_screen.dart';
import '../features/revieworders/store_orders_list_screen.dart';
import '../features/revieworders/view_device_orders_screen.dart';
import '../features/login/login_screen.dart';
import '../features/orderentry/mults_returned_screen.dart';
import '../features/orderentry/order_filling_screen.dart';
import '../features/orderentry/order_header_screen.dart';
import '../features/orderentry/order_item_search_screen.dart';
import '../features/orderentry/select_customer_screen.dart';
import '../features/otheroptions/other_options_screen.dart';
import '../features/orderentry/select_order_type_screen.dart';
import '../features/orderentry/select_partition_screen.dart';
import '../features/orderentry/standing_orders_screen.dart';
import '../features/sendorders/order_minimum_screen.dart';
import '../features/sendorders/recommended_items_screen.dart';
import '../features/sendorders/send_orders_screen.dart';
import '../features/sendorders/submit_order_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/tos/tos_screen.dart';
import '../widgets/placeholder_screen.dart';
import 'app_routes.dart';

/// Builds the app router. Fully-ported screens are wired to real widgets; every
/// other native route resolves to a [PlaceholderScreen] so the whole navigation
/// graph is browsable while modules are ported area-by-area.
GoRouter createRouter() {
  GoRoute placeholder(String path, String title) => GoRoute(
        path: path,
        builder: (_, _) => PlaceholderScreen(title),
      );

  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      // ── Ported slice ──────────────────────────────────────────────────────
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
          path: Routes.userSetup,
          builder: (_, _) => const LoginScreen(isUserSetup: true)),
      GoRoute(path: Routes.tos, builder: (_, _) => const TosScreen()),
      GoRoute(path: Routes.dataSync, builder: (_, _) => const DataSyncScreen()),
      GoRoute(path: Routes.dashboard, builder: (_, _) => const DashboardScreen()),
      GoRoute(
          path: Routes.orderEntry,
          builder: (_, _) => const SelectCustomerScreen()),
      GoRoute(path: Routes.itemCatalog, builder: (_, _) => const ItemCatalogScreen()),
      GoRoute(path: Routes.itemSearch, builder: (_, _) => const ItemSearchScreen()),
      GoRoute(
        path: Routes.itemDetail,
        builder: (_, s) =>
            ItemDetailScreen(item: s.extra as Map<String, String>?),
      ),
      GoRoute(path: Routes.refreshData, builder: (_, _) => const RefreshDataScreen()),
      GoRoute(
          path: Routes.itemDeptList,
          builder: (_, _) => const CatalogListScreen(kind: 'DEPT', title: 'DEPARTMENTS')),
      GoRoute(
          path: Routes.itemCsCatList,
          builder: (_, _) => const CatalogListScreen(kind: 'CS', title: 'CS CATEGORIES')),
      GoRoute(
          path: Routes.itemNeilsonCatList,
          builder: (_, _) =>
              const CatalogListScreen(kind: 'NEILSON', title: 'NEILSON CATEGORIES')),
      GoRoute(
        path: Routes.itemFilteredList,
        builder: (_, s) => ItemFilteredListScreen(
          dept: s.uri.queryParameters['dept'],
          categoryKind: s.uri.queryParameters['catKind'],
          category: s.uri.queryParameters['cat'],
          dealsOnly: s.uri.queryParameters['deals'] == 'true',
        ),
      ),
      GoRoute(
          path: Routes.searchDeals,
          builder: (_, _) => const ItemFilteredListScreen(dealsOnly: true)),
      GoRoute(
          path: Routes.manageSavedItems, builder: (_, _) => const SavedItemsScreen()),
      GoRoute(
        path: Routes.itemImages,
        builder: (_, s) => ItemImagesScreen(itemCode: s.uri.queryParameters['code']),
      ),
      GoRoute(path: Routes.reviewOrders, builder: (_, _) => const ReviewOrdersScreen()),
      GoRoute(
          path: Routes.viewDeviceOrders,
          builder: (_, _) => const ViewDeviceOrdersScreen()),
      GoRoute(path: Routes.orderApproval, builder: (_, _) => const OrderApprovalScreen()),
      GoRoute(
        path: Routes.approvalsList,
        builder: (_, s) =>
            ApprovalsListScreen(mode: s.uri.queryParameters['mode'] ?? 'WAITING'),
      ),
      GoRoute(
        path: Routes.approvalOrderDetail,
        builder: (_, s) =>
            ApprovalOrderDetailScreen(confirmId: s.uri.queryParameters['confirmId'] ?? ''),
      ),
      GoRoute(path: Routes.invoiceList, builder: (_, _) => const InvoiceListScreen()),
      GoRoute(
        path: Routes.invoiceDetail,
        builder: (_, s) => InvoiceDetailScreen(
            invoiceNumber: s.uri.queryParameters['invoiceNumber'] ?? ''),
      ),
      GoRoute(path: Routes.invoicePdfList, builder: (_, _) => const InvoicePdfScreen()),
      GoRoute(path: Routes.otherOptions, builder: (_, _) => const OtherOptionsScreen()),
      GoRoute(
          path: Routes.backroomInventory,
          builder: (_, _) => const BackroomInventoryScreen()),
      GoRoute(
          path: Routes.backroomUpdate, builder: (_, _) => const UpdateInventoryScreen()),
      GoRoute(
          path: Routes.backroomReset, builder: (_, _) => const ResetInventoryScreen()),
      GoRoute(
          path: Routes.backroomPullList, builder: (_, _) => const ViewPullListScreen()),
      GoRoute(path: Routes.messages, builder: (_, _) => const MessagesScreen()),
      GoRoute(path: Routes.help, builder: (_, _) => const HelpScreen()),
      GoRoute(
          path: Routes.operationalGuide,
          builder: (_, _) => const OperationalGuideScreen()),
      GoRoute(path: Routes.scanDebug, builder: (_, _) => const ScanDebugScreen()),
      GoRoute(path: Routes.debug, builder: (_, _) => const DebugScreen()),
      GoRoute(path: Routes.standingOrders, builder: (_, _) => const StandingOrdersScreen()),
      GoRoute(
          path: Routes.viewStoreOrdersSelect, builder: (_, _) => const SelectStoreScreen()),
      GoRoute(
          path: Routes.viewStoreOrdersList,
          builder: (_, _) => const StoreOrdersListScreen()),
      GoRoute(
          path: Routes.viewStoreOrdersDetail,
          builder: (_, _) => const StoreOrderDetailScreen()),
      GoRoute(
          path: Routes.selectOrderType,
          builder: (_, _) => const SelectOrderTypeScreen()),
      GoRoute(
          path: Routes.selectPartition,
          builder: (_, _) => const SelectPartitionScreen()),
      GoRoute(path: Routes.orderHeader, builder: (_, _) => const OrderHeaderScreen()),
      GoRoute(path: Routes.orderFilling, builder: (_, _) => const OrderFillingScreen()),
      GoRoute(
          path: Routes.orderItemSearch,
          builder: (_, _) => const OrderItemSearchScreen()),
      GoRoute(
          path: Routes.orderMultsReturned,
          builder: (_, _) => const MultsReturnedScreen()),
      GoRoute(
        path: Routes.sendOrders,
        builder: (_, s) => SendOrdersScreen(
            currentOrderId:
                int.tryParse(s.uri.queryParameters['currentOrderId'] ?? '') ?? -1),
      ),
      GoRoute(
        path: Routes.submitOrder,
        builder: (_, s) => SubmitOrderScreen(
            orderId: int.tryParse(s.uri.queryParameters['orderId'] ?? '') ?? -1),
      ),
      GoRoute(
        path: Routes.orderMinimum,
        builder: (_, s) => OrderMinimumScreen(
            orderId: int.tryParse(s.uri.queryParameters['orderId'] ?? '') ?? -1),
      ),
      GoRoute(
        path: Routes.recommendedItems,
        builder: (_, s) => RecommendedItemsScreen(
            orderId: int.tryParse(s.uri.queryParameters['orderId'] ?? '') ?? -1),
      ),

      // ── Not yet ported (navigable placeholders) ───────────────────────────
      GoRoute(
          path: Routes.chooseActiveCustomer,
          builder: (_, _) => const ChooseActiveCustomerScreen()),
      placeholder(Routes.viewStoreOrdersResponse, 'Order Response'),
      placeholder(Routes.standingOrderTemplateSelect, 'Templates'),
      placeholder(Routes.orderItemDetail, 'Order Item'),
      placeholder(Routes.orderItemCatalog, 'Order Item Catalog'),
      placeholder(Routes.orderItemDeptList, 'Departments'),
      placeholder(Routes.orderItemCsCatList, 'CS Categories'),
      placeholder(Routes.orderItemNeilsonCatList, 'Neilson Categories'),
      placeholder(Routes.orderItemFiltered, 'Items'),
      placeholder(Routes.orderSearchDeals, 'Deals'),
      placeholder(Routes.orderSearchNewItems, 'New Items'),
      placeholder(Routes.orderSavedItems, 'Saved Items'),
    ],
  );
}
