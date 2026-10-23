import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/device_meta.dart';
import '../../core/network/api_client.dart';
import '../../data/db/pending_order.dart';
import '../../data/db/pending_order_dao.dart';
import '../../data/repository/order_repository.dart';
import '../../data/session/session_providers.dart';

enum SubmitPhase { idle, sending, result }

class SubmitState {
  final SubmitPhase phase;
  final PendingOrder? order;
  final String? receipt; // formatted acknowledgement text
  final String responseHtml; // optional HTML/extra response
  final String? error;
  const SubmitState({
    this.phase = SubmitPhase.idle,
    this.order,
    this.receipt,
    this.responseHtml = '',
    this.error,
  });
  bool get isSuccess => error == null;
}

/// Port of `SubmitOrderViewModel`: submits an order and surfaces the receipt.
class SubmitController extends AutoDisposeNotifier<SubmitState> {
  final _dao = PendingOrderDao();

  @override
  SubmitState build() => const SubmitState();

  Future<void> submit(int orderId) async {
    if (state.phase != SubmitPhase.idle || orderId == -1) return;
    final order = await _dao.getById(orderId);
    if (order == null) {
      state = const SubmitState(phase: SubmitPhase.result, error: 'Order not found');
      return;
    }
    state = SubmitState(phase: SubmitPhase.sending, order: order);

    final repo = OrderRepository(ApiClient());
    final session = ref.read(sessionManagerProvider);
    final result = await repo.submitSavedOrder(
      session: session,
      order: order,
      deviceId: await deviceId(),
      versionId: await versionId(),
    );

    if (result.isSuccess) {
      final body = result.value!;
      final conf = _extractConfirmationId(body);
      await _dao.markSent(order.id, DateTime.now().millisecondsSinceEpoch, conf);
      state = SubmitState(
        phase: SubmitPhase.result,
        order: order,
        receipt: _formatReceipt(body),
        responseHtml: _extractResponse(body),
      );
    } else {
      state = SubmitState(
        phase: SubmitPhase.result,
        order: order,
        error: _errMsg(result.error),
      );
    }
  }

  Map<String, dynamic>? _asObj(String body) {
    try {
      final v = jsonDecode(body);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  String _extractConfirmationId(String body) {
    final obj = _asObj(body);
    final top = obj?['confirmationId']?.toString();
    if (top != null && top.isNotEmpty) return top;
    final data = obj?['data'];
    if (data is Map && data['confirmationId'] != null) {
      return data['confirmationId'].toString();
    }
    if (data is List && data.isNotEmpty && data.first is Map) {
      final c = (data.first as Map)['confirmationId'];
      if (c != null) return c.toString();
    }
    final m = RegExp(r'Confirmation\s*[#ID]*\s*[:#]?\s*(\d+)', caseSensitive: false)
        .firstMatch(body);
    return m?.group(1) ?? '';
  }

  String _extractResponse(String body) {
    final obj = _asObj(body);
    final top = obj?['response']?.toString();
    if (top != null && top.isNotEmpty) return top;
    final data = obj?['data'];
    if (data is Map && data['response'] != null) return data['response'].toString();
    if (data is List && data.isNotEmpty && data.first is Map) {
      final r = (data.first as Map)['response'];
      if (r != null) return r.toString();
    }
    return '';
  }

  String _formatReceipt(String body) {
    final obj = _asObj(body);
    final msg = obj?['message']?.toString();
    if (msg != null && msg.isNotEmpty) return msg;
    final data = obj?['data'];
    if (data is List && data.isNotEmpty && data.first is Map) {
      final f = data.first as Map;
      for (final k in ['message', 'acknowledgement', 'ackMessage']) {
        final v = f[k];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
    }
    if (data is Map && data['message'] != null) return data['message'].toString();
    return body.trim();
  }

  String _errMsg(Object? e) =>
      e is StateError ? e.message : (e?.toString() ?? 'Submission failed');
}

final submitControllerProvider =
    AutoDisposeNotifierProvider<SubmitController, SubmitState>(
        SubmitController.new);
