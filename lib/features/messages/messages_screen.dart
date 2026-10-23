import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/message.dart';
import '../orderentry/order_widgets.dart';
import 'messages_controller.dart';

/// Port of the native Messages dialog stack as a screen: group list → group
/// messages → message detail (in-screen back navigation).
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _State();
}

enum _View { groups, list, detail }

class _State extends ConsumerState<MessagesScreen> {
  _View _view = _View.groups;
  String _group = '';
  List<MessageRow> _messages = [];
  MessageRow? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(messagesControllerProvider.notifier).load());
  }

  Future<void> _openGroup(String group) async {
    final msgs = await ref.read(messagesControllerProvider.notifier).messagesForGroup(group);
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
    // reload the group so the read state updates
    final msgs = await ref.read(messagesControllerProvider.notifier).messagesForGroup(_group);
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
        context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(messagesControllerProvider);
    final subtitle = switch (_view) {
      _View.groups => 'MESSAGES',
      _View.list => _group,
      _View.detail => 'MESSAGE',
    };
    return Scaffold(
      appBar: orderAppBar(subtitle: subtitle, height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: _back),
      body: st.loading && _view == _View.groups
          ? const Center(child: CircularProgressIndicator())
          : switch (_view) {
              _View.groups => _groups(st),
              _View.list => _list(),
              _View.detail => _detail(),
            },
    );
  }

  Widget _groups(MessagesState st) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListView.separated(
      itemCount: st.groups.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (_, i) {
        final g = st.groups[i];
        return ListTile(
          title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: g.unreadCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                  child: Text('${g.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                )
              : const Icon(Icons.chevron_right),
          onTap: () => _openGroup(g.name),
        );
      },
    );
  }

  Widget _list() {
    if (_messages.isEmpty) {
      return const Center(
          child: Text('No messages in this group.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      itemCount: _messages.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (_, i) {
        final m = _messages[i];
        return ListTile(
          leading: Icon(m.isRead ? Icons.drafts_outlined : Icons.markunread,
              color: m.isRead ? Colors.grey : Theme.of(context).colorScheme.primary),
          title: Text(
            m.messageBody.isEmpty ? '(no text)' : m.messageBody,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: m.isRead ? FontWeight.normal : FontWeight.bold),
          ),
          subtitle: Text(m.lastCommunicationDate),
          onTap: () => _openMessage(m),
        );
      },
    );
  }

  Widget _detail() {
    final m = _selected;
    if (m == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (m.contactName.isNotEmpty)
          Text('From: ${m.contactName}', style: const TextStyle(fontWeight: FontWeight.bold)),
        if (m.lastCommunicationDate.isNotEmpty)
          Text(m.lastCommunicationDate, style: const TextStyle(color: Colors.black54)),
        const Divider(height: 24),
        Text(m.messageBody, style: const TextStyle(fontSize: 15)),
      ],
    );
  }
}
