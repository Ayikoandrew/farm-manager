import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/payment.dart';
import '../../providers/payment_providers.dart';
import '../../utils/currency_utils.dart';
import '../../utils/responsive_layout.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final filterNotifier = ref.read(paymentFilterProvider.notifier);
      switch (_tabController.index) {
        case 0:
          filterNotifier.setType(null);
          break;
        case 1:
          filterNotifier.setType(PaymentType.incoming);
          break;
        case 2:
          filterNotifier.setType(PaymentType.outgoing);
          break;
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(paymentFilterProvider.notifier).setSearchQuery(null);
      }
    });
  }

  void _onSearchChanged(String query) {
    ref.read(paymentFilterProvider.notifier).setSearchQuery(query);
  }

  void _showFilterBottomSheet() {
    final filter = ref.read(paymentFilterProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        currentFilter: filter,
        onApply: (newFilter) {
          final notifier = ref.read(paymentFilterProvider.notifier);
          notifier.setStatus(newFilter.status);
          notifier.setDateRange(newFilter.startDate, newFilter.endDate);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentHistoryProvider);
    final filter = ref.watch(paymentFilterProvider);
    final formatter = ref.read(ugxFormatterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: _onSearchChanged,
              )
            : const Text('Transaction History'),
        centerTitle: !_showSearch,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Badge(
              isLabelVisible:
                  filter.status != null ||
                  filter.startDate != null ||
                  filter.endDate != null,
              child: const Icon(Icons.tune),
            ),
            tooltip: 'Filter',
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(paymentHistoryProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: paymentsAsync.when(
        data: (payments) {
          // Apply search filter client-side
          var filteredPayments = payments;
          if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
            final query = filter.searchQuery!.toLowerCase();
            filteredPayments = payments.where((p) {
              return (p.phoneNumber?.toLowerCase().contains(query) ?? false) ||
                  p.description.toLowerCase().contains(query) ||
                  (p.recipientName?.toLowerCase().contains(query) ?? false) ||
                  (p.transactionRef?.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          return TabBarView(
            controller: _tabController,
            children: List.generate(3, (tabIndex) {
              // The provider already filters by type based on tab
              // But since we share one list, filter here for tab display
              var tabPayments = filteredPayments;
              if (tabIndex == 1) {
                tabPayments = filteredPayments
                    .where((p) => p.type == PaymentType.incoming)
                    .toList();
              } else if (tabIndex == 2) {
                tabPayments = filteredPayments
                    .where((p) => p.type == PaymentType.outgoing)
                    .toList();
              }

              // Apply status filter
              if (filter.status != null) {
                tabPayments = tabPayments
                    .where((p) => p.status == filter.status)
                    .toList();
              }

              if (tabPayments.isEmpty) {
                return _EmptyState(
                  tabIndex: tabIndex,
                  hasFilter: filter.hasFilters,
                );
              }

              final groupedPayments = _groupPaymentsByDate(tabPayments);

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(paymentHistoryProvider),
                child: ResponsiveLayout(
                  maxWidth: 600,
                  padding: EdgeInsets.zero,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupedPayments.length,
                    itemBuilder: (context, index) {
                      final entry = groupedPayments.entries.elementAt(index);
                      final dateLabel = entry.key;
                      final dayPayments = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    dateLabel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...dayPayments.map(
                            (payment) => _TransactionCard(
                              payment: payment,
                              formatter: formatter,
                              onTap: () => _showPaymentDetails(
                                context,
                                payment,
                                formatter,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
              );
            }),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error.toString(),
          onRetry: () => ref.invalidate(paymentHistoryProvider),
        ),
      ),
    );
  }

  Map<String, List<Payment>> _groupPaymentsByDate(List<Payment> payments) {
    final grouped = <String, List<Payment>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final payment in payments) {
      final paymentDate = DateTime(
        payment.createdAt.year,
        payment.createdAt.month,
        payment.createdAt.day,
      );

      String label;
      if (paymentDate == today) {
        label = 'Today';
      } else if (paymentDate == yesterday) {
        label = 'Yesterday';
      } else if (now.difference(paymentDate).inDays < 7) {
        final weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        label = weekdays[paymentDate.weekday - 1];
      } else {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        label =
            '${paymentDate.day} ${months[paymentDate.month - 1]} ${paymentDate.year}';
      }

      grouped.putIfAbsent(label, () => []).add(payment);
    }

    return grouped;
  }

  void _showPaymentDetails(
    BuildContext context,
    Payment payment,
    CurrencyFormatter formatter,
  ) {
    final isIncoming = payment.type == PaymentType.incoming;
    final primaryColor = isIncoming ? Colors.green : Colors.orange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isIncoming
                        ? [Colors.green.shade400, Colors.teal.shade400]
                        : [Colors.orange.shade400, Colors.deepOrange.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncoming
                            ? Icons.call_received_rounded
                            : Icons.call_made_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${isIncoming ? '+' : '-'} ${formatter.format(payment.amount)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusChip(status: payment.status),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Details Section
              Text(
                'Transaction Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              _DetailCard(
                children: [
                  _DetailItem(
                    icon: Icons.swap_horiz,
                    label: 'Type',
                    value: isIncoming ? 'Money Received' : 'Money Sent',
                  ),
                  _DetailItem(
                    icon: Icons.description_outlined,
                    label: 'Description',
                    value: payment.description,
                  ),
                  _DetailItem(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: payment.phoneNumber ?? 'N/A',
                  ),
                  _DetailItem(
                    icon: Icons.signal_cellular_alt,
                    label: 'Network',
                    value: payment.network?.displayName ?? 'Unknown',
                  ),
                  if (payment.recipientName != null)
                    _DetailItem(
                      icon: Icons.person_outline,
                      label: isIncoming ? 'From' : 'To',
                      value: payment.recipientName!,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              _DetailCard(
                children: [
                  _DetailItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date & Time',
                    value: _formatDateTime(payment.createdAt),
                  ),
                  _DetailItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Reference',
                    value: payment.transactionRef ?? 'N/A',
                    isMonospace: true,
                  ),
                  if (payment.flutterwaveRef != null)
                    _DetailItem(
                      icon: Icons.tag,
                      label: 'Flutterwave ID',
                      value: payment.flutterwaveRef!,
                      isMonospace: true,
                    ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} at $hour:$minute';
  }
}

class _TransactionCard extends StatelessWidget {
  final Payment payment;
  final CurrencyFormatter formatter;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.payment,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncoming = payment.type == PaymentType.incoming;
    final primaryColor = isIncoming ? Colors.green : Colors.orange;
    final statusColor = _getStatusColor(payment.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncoming
                        ? Icons.call_received_rounded
                        : Icons.call_made_rounded,
                    color: primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(payment.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              payment.status.name[0].toUpperCase() +
                                  payment.status.name.substring(1),
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncoming ? '+' : '-'} ${formatter.format(payment.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                payment.network == MobileMoneyNetwork.mtnUganda
                                ? const Color(0xFFFFCC00)
                                : const Color(0xFFE40000),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          payment.network?.displayName ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.successful:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final int tabIndex;
  final bool hasFilter;

  const _EmptyState({required this.tabIndex, required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    final messages = [
      hasFilter ? 'No transactions match your filter' : 'No transactions yet',
      hasFilter
          ? 'No received payments match your filter'
          : 'No money received yet',
      hasFilter ? 'No sent payments match your filter' : 'No money sent yet',
    ];

    final icons = [
      Icons.receipt_long_outlined,
      Icons.call_received_rounded,
      Icons.call_made_rounded,
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icons[tabIndex], size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            messages[tabIndex],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Try changing your filter settings'
                : 'Your transactions will appear here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PaymentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status.name[0].toUpperCase() + status.name.substring(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case PaymentStatus.successful:
        return Colors.greenAccent;
      case PaymentStatus.pending:
        return Colors.yellowAccent;
      case PaymentStatus.failed:
        return Colors.redAccent;
      case PaymentStatus.cancelled:
        return Colors.grey.shade300;
    }
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map(
              (entry) => Column(
                children: [
                  entry.value,
                  if (entry.key < children.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Colors.grey.shade200),
                    ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMonospace;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontFamily: isMonospace ? 'monospace' : null,
                  fontSize: isMonospace ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final PaymentFilter currentFilter;
  final ValueChanged<PaymentFilter> onApply;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late PaymentStatus? _status;
  late DateTime? _startDate;
  late DateTime? _endDate;
  String? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _status = widget.currentFilter.status;
    _startDate = widget.currentFilter.startDate;
    _endDate = widget.currentFilter.endDate;
  }

  void _selectDateRange(String? range) {
    setState(() {
      _selectedDateRange = range;
      if (range == null) {
        _startDate = null;
        _endDate = null;
      } else {
        final now = DateTime.now();
        switch (range) {
          case 'today':
            _startDate = DateTime(now.year, now.month, now.day);
            _endDate = _startDate!.add(const Duration(days: 1));
            break;
          case 'week':
            final start = now.subtract(Duration(days: now.weekday - 1));
            _startDate = DateTime(start.year, start.month, start.day);
            _endDate = now;
            break;
          case 'month':
            _startDate = DateTime(now.year, now.month, 1);
            _endDate = now;
            break;
          case '30days':
            _startDate = now.subtract(const Duration(days: 30));
            _endDate = now;
            break;
        }
      }
    });
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Transactions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _status = null;
                    _startDate = null;
                    _endDate = null;
                    _selectedDateRange = null;
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Status Filter
          Text(
            'Status',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                isSelected: _status == null,
                onTap: () => setState(() => _status = null),
              ),
              ...PaymentStatus.values.map(
                (status) => _FilterChip(
                  label:
                      status.name[0].toUpperCase() + status.name.substring(1),
                  isSelected: _status == status,
                  color: _getStatusColor(status),
                  onTap: () => setState(() => _status = status),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Date Range Filter
          Text(
            'Date Range',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All Time',
                isSelected: _selectedDateRange == null,
                onTap: () => _selectDateRange(null),
              ),
              _FilterChip(
                label: 'Today',
                isSelected: _selectedDateRange == 'today',
                onTap: () => _selectDateRange('today'),
              ),
              _FilterChip(
                label: 'This Week',
                isSelected: _selectedDateRange == 'week',
                onTap: () => _selectDateRange('week'),
              ),
              _FilterChip(
                label: 'This Month',
                isSelected: _selectedDateRange == 'month',
                onTap: () => _selectDateRange('month'),
              ),
              _FilterChip(
                label: 'Last 30 Days',
                isSelected: _selectedDateRange == '30days',
                onTap: () => _selectDateRange('30days'),
              ),
              _FilterChip(
                label: 'Custom',
                isSelected: _selectedDateRange == 'custom',
                onTap: _selectCustomDateRange,
                icon: Icons.calendar_today,
              ),
            ],
          ),

          if (_selectedDateRange == 'custom' &&
              _startDate != null &&
              _endDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.date_range,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                widget.onApply(
                  PaymentFilter(
                    status: _status,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.successful:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveColor.withValues(alpha: 0.15)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? effectiveColor : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? effectiveColor : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? effectiveColor : Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
