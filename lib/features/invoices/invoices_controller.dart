import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

import '../../core/device_meta.dart';
import '../../core/network/api_client.dart';
import '../../data/models/order_models.dart';
import '../../data/repository/order_repository.dart';
import '../../data/session/session_providers.dart';

class InvoicesState {
  final List<InvoiceSummary> list;
  final bool loadingList;
  final String listError;
  final InvoiceDetailResponse? detail;
  final bool loadingDetail;
  final String detailError;
  final String pdfStatus;
  final bool loadingPdf;

  const InvoicesState({
    this.list = const [],
    this.loadingList = false,
    this.listError = '',
    this.detail,
    this.loadingDetail = false,
    this.detailError = '',
    this.pdfStatus = '',
    this.loadingPdf = false,
  });

  InvoicesState copyWith({
    List<InvoiceSummary>? list,
    bool? loadingList,
    String? listError,
    InvoiceDetailResponse? detail,
    bool? loadingDetail,
    String? detailError,
    String? pdfStatus,
    bool? loadingPdf,
    bool clearDetail = false,
  }) =>
      InvoicesState(
        list: list ?? this.list,
        loadingList: loadingList ?? this.loadingList,
        listError: listError ?? this.listError,
        detail: clearDetail ? null : (detail ?? this.detail),
        loadingDetail: loadingDetail ?? this.loadingDetail,
        detailError: detailError ?? this.detailError,
        pdfStatus: pdfStatus ?? this.pdfStatus,
        loadingPdf: loadingPdf ?? this.loadingPdf,
      );
}

/// Port of `InvoicesViewModel` + `InvoicePdfViewModel`.
class InvoicesController extends Notifier<InvoicesState> {
  late final OrderRepository _repo = OrderRepository(ApiClient());

  @override
  InvoicesState build() => const InvoicesState();

  Future<void> fetchList(
      {String fromDate = '', String toDate = '', String invoiceNumber = ''}) async {
    state = state.copyWith(loadingList: true, listError: '', list: const []);
    final res = await _repo.fetchInvoiceList(
      session: ref.read(sessionManagerProvider),
      fromDate: fromDate,
      toDate: toDate,
      invoiceNumber: invoiceNumber,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );
    if (res.isSuccess) {
      final ok = res.value!.status.toLowerCase() == 'success';
      state = state.copyWith(
        loadingList: false,
        list: ok ? res.value!.invoiceList : const [],
        listError: ok ? '' : 'No invoices found.',
      );
    } else {
      state = state.copyWith(loadingList: false, listError: 'Failed to load invoices.');
    }
  }

  Future<void> fetchDetail(String invoiceNumber) async {
    state = state.copyWith(loadingDetail: true, detailError: '', clearDetail: true);
    final res = await _repo.fetchInvoiceDetails(
      session: ref.read(sessionManagerProvider),
      invoiceNumber: invoiceNumber,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );
    state = state.copyWith(
      loadingDetail: false,
      detail: res.isSuccess ? res.value : null,
      detailError: res.isSuccess ? '' : 'Failed to load invoice detail.',
    );
  }

  void clearDetail() => state = state.copyWith(clearDetail: true, detailError: '');

  /// Fetches the invoice PDF and saves it to a local file. In-app rendering
  /// needs a PDF-viewer plugin (follow-up); this reports the saved file.
  Future<void> fetchPdf(String invoiceNumber) async {
    state = state.copyWith(loadingPdf: true, pdfStatus: 'Fetching PDF...');
    final res = await _repo.fetchInvoicePdf(
      session: ref.read(sessionManagerProvider),
      invoiceNumber: invoiceNumber,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );
    if (!res.isSuccess) {
      state = state.copyWith(loadingPdf: false, pdfStatus: 'Failed to fetch PDF.');
      return;
    }
    try {
      final dir = await getDatabasesPath();
      final file = File(p.join(dir, 'invoice_pdf_$invoiceNumber.pdf'));
      await file.writeAsBytes(res.value!);
      final kb = (res.value!.length / 1024).toStringAsFixed(1);
      state = state.copyWith(
          loadingPdf: false,
          pdfStatus: 'Saved $kb KB → ${file.path}\n(In-app PDF view is a follow-up.)');
    } catch (e) {
      state = state.copyWith(loadingPdf: false, pdfStatus: 'Save failed: $e');
    }
  }
}

final invoicesControllerProvider =
    NotifierProvider<InvoicesController, InvoicesState>(InvoicesController.new);
