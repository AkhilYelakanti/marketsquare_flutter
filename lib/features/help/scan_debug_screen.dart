import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/session/session_providers.dart';
import '../../widgets/scanner_sheet.dart';
import '../orderentry/order_widgets.dart';

/// Result of applying the LOV1 scanParams rules to a scanned/typed value.
class _ScanResult {
  final String converted;
  final Map<String, dynamic>? rule;
  final List<String> steps;
  const _ScanResult(this.converted, this.rule, this.steps);
}

/// Port of native `ScanDebugScreen` + `HelpViewModel.applyScanParams`:
/// scan or key a barcode, then show the SCANNED → CONVERTED result, the matched
/// scanParams rule and each conversion step.
class ScanDebugScreen extends ConsumerStatefulWidget {
  const ScanDebugScreen({super.key});

  @override
  ConsumerState<ScanDebugScreen> createState() => _State();
}

class _State extends ConsumerState<ScanDebugScreen> {
  final _input = TextEditingController();
  String _scanned = '';
  _ScanResult? _result;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  int _int(Object? v) => int.tryParse('${v ?? ''}'.trim()) ?? 0;
  bool _isY(Object? v) => '${v ?? ''}'.trim().toUpperCase() == 'Y';

  /// First rule whose scanLength equals the trimmed input length (native parity).
  _ScanResult _apply(String raw, List<Map<String, dynamic>> params) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const _ScanResult('', null, []);

    Map<String, dynamic>? matched;
    for (final p in params) {
      if (_int(p['scanLength']) == trimmed.length) {
        matched = p;
        break;
      }
    }
    if (matched == null) {
      return _ScanResult(trimmed, null,
          ['No matching scan rule for input length ${trimmed.length}']);
    }

    final steps = <String>[];
    steps.add(
        'Matched rule: ${matched['scanInterpreterType']} (scanLength=${matched['scanLength']})');
    var result = trimmed;

    final dropLeft = _int(matched['scanDropDigitsLeft']);
    if (dropLeft > 0) {
      result = result.length > dropLeft ? result.substring(dropLeft) : '';
      steps.add('Dropped $dropLeft char(s) from left → "$result"');
    }

    final dropRight = _int(matched['scanDropDigitsRight']);
    if (dropRight > 0) {
      result =
          result.length > dropRight ? result.substring(0, result.length - dropRight) : '';
      steps.add('Dropped $dropRight char(s) from right → "$result"');
    }

    if (_isY(matched['scanDropCheckDigit']) && dropRight == 0 && result.isNotEmpty) {
      result = result.substring(0, result.length - 1);
      steps.add('Dropped check digit → "$result"');
    }

    final desired = _int(matched['desiredResult']);
    if (desired > 0) {
      if (_isY(matched['scanPadLeftDigits']) && result.length < desired) {
        result = result.padLeft(desired, '0');
        steps.add('Left-padded to length $desired → "$result"');
      }
      if (_isY(matched['scanPadRightDigits']) && result.length < desired) {
        result = result.padRight(desired, '0');
        steps.add('Right-padded to length $desired → "$result"');
      }
    }

    if (_isY(matched['conditionalLTrim'])) {
      result = result.replaceFirst(RegExp(r'^0+'), '');
      if (result.isEmpty) result = '0';
      steps.add('Left-trimmed zeros → "$result"');
    }
    if (_isY(matched['conditionalRTrim'])) {
      result = result.replaceFirst(RegExp(r'0+$'), '');
      if (result.isEmpty) result = '0';
      steps.add('Right-trimmed zeros → "$result"');
    }

    return _ScanResult(result, matched, steps);
  }

  void _run(String raw) {
    final params = ref.read(sessionManagerProvider).getScanParams();
    setState(() {
      _scanned = raw.trim();
      _result = _apply(raw, params);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final params = ref.watch(sessionManagerProvider).getScanParams();
    final r = _result;

    return Scaffold(
      appBar: orderAppBar(subtitle: 'SCAN DEBUG', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter or scan a barcode',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: _run,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: primary),
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                onPressed: () async {
                  final code = await ScannerSheet.scan(context);
                  if (code != null) {
                    _input.text = code;
                    _run(code);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _run(_input.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: primary, foregroundColor: Colors.white),
            child: const Text('CONVERT'),
          ),
          const SizedBox(height: 16),
          if (r != null) ...[
            _kv('SCANNED', _scanned, primary),
            const SizedBox(height: 4),
            _kv('CONVERTED', r.converted, primary, highlight: true),
            const SizedBox(height: 12),
            if (r.steps.isNotEmpty) ...[
              const Text('Conversion steps',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              for (final s in r.steps)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $s',
                      style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ),
            ],
            if (r.rule != null) ...[
              const SizedBox(height: 12),
              const Text('Matched config',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              for (final e in r.rule!.entries)
                Text('${e.key}: ${e.value}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
            const Divider(height: 32),
          ],
          Text('scanParams configured: ${params.length}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (var i = 0; i < params.length; i++)
            Card(
              color: const Color(0xFFF5F5F5),
              shape: const RoundedRectangleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('[$i] ${params[i]['scanInterpreterType'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    for (final e in params[i].entries)
                      Text('${e.key}: ${e.value}',
                          style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, Color primary, {bool highlight = false}) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(k,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13))),
          Expanded(
            child: Text(v.isEmpty ? '—' : v,
                style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: highlight ? primary : Colors.black87)),
          ),
        ],
      );
}
