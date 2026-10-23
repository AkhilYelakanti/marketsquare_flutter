import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/item_repository.dart';
import '../../data/session/session_providers.dart';
import '../../router/app_routes.dart';
import '../orderentry/order_widgets.dart';

/// Port of native `SearchDealsScreen`: pick DEPARTMENT / CATEGORY / AD PLAN and
/// an "effective next billing date" toggle, then SUBMIT to the deals list.
class SearchDealsScreen extends ConsumerStatefulWidget {
  const SearchDealsScreen({super.key});

  @override
  ConsumerState<SearchDealsScreen> createState() => _State();
}

class _State extends ConsumerState<SearchDealsScreen> {
  final _repo = ItemRepository();
  List<String> _depts = [];
  String? _dept;
  String _category = 'All';
  String? _adPlan;
  bool _nextBilling = false;

  @override
  void initState() {
    super.initState();
    _loadDepts();
  }

  Future<void> _loadDepts() async {
    final d = await _repo.distinctForKind('DEPT');
    if (mounted) setState(() => _depts = d);
  }

  void _submit() {
    final q = StringBuffer(Routes.itemFilteredList)
      ..write('?deals=true');
    if (_dept != null && _dept!.isNotEmpty) {
      q.write('&dept=${Uri.encodeComponent(_dept!)}');
    }
    context.push(q.toString());
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final categories = ref.read(sessionManagerProvider).getDealCategories();
    final adPlans = ref.read(sessionManagerProvider).getAdPlanDates();

    return Scaffold(
      appBar: orderAppBar(subtitle: 'SEARCH DEALS', height: 60),
      bottomNavigationBar: OrderBottomBar(onBack: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('DEPARTMENT:',
              _dropdown<String>(
                value: _dept,
                hint: 'department',
                items: _depts,
                onChanged: (v) => setState(() => _dept = v),
              )),
          const SizedBox(height: 16),
          _row('CATEGORY:',
              _dropdown<String>(
                value: _category,
                hint: 'All',
                items: categories,
                onChanged: (v) => setState(() => _category = v ?? 'All'),
              )),
          const SizedBox(height: 16),
          _row('AD PLAN:',
              _dropdown<String>(
                value: _adPlan,
                hint: 'select plan',
                items: adPlans,
                onChanged: (v) => setState(() => _adPlan = v),
              )),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text('DEALS EFFECTIVE NEXT BILLING DATE:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              InkWell(
                onTap: () => setState(() => _nextBilling = !_nextBilling),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _nextBilling ? primary : Colors.white,
                    border: Border.all(color: primary, width: 2),
                  ),
                  child: _nextBilling
                      ? const Icon(Icons.check, color: Colors.white, size: 26)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: Colors.black, width: 2)),
              ),
              child: const Text('SUBMIT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, Widget field) => Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(child: field),
        ],
      );

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFCCCCCC)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value as String?,
            hint: Text(hint, style: const TextStyle(color: Colors.black38)),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );
}
