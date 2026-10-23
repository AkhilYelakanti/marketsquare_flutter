import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/message.dart';
import '../orderentry/alert_pipeline.dart';
import 'messages_controller.dart';

/// Native parity: Messages is a stack of centered popups (GROUP list →
/// RECEIVED MESSAGES → MESSAGE detail), not a full-screen route. Opened from the
/// dashboard MESSAGES tile and from the mandatory IMPORTANT alert.
Future<void> showMessagesDialog(BuildContext context, {String? initialGroup}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _MessagesPopup(initialGroup: initialGroup),
  );
}

/// Mandatory, non-dismissable IMPORTANT alert. Blocks all other taps until the
/// user clicks "Proceed To Read", which opens the IMPORTANT message group.
Future<void> showImportantAlertDialog(
    BuildContext context, WidgetRef ref, AlertMessagesConfig cfg) {
  final ctrl = ref.read(messagesControllerProvider.notifier);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dctx) => PopScope(
      canPop: false,
      child: _DialogShell(
        children: [
          _redHeader(dctx,
              cfg.alertType.isEmpty ? 'MESSAGE_IMPORTANT' : cfg.alertType),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              cfg.alertText.isEmpty
                  ? 'Please read IMPORTANT message before Proceeding'
                  : cfg.alertText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pop(dctx);
                ctrl.dismissImportant();
                showMessagesDialog(context, initialGroup: 'IMPORTANT');
              },
              child: Text(
                (cfg.button2Text.isEmpty ? 'Proceed To Read' : cfg.button2Text),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ── Shared popup chrome ────────────────────────────────────────────────────

/// White rounded popup container, width-capped like the native Dialog.
class _DialogShell extends StatelessWidget {
  final List<Widget> children;
  const _DialogShell({required this.children});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6))),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

Widget _redHeader(BuildContext context, String title) {
  final primary = Theme.of(context).colorScheme.primary;
  return Container(
    width: double.infinity,
    color: primary,
    padding: const EdgeInsets.symmetric(vertical: 14),
    alignment: Alignment.center,
    child: Text(title,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
  );
}

/// Red bottom bar with a circled back-arrow + label (EXIT / BACK).
Widget _bottomBar(BuildContext context, String label, VoidCallback onTap) {
  final primary = Theme.of(context).colorScheme.primary;
  return InkWell(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      color: primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    ),
  );
}

// ── Messages popup (groups → list → detail) ────────────────────────────────

enum _View { groups, list, detail }

class _MessagesPopup extends ConsumerStatefulWidget {
  final String? initialGroup;
  const _MessagesPopup({this.initialGroup});

  @override
  ConsumerState<_MessagesPopup> createState() => _MessagesPopupState();
}

class _MessagesPopupState extends ConsumerState<_MessagesPopup> {
  _View _view = _View.groups;
  String _group = '';
  List<MessageRow> _messages = [];
  MessageRow? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(messagesControllerProvider.notifier).load();
      if (widget.initialGroup != null) _openGroup(widget.initialGroup!);
    });
  }

  Future<void> _openGroup(String group) async {
    final msgs =
        await ref.read(messagesControllerProvider.notifier).messagesForGroup(group);
    if (!mounted) return;
    setState(() {
      _group = group;
      _messages = msgs;
      _view = _View.list;
    });
  }

  Future<void> _openMessage(MessageRow m) async {
    await ref.read(messagesControllerProvider.notifier).openMessage(m);
    if (!mounted) return;
    final msgs =
        await ref.read(messagesControllerProvider.notifier).messagesForGroup(_group);
    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _selected = m;
      _view = _View.detail;
    });
  }

  void _back() {
    switch (_view) {
      case _View.detail:
        setState(() => _view = _View.list);
      case _View.list:
        setState(() => _view = _View.groups);
      case _View.groups:
        Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      children: switch (_view) {
        _View.groups => _groups(),
        _View.list => _list(),
        _View.detail => _detail(),
      },
    );
  }

  List<Widget> _groups() {
    final st = ref.watch(messagesControllerProvider);
    final primary = Theme.of(context).colorScheme.primary;
    return [
      _redHeader(context, 'MESSAGES'),
      Container(
        color: const Color(0xFFEDEDED),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: const Row(
          children: [
            Expanded(
                child: Text('GROUP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            Text('UNREAD',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
      if (st.loading && st.groups.isEmpty)
        const Padding(
            padding: EdgeInsets.all(28), child: CircularProgressIndicator())
      else
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final g in st.groups) ...[
                  InkWell(
                    onTap: () => _openGroup(g.name),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(g.name,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: g.unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: g.unreadCount > 0
                                        ? primary
                                        : Colors.black)),
                          ),
                          Text('${g.unreadCount}',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      g.unreadCount > 0 ? primary : Colors.black)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                ],
              ],
            ),
          ),
        ),
      _bottomBar(context, 'EXIT', () => Navigator.pop(context)),
    ];
  }

  List<Widget> _list() {
    return [
      _redHeader(context, 'RECEIVED MESSAGES'),
      Flexible(
        child: _messages.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No messages in $_group',
                    style: const TextStyle(color: Colors.grey)))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    for (final m in _messages) ...[
                      _ReceivedRow(message: m, onTap: () => _openMessage(m)),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    ],
                  ],
                ),
              ),
      ),
      _bottomBar(context, 'EXIT', _back),
    ];
  }

  List<Widget> _detail() {
    final m = _selected;
    if (m == null) return [const SizedBox.shrink()];
    return [
      _redHeader(context, m.notificationType.isEmpty ? 'MESSAGE' : m.notificationType),
      Container(
        width: double.infinity,
        color: const Color(0xFFEDEDED),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(m.contactName.isEmpty ? 'CS REP' : m.contactName,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            Text('(${m.lastCommunicationDate})',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
      const Divider(height: 1, color: Color(0xFFCCCCCC)),
      Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(m.messageBody,
              style: const TextStyle(fontSize: 14, height: 1.45, color: Colors.black)),
        ),
      ),
      _bottomBar(context, 'BACK', _back),
    ];
  }
}

/// RECEIVED MESSAGES row: CONV ID, owner + date, dept/queue, body preview.
class _ReceivedRow extends StatelessWidget {
  final MessageRow message;
  final VoidCallback onTap;
  const _ReceivedRow({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final unread = !message.isRead;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: unread ? const Color(0xFFFFF8F8) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: const Color(0xFFEDEDED),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  const Text('CONV ID  ',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Expanded(
                    child: Text(
                      message.convId.isEmpty ? message.messageKey : message.convId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(message.contactName.isEmpty ? 'CS REP' : message.contactName,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: unread ? primary : Colors.black54)),
                ),
                Text(message.lastCommunicationDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            if (message.notificationType.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(message.notificationType,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
            const SizedBox(height: 2),
            Text(
              message.messageBody,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: unread ? Colors.black : Colors.black54,
                  fontWeight: unread ? FontWeight.w500 : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
