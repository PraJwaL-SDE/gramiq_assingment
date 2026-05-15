import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final IconData? icon;
  final Color? iconColor;

  const CustomDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.icon,
    this.iconColor,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 48, color: iconColor ?? AppColors.primary),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: onCancel ?? () => Navigator.pop(context),
            child: Text(
              cancelText!,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        if (confirmText != null)
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmText!),
          ),
      ],
    );
  }
}
