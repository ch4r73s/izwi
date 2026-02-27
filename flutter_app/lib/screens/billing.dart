import 'package:flutter/material.dart';
import 'background/wavy_scaffold.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  final int whatsappNotifications = 15;
  final double whatsappCostPerNotification = 1.5;
  final int smsNotifications = 25;
  final double smsCostPerNotification = 0.5;

  @override
  Widget build(BuildContext context) {
    final totalWhatsappCost = whatsappNotifications * whatsappCostPerNotification;
    final totalSmsCost = smsNotifications * smsCostPerNotification;
    final overallTotalCost = totalWhatsappCost + totalSmsCost;

    return WavyScaffold(
      theme: Theme.of(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Billing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BillingCard(
              title: 'WhatsApp Notifications',
              count: whatsappNotifications,
              unitCost: whatsappCostPerNotification,
              totalCost: totalWhatsappCost,
            ),
            const SizedBox(height: 10),
            _BillingCard(
              title: 'SMS Notifications',
              count: smsNotifications,
              unitCost: smsCostPerNotification,
              totalCost: totalSmsCost,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Overall Total',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '\$${overallTotalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Pay Now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillingCard extends StatelessWidget {
  final String title;
  final int count;
  final double unitCost;
  final double totalCost;

  const _BillingCard({
    required this.title,
    required this.count,
    required this.unitCost,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _line('Number of Notifications', '$count'),
          _line('Cost per Notification', '\$${unitCost.toStringAsFixed(2)}'),
          _line('Total Cost', '\$${totalCost.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Pay Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
