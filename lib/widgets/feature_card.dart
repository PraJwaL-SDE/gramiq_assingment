import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? amount;
  final IconData icon;
  final bool isLarge;
  final VoidCallback? onTap;

  const FeatureCard({
    super.key,
    this.title,
    this.subtitle,
    this.amount,
    required this.icon,
    this.isLarge = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isLarge ? _buildLargeLayout() : _buildSmallLayout(),
      ),
    );
  }

  Widget _buildLargeLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (amount != null)
          Text(
            amount!,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
        const SizedBox(height: 16),
        Icon(icon, size: 60, color: const Color(0xFF3F3D89)),
        const SizedBox(height: 16),
        if (title != null)
          Text(
            title!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 8),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildSmallLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: const Color(0xFF3F3D89)),
        const SizedBox(height: 12),
        if (title != null)
          Text(
            title!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
