import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router/app_routes.dart';

/// Turns a tapped push notification into a pending route, held until the user
/// is past splash/login/sync. Port of Kotlin `PushNavigator`.
///
/// Backend FCM `data` contract:
///   screen        (required) HOME | ORDER_APPROVALS | REFRESH_DATA | REVIEW_ORDERS | INVOICES
///   confirmId     (optional) with ORDER_APPROVALS → that approval's detail
///   mode          (optional) with ORDER_APPROVALS → approvals list filter
///   invoiceNumber (optional) with INVOICES → that invoice
class PushNavigator extends Notifier<String?> {
  static const keyScreen = 'screen';

  /// Routes where the user is not yet authenticated; deep links wait.
  static const preAuthRoutes = <String>{
    Routes.splash,
    Routes.login,
    Routes.userSetup,
    Routes.tos,
    Routes.dataSync,
    Routes.chooseActiveCustomer,
  };

  static const homeRoute = Routes.dashboard;

  @override
  String? build() => null;

  /// Reads notification data and stores the pending route (if any).
  void handleMessageData(Map<String, dynamic> data) {
    final screen = data[keyScreen]?.toString();
    if (screen == null || screen.isEmpty) return;
    final route = routeFor(screen, data);
    if (route != null) state = route;
  }

  void consume() => state = null;

  /// Pure mapping from a screen name + data to a route string.
  static String? routeFor(String screen, Map<String, dynamic> data) {
    switch (screen.toUpperCase()) {
      case 'HOME':
        return homeRoute;
      case 'ORDER_APPROVALS':
        final confirmId = data['confirmId']?.toString();
        final mode = data['mode']?.toString();
        if (confirmId != null && confirmId.isNotEmpty) {
          return '${Routes.approvalOrderDetail}?confirmId=$confirmId';
        }
        if (mode != null && mode.isNotEmpty) {
          return '${Routes.approvalsList}?mode=$mode';
        }
        return Routes.orderApproval;
      case 'REFRESH_DATA':
        return Routes.refreshData;
      case 'REVIEW_ORDERS':
        return Routes.reviewOrders;
      case 'INVOICES':
        final inv = data['invoiceNumber']?.toString();
        if (inv != null && inv.isNotEmpty) {
          return '${Routes.invoiceDetail}?invoiceNumber=$inv';
        }
        return Routes.invoiceList;
      default:
        return null;
    }
  }
}

final pushNavigatorProvider =
    NotifierProvider<PushNavigator, String?>(PushNavigator.new);
