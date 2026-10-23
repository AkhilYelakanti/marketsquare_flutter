// Port of OrderModels.kt — domain + config models for the Order Entry flow.
// API payload construction lives in OrderRepository.buildPayloadJson.

/// A customer/store the user can select before entering an order.
class CustomerEntry {
  final String rawData; // e.g. "18316-Highland Park Manchester"
  final String storeId;
  final String storeName;
  const CustomerEntry({this.rawData = '', this.storeId = '', this.storeName = ''});
}

/// One line in a work-in-progress order. [item] is the full catalog row.
class OrderLine {
  final Map<String, String> item;
  final String qty;
  final String newPrice;
  final String tagRequired;
  final String fromDate;
  final String toDate;
  final String crReasonCode;
  final String crType;
  final String crInvoiceNumber;
  final String? alertWatermarkText;
  final String? alertBackgroundHex;
  final String partition;

  const OrderLine({
    required this.item,
    this.qty = '',
    this.newPrice = '',
    this.tagRequired = '0',
    this.fromDate = '',
    this.toDate = '',
    this.crReasonCode = '',
    this.crType = '',
    this.crInvoiceNumber = '',
    this.alertWatermarkText,
    this.alertBackgroundHex,
    this.partition = '',
  });

  OrderLine copyWith({
    Map<String, String>? item,
    String? qty,
    String? newPrice,
    String? tagRequired,
    String? fromDate,
    String? toDate,
    String? crReasonCode,
    String? crType,
    String? crInvoiceNumber,
    String? alertWatermarkText,
    String? alertBackgroundHex,
    String? partition,
  }) =>
      OrderLine(
        item: item ?? this.item,
        qty: qty ?? this.qty,
        newPrice: newPrice ?? this.newPrice,
        tagRequired: tagRequired ?? this.tagRequired,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        crReasonCode: crReasonCode ?? this.crReasonCode,
        crType: crType ?? this.crType,
        crInvoiceNumber: crInvoiceNumber ?? this.crInvoiceNumber,
        alertWatermarkText: alertWatermarkText ?? this.alertWatermarkText,
        alertBackgroundHex: alertBackgroundHex ?? this.alertBackgroundHex,
        partition: partition ?? this.partition,
      );
}

/// One field definition from `formFieldsInOrdering`. Drives the Order Header form.
class FormFieldConfig {
  final String fieldKey;
  final String label;
  final String type; // text | date | dropdown | textarea
  final String placeholder;
  final String source; // LOV1 key supplying dropdown options
  const FormFieldConfig({
    this.fieldKey = '',
    this.label = '',
    this.type = 'text',
    this.placeholder = '',
    this.source = '',
  });

  FormFieldConfig copyWith({String? label}) => FormFieldConfig(
        fieldKey: fieldKey,
        label: label ?? this.label,
        type: type,
        placeholder: placeholder,
        source: source,
      );
}

/// A mandatory/optional-ness pairing for a field on a given order type.
class FieldRow {
  final FormFieldConfig config;
  final bool isMandatory;
  const FieldRow(this.config, this.isMandatory);
}

/// Extra toolbar button from `orderControlButtons`.
class OrderControlButton {
  final String key;
  final String label;
  final String icon;
  final List<String> requestTypes; // empty = all order types
  const OrderControlButton({
    this.key = '',
    this.label = '',
    this.icon = '',
    this.requestTypes = const [],
  });
}

/// One totals cell from `orderTotals`.
class OrderTotalField {
  final String key; // ITEM_QTY | CASE_QTY | EST_VALUE | ALLOWANCE | TOTAL_CUBE
  final String label;
  final String prefix;
  const OrderTotalField({this.key = '', this.label = '', this.prefix = ''});
}

// ── Order Approval models ─────────────────────────────────────────────────────

/// One order in a waiting/approved list.
class ApprovalOrderSummary {
  final String department;
  final String confirmationId;
  final String orderDate;
  final String totalItems;
  final String totalCaseQty;
  final String totalEstimateValue;
  const ApprovalOrderSummary({
    this.department = '',
    this.confirmationId = '',
    this.orderDate = '',
    this.totalItems = '',
    this.totalCaseQty = '',
    this.totalEstimateValue = '',
  });
  factory ApprovalOrderSummary.fromJson(Map<String, dynamic> j) => ApprovalOrderSummary(
        department: (j['department'] ?? '').toString(),
        confirmationId: (j['confirmationId'] ?? '').toString(),
        orderDate: (j['orderDate'] ?? '').toString(),
        totalItems: (j['totalItems'] ?? '').toString(),
        totalCaseQty: (j['totalCaseQty'] ?? '').toString(),
        totalEstimateValue: (j['totalEstimateValue'] ?? '').toString(),
      );
}

class ApprovalsListResponse {
  final String status;
  final List<ApprovalOrderSummary> ordersList;
  const ApprovalsListResponse({this.status = '', this.ordersList = const []});
  factory ApprovalsListResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['ordersList'] as List?) ?? const [];
    return ApprovalsListResponse(
      status: (j['status'] ?? '').toString(),
      ordersList: list
          .map((e) => ApprovalOrderSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// One line of a fetched approval order.
class ApiOrderDetail {
  final String itemNumber;
  final String itemDescription;
  final String storeDepartment;
  final String quantity;
  final String tagRequired;
  final String itemUpc;
  const ApiOrderDetail({
    this.itemNumber = '',
    this.itemDescription = '',
    this.storeDepartment = '',
    this.quantity = '',
    this.tagRequired = '0',
    this.itemUpc = '0',
  });
  factory ApiOrderDetail.fromJson(Map<String, dynamic> j) => ApiOrderDetail(
        itemNumber: (j['itemNumber'] ?? '').toString(),
        itemDescription: (j['itemDescription'] ?? '').toString(),
        storeDepartment: (j['storeDepartment'] ?? '').toString(),
        quantity: (j['quantity'] ?? '').toString(),
        tagRequired: (j['tagRequired'] ?? '0').toString(),
        itemUpc: (j['itemUpc'] ?? '0').toString(),
      );
}

/// Header of a fetched approval order.
class ApiOrderHeader {
  final String custPoNumber;
  final String requestedDeliveryDate;
  final String requestType;
  final String storePartition;
  final String comment;
  final String totalEstimateValue;
  const ApiOrderHeader({
    this.custPoNumber = '',
    this.requestedDeliveryDate = '',
    this.requestType = '',
    this.storePartition = '',
    this.comment = '',
    this.totalEstimateValue = '',
  });
  factory ApiOrderHeader.fromJson(Map<String, dynamic> j) => ApiOrderHeader(
        custPoNumber: (j['custPoNumber'] ?? '').toString(),
        requestedDeliveryDate: (j['requestedDeliveryDate'] ?? '').toString(),
        requestType: (j['requestType'] ?? '').toString(),
        storePartition: (j['storePartition'] ?? '').toString(),
        comment: (j['comment'] ?? '').toString(),
        totalEstimateValue:
            (((j['custTransmissionSummary'] as Map?)?['totalEstimateValue']) ?? '')
                .toString(),
      );
}

/// A fetched approval order (first orderRequest group).
class ApiItemOrder {
  final ApiOrderHeader? header;
  final List<ApiOrderDetail> details;
  const ApiItemOrder({this.header, this.details = const []});
  factory ApiItemOrder.fromJson(Map<String, dynamic> j) {
    final groups = (j['orderRequest'] as List?) ?? const [];
    if (groups.isEmpty) return const ApiItemOrder();
    final g = groups.first as Map<String, dynamic>;
    final header = g['orderHeader'] is Map
        ? ApiOrderHeader.fromJson(g['orderHeader'] as Map<String, dynamic>)
        : null;
    final details = ((g['orderDetails'] as List?) ?? const [])
        .map((e) => ApiOrderDetail.fromJson(e as Map<String, dynamic>))
        .toList();
    return ApiItemOrder(header: header, details: details);
  }
}

// ── Store-order history ───────────────────────────────────────────────────────

class OrderSummary {
  final String confirmationId;
  final String transactionId;
  final String status;
  final String orderDate;
  final String storePartition;
  const OrderSummary({
    this.confirmationId = '',
    this.transactionId = '',
    this.status = '',
    this.orderDate = '',
    this.storePartition = '',
  });
  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
        confirmationId: (j['confirmationId'] ?? '').toString(),
        transactionId: (j['transactionId'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        orderDate: (j['orderDate'] ?? '').toString(),
        storePartition: (j['storePartition'] ?? '').toString(),
      );
}

class RecentOrdersResponse {
  final String status;
  final String statusMsg;
  final List<OrderSummary> data;
  const RecentOrdersResponse({this.status = '', this.statusMsg = '', this.data = const []});
  factory RecentOrdersResponse.fromJson(Map<String, dynamic> j) => RecentOrdersResponse(
        status: (j['status'] ?? '').toString(),
        statusMsg: (j['statusMsg'] ?? '').toString(),
        data: ((j['data'] as List?) ?? const [])
            .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StoreOrderHeader {
  final String confirmationId;
  final String requestType;
  final String orderType;
  final String buId;
  final String requestedDeliveryDate;
  final String customerStoreNumber;
  final String orderCreationDate;
  final String currentStatus;
  const StoreOrderHeader({
    this.confirmationId = '',
    this.requestType = '',
    this.orderType = '',
    this.buId = '',
    this.requestedDeliveryDate = '',
    this.customerStoreNumber = '',
    this.orderCreationDate = '',
    this.currentStatus = '',
  });
  factory StoreOrderHeader.fromJson(Map<String, dynamic> j) => StoreOrderHeader(
        confirmationId: (j['confirmationId'] ?? '').toString(),
        requestType: (j['requestType'] ?? '').toString(),
        orderType: (j['orderType'] ?? '').toString(),
        buId: (j['buId'] ?? '').toString(),
        requestedDeliveryDate: (j['requestedDeliveryDate'] ?? '').toString(),
        customerStoreNumber: (j['customerStoreNumber'] ?? '').toString(),
        orderCreationDate: (j['orderCreationDate'] ?? '').toString(),
        currentStatus: (j['currentStatus'] ?? '').toString(),
      );
}

/// ORDER_RESPONSE receipt (REVIEW ORDER RECEIPT). Native `OrderDetailItem`.
class OrderResponseReceipt {
  final String acknowledgementId;
  final String confirmationId;
  final String orderDate;
  final String status;
  final String storeId;
  final String requestType;
  final String billingDate;
  final String estimatedShipDate;
  final String estimatedDeliveryDate;
  const OrderResponseReceipt({
    this.acknowledgementId = '',
    this.confirmationId = '',
    this.orderDate = '',
    this.status = '',
    this.storeId = '',
    this.requestType = '',
    this.billingDate = '',
    this.estimatedShipDate = '',
    this.estimatedDeliveryDate = '',
  });
  factory OrderResponseReceipt.fromJson(Map<String, dynamic> j) => OrderResponseReceipt(
        acknowledgementId: (j['acknowledgementId'] ?? '').toString(),
        confirmationId: (j['confirmationId'] ?? '').toString(),
        orderDate: (j['orderDate'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        storeId: (j['storeId'] ?? '').toString(),
        requestType: (j['requestType'] ?? '').toString(),
        billingDate: (j['billingDate'] ?? '').toString(),
        estimatedShipDate: (j['estimatedShipDate'] ?? '').toString(),
        estimatedDeliveryDate: (j['estimatedDeliveryDate'] ?? '').toString(),
      );

  /// ORDER_RESPONSE wraps the receipt in a `data` array; takes the first entry.
  static OrderResponseReceipt? fromResponseJson(Map<String, dynamic> j) {
    final data = (j['data'] as List?) ?? const [];
    if (data.isEmpty) return null;
    return OrderResponseReceipt.fromJson(data.first as Map<String, dynamic>);
  }
}

class DeptOrderLine {
  final String itemNumber;
  final String itemDescription;
  final String quantity;
  const DeptOrderLine(
      {this.itemNumber = '', this.itemDescription = '', this.quantity = ''});
  factory DeptOrderLine.fromJson(Map<String, dynamic> j) => DeptOrderLine(
        itemNumber: (j['itemNumber'] ?? '').toString(),
        itemDescription: (j['itemDescription'] ?? '').toString(),
        quantity: (j['quantity'] ?? '').toString(),
      );
}

class DeptOrderDetail {
  final String department;
  final List<DeptOrderLine> orderDetails;
  const DeptOrderDetail({this.department = '', this.orderDetails = const []});
  factory DeptOrderDetail.fromJson(Map<String, dynamic> j) => DeptOrderDetail(
        department: (j['department'] ?? '').toString(),
        orderDetails: ((j['orderDetails'] as List?) ?? const [])
            .map((e) => DeptOrderLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StoreOrderDetailResponse {
  final StoreOrderHeader header;
  final List<DeptOrderDetail> deptOrderDetails;
  const StoreOrderDetailResponse(
      {this.header = const StoreOrderHeader(), this.deptOrderDetails = const []});
  factory StoreOrderDetailResponse.fromJson(Map<String, dynamic> j) =>
      StoreOrderDetailResponse(
        header: j['orderHeader'] is Map
            ? StoreOrderHeader.fromJson(j['orderHeader'] as Map<String, dynamic>)
            : const StoreOrderHeader(),
        deptOrderDetails: ((j['deptOrderDetails'] as List?) ?? const [])
            .map((e) => DeptOrderDetail.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Invoices ──────────────────────────────────────────────────────────────────

class InvoiceSummary {
  final String storeId;
  final String department;
  final String invoiceDate;
  final String invoiceNumber;
  final String invoiceAmount;
  const InvoiceSummary({
    this.storeId = '',
    this.department = '',
    this.invoiceDate = '',
    this.invoiceNumber = '',
    this.invoiceAmount = '',
  });
  factory InvoiceSummary.fromJson(Map<String, dynamic> j) => InvoiceSummary(
        storeId: (j['storeId'] ?? '').toString(),
        department: (j['department'] ?? '').toString(),
        invoiceDate: (j['invoiceDate'] ?? '').toString(),
        invoiceNumber: (j['invoiceNumber'] ?? '').toString(),
        invoiceAmount: (j['invoiceAmount'] ?? '').toString(),
      );
}

class InvoiceListResponse {
  final String status;
  final List<InvoiceSummary> invoiceList;
  const InvoiceListResponse({this.status = '', this.invoiceList = const []});
  factory InvoiceListResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['invoiceList'] as List?) ?? const [];
    return InvoiceListResponse(
      status: (j['status'] ?? '').toString(),
      invoiceList:
          list.map((e) => InvoiceSummary.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class InvoiceHeaderData {
  final String department;
  final String invoiceNumber;
  final String invoiceDate;
  final String totalInvoiceAmount;
  const InvoiceHeaderData({
    this.department = '',
    this.invoiceNumber = '',
    this.invoiceDate = '',
    this.totalInvoiceAmount = '',
  });
  factory InvoiceHeaderData.fromJson(Map<String, dynamic> j) => InvoiceHeaderData(
        department: (j['department'] ?? '').toString(),
        invoiceNumber: (j['invoiceNumber'] ?? '').toString(),
        invoiceDate: (j['invoiceDate'] ?? '').toString(),
        totalInvoiceAmount: (j['totalInvoiceAmount'] ?? '').toString(),
      );
}

class InvoiceLineItem {
  final String itemId;
  final String description;
  final String packSize;
  final String orderQty;
  final String shippedQty;
  final String unitCost;
  final String invoiceAmount;
  const InvoiceLineItem({
    this.itemId = '',
    this.description = '',
    this.packSize = '',
    this.orderQty = '',
    this.shippedQty = '',
    this.unitCost = '',
    this.invoiceAmount = '',
  });
  factory InvoiceLineItem.fromJson(Map<String, dynamic> j) => InvoiceLineItem(
        itemId: (j['itemId'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        packSize: (j['packSize'] ?? '').toString(),
        orderQty: (j['orderQty'] ?? '').toString(),
        shippedQty: (j['shippedQty'] ?? '').toString(),
        unitCost: (j['unitCost'] ?? '').toString(),
        invoiceAmount: (j['invoiceAmount'] ?? '').toString(),
      );
}

class InvoiceDetailResponse {
  final String status;
  final List<InvoiceHeaderData> invoiceHeader;
  final List<InvoiceLineItem> invoiceDetails;
  const InvoiceDetailResponse({
    this.status = '',
    this.invoiceHeader = const [],
    this.invoiceDetails = const [],
  });
  factory InvoiceDetailResponse.fromJson(Map<String, dynamic> j) {
    final hdr = (j['invoiceHeader'] as List?) ?? const [];
    final det = (j['invoiceDetails'] as List?) ?? const [];
    return InvoiceDetailResponse(
      status: (j['status'] ?? '').toString(),
      invoiceHeader:
          hdr.map((e) => InvoiceHeaderData.fromJson(e as Map<String, dynamic>)).toList(),
      invoiceDetails:
          det.map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Result of the PRE-OM-CHECK pre-submit gate.
class PreOmCheckResult {
  final bool isShortfall;
  final String html;
  const PreOmCheckResult(this.isShortfall, this.html);
}

/// One recommended item from the RECOMMENDED_ITEMS pre-submit gate.
class RecommendedItemEntry {
  final String itemNumber;
  final String qty;
  const RecommendedItemEntry(this.itemNumber, this.qty);
}

/// One line serialized into PendingOrder.linesJson.
class SavedOrderLine {
  final String itemNumber;
  final String itemDescription;
  final String qty;
  final String newPrice;
  final String pack;
  final String upc;
  final String storeDepartment;
  final String cube;
  final String itemCodeMults;
  final String tagRequired;
  final String alertWatermarkText;
  final String alertBackgroundHex;
  final String fromDate;
  final String toDate;
  final String crReasonCode;
  final String crType;
  final String crInvoiceNumber;
  final String partition;
  final String estimatedValue;

  const SavedOrderLine({
    this.itemNumber = '',
    this.itemDescription = '',
    this.qty = '1',
    this.newPrice = '',
    this.pack = '',
    this.upc = '0',
    this.storeDepartment = '',
    this.cube = '0.00',
    this.itemCodeMults = '',
    this.tagRequired = '0',
    this.alertWatermarkText = '',
    this.alertBackgroundHex = '',
    this.fromDate = '',
    this.toDate = '',
    this.crReasonCode = '',
    this.crType = '',
    this.crInvoiceNumber = '',
    this.partition = '',
    this.estimatedValue = '0.00',
  });

  Map<String, dynamic> toJson() => {
        'itemNumber': itemNumber,
        'itemDescription': itemDescription,
        'qty': qty,
        'newPrice': newPrice,
        'pack': pack,
        'upc': upc,
        'storeDepartment': storeDepartment,
        'cube': cube,
        'itemCodeMults': itemCodeMults,
        'tagRequired': tagRequired,
        'alertWatermarkText': alertWatermarkText,
        'alertBackgroundHex': alertBackgroundHex,
        'fromDate': fromDate,
        'toDate': toDate,
        'crReasonCode': crReasonCode,
        'crType': crType,
        'crInvoiceNumber': crInvoiceNumber,
        'partition': partition,
        'estimatedValue': estimatedValue,
      };

  factory SavedOrderLine.fromJson(Map<String, dynamic> j) => SavedOrderLine(
        itemNumber: (j['itemNumber'] ?? '').toString(),
        itemDescription: (j['itemDescription'] ?? '').toString(),
        qty: (j['qty'] ?? '1').toString(),
        newPrice: (j['newPrice'] ?? '').toString(),
        pack: (j['pack'] ?? '').toString(),
        upc: (j['upc'] ?? '0').toString(),
        storeDepartment: (j['storeDepartment'] ?? '').toString(),
        cube: (j['cube'] ?? '0.00').toString(),
        itemCodeMults: (j['itemCodeMults'] ?? '').toString(),
        tagRequired: (j['tagRequired'] ?? '0').toString(),
        alertWatermarkText: (j['alertWatermarkText'] ?? '').toString(),
        alertBackgroundHex: (j['alertBackgroundHex'] ?? '').toString(),
        fromDate: (j['fromDate'] ?? '').toString(),
        toDate: (j['toDate'] ?? '').toString(),
        crReasonCode: (j['crReasonCode'] ?? '').toString(),
        crType: (j['crType'] ?? '').toString(),
        crInvoiceNumber: (j['crInvoiceNumber'] ?? '').toString(),
        partition: (j['partition'] ?? '').toString(),
        estimatedValue: (j['estimatedValue'] ?? '0.00').toString(),
      );
}
