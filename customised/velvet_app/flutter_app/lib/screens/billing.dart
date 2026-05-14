import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:outgoing_notifications/config/app_constants.dart';
import 'package:outgoing_notifications/services/common/api_client.dart';
import 'package:outgoing_notifications/services/storage/secure_storage_service.dart';
import 'background/wavy_scaffold.dart';

String _formatPaidAt(String? raw) {
  if (raw == null) return '';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  final local = dt.toLocal();
  final day = local.day;
  final suffix = (day >= 11 && day <= 13)
      ? 'th'
      : switch (day % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
  return '${DateFormat('MMMM').format(local)} $day$suffix, ${local.year}';
}

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _apiClient = ApiClient(SecureStorageService());
  Map<String, dynamic>? _subscription;
  Map<String, dynamic>? _currentPackage;
  List<dynamic> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiClient.get(AppConstants.clientsMyPath);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final sub = data['subscription'] as Map<String, dynamic>?;
        setState(() {
          _subscription = sub;
          _currentPackage = sub?['currentPackage'] as Map<String, dynamic>?;
          _payments = (sub?['payments'] as List<dynamic>?) ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load subscription data.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not reach the server.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return WavyScaffold(
      theme: theme,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Subscription',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _loadSubscription,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _ErrorView(error: _error!, onRetry: _loadSubscription)
                      : _subscription == null
                          ? _NoSubscriptionView(cs: cs)
                          : _SubscriptionView(
                              subscription: _subscription!,
                              currentPackage: _currentPackage,
                              payments: _payments,
                              cs: cs,
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionView extends StatelessWidget {
  final Map<String, dynamic> subscription;
  final Map<String, dynamic>? currentPackage;
  final List<dynamic> payments;
  final ColorScheme cs;

  const _SubscriptionView({
    required this.subscription,
    required this.currentPackage,
    required this.payments,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final totalAllocated = (subscription['totalAllocated'] as num?)?.toInt() ?? 0;
    final totalConsumed = (subscription['totalConsumed'] as num?)?.toInt() ?? 0;
    final totalRemaining = (subscription['totalRemaining'] as num?)?.toInt() ?? 0;
    final progress = totalAllocated > 0 ? totalConsumed / totalAllocated : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // ── Package banner ───────────────────────────────────────────
        if (currentPackage != null)
          _PackageBanner(package: currentPackage!, cs: cs),
        const SizedBox(height: 14),

        // ── Usage overview ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SMS Usage',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 0.9 ? Colors.red : cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _UsageStat(
                    label: 'Remaining',
                    value: totalRemaining.toString(),
                    color: totalRemaining == 0 ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _UsageStat(
                    label: 'Consumed',
                    value: totalConsumed.toString(),
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  _UsageStat(
                    label: 'Allocated',
                    value: totalAllocated.toString(),
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Payment history ──────────────────────────────────────────
        if (payments.isNotEmpty) ...[
          Text(
            'Payment History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...payments.reversed.map(
            (p) => _PaymentCard(payment: p as Map<String, dynamic>, cs: cs),
          ),
        ],

        if (totalRemaining == 0 && totalAllocated > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your SMS balance is exhausted. Please contact your administrator to top up.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PackageBanner extends StatelessWidget {
  final Map<String, dynamic> package;
  final ColorScheme cs;

  const _PackageBanner({required this.package, required this.cs});

  @override
  Widget build(BuildContext context) {
    final name = package['name'] as String? ?? '—';
    final description = package['description'] as String? ?? '';
    final pricePerSms = (package['pricePerSms'] as num?)?.toDouble() ?? 0;
    final maxLimit = package['maxSmsLimit'] as int?;

    final (badgeColor, badgeIcon) = switch (name.toLowerCase()) {
      'enterprise' => (Colors.amber, Icons.workspace_premium_rounded),
      'business' => (cs.primary, Icons.business_center_rounded),
      _ => (Colors.teal, Icons.rocket_launch_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor.withValues(alpha: 0.18),
            badgeColor.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${pricePerSms.toStringAsFixed(3)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                ),
              ),
              Text(
                'per SMS',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              if (maxLimit != null)
                Text(
                  'up to ${_formatNumber(maxLimit)}',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(0)}k' : '$n';
}

class _UsageStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _UsageStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final ColorScheme cs;

  const _PaymentCard({required this.payment, required this.cs});

  @override
  Widget build(BuildContext context) {
    final amountPaid = (payment['amountPaid'] as num?)?.toDouble() ?? 0;
    final allocated = (payment['smsAllocated'] as num?)?.toInt() ?? 0;
    final consumed = (payment['smsConsumed'] as num?)?.toInt() ?? 0;
    final remaining = (payment['smsRemaining'] as num?)?.toInt() ?? 0;
    final paidAt = payment['paidAt'] as String?;
    final notes = payment['notes'] as String?;
    final packageName =
        (payment['package'] as Map<String, dynamic>?)?['name'] as String? ?? '—';
    final progress = allocated > 0 ? consumed / allocated : 0.0;
    final isExhausted = remaining == 0 && allocated > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: isExhausted
            ? Border.all(color: Colors.red.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  packageName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: cs.primary,
                  ),
                ),
              ),
              Text(
                '\$${amountPaid.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          if (paidAt != null) ...[
            const SizedBox(height: 2),
            Text(
              _formatPaidAt(paidAt),
              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
            ),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              notes,
              style: TextStyle(
                fontSize: 11.5,
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isExhausted ? Colors.red : cs.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniStat(label: 'Allocated', value: '$allocated', cs: cs),
              _MiniStat(label: 'Consumed', value: '$consumed', cs: cs),
              _MiniStat(
                label: 'Remaining',
                value: '$remaining',
                cs: cs,
                highlight: isExhausted ? Colors.red : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final Color? highlight;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.cs,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: highlight ?? cs.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _NoSubscriptionView extends StatelessWidget {
  final ColorScheme cs;

  const _NoSubscriptionView({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No subscription yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact your administrator to assign a package and allocate SMS credit.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(error, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
