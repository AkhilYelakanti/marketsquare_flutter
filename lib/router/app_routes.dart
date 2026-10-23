/// Route path constants — one-to-one with the native NavGraph routes.
class Routes {
  Routes._();

  static const splash = '/splash';
  static const login = '/login';
  static const userSetup = '/user_setup';
  static const tos = '/tos';
  static const dataSync = '/dataSync';
  static const dashboard = '/dashboard';
  static const chooseActiveCustomer = '/choose_active_customer';

  // Item catalog
  static const itemCatalog = '/item_catalog';
  static const itemSearch = '/item_search';
  static const itemDeptList = '/item_dept_list';
  static const manageSavedItems = '/manage_saved_items';
  static const itemCsCatList = '/item_cs_cat_list';
  static const itemNeilsonCatList = '/item_neilson_cat_list';
  static const itemFilteredList = '/item_filtered_list';
  static const searchDeals = '/search_deals';
  static const itemImages = '/item_images';
  static const itemDetail = '/item_detail';

  // Review orders
  static const reviewOrders = '/review_orders';
  static const viewDeviceOrders = '/view_device_orders';
  static const viewStoreOrdersSelect = '/view_store_orders_select';
  static const viewStoreOrdersList = '/view_store_orders_list';
  static const viewStoreOrdersDetail = '/view_store_orders_detail';
  static const viewStoreOrdersResponse = '/view_store_orders_response';

  // Order entry
  static const orderEntry = '/order_entry';
  static const selectOrderType = '/select_order_type';
  static const standingOrders = '/standing_orders';
  static const standingOrderTemplateSelect = '/standing_order_template_select';
  static const orderHeader = '/order_header';
  static const selectPartition = '/select_partition';
  static const orderFilling = '/order_filling';
  static const orderItemDetail = '/order_item_detail';
  static const orderItemCatalog = '/order_item_catalog';
  static const orderItemSearch = '/order_item_search';
  static const orderItemDeptList = '/order_item_dept_list';
  static const orderItemCsCatList = '/order_item_cs_cat_list';
  static const orderItemNeilsonCatList = '/order_item_neilson_cat_list';
  static const orderItemFiltered = '/order_item_filtered';
  static const orderSearchDeals = '/order_search_deals';
  static const orderSearchNewItems = '/order_search_new_items';
  static const orderSavedItems = '/order_saved_items';
  static const orderMultsReturned = '/order_mults_returned';

  // Send orders
  static const sendOrders = '/send_orders';
  static const submitOrder = '/submit_order';
  static const orderMinimum = '/order_minimum';
  static const recommendedItems = '/recommended_items';

  // Order approval
  static const orderApproval = '/order_approval';
  static const approvalsList = '/approvals_list';
  static const approvalOrderDetail = '/approval_order_detail';

  // Invoices
  static const invoiceList = '/invoice_list';
  static const invoicePdfList = '/invoice_pdf_list';
  static const invoiceDetail = '/invoice_detail';

  // Other options / backroom
  static const otherOptions = '/other_options';
  static const backroomInventory = '/backroom_inventory';
  static const backroomUpdate = '/backroom_update';
  static const backroomReset = '/backroom_reset';
  static const backroomPullList = '/backroom_pull_list';

  // Help / misc
  static const help = '/help';
  static const operationalGuide = '/operational_guide';
  static const scanDebug = '/scan_debug';
  static const debug = '/debug';
  static const refreshData = '/refreshData';
  static const messages = '/messages';
}
