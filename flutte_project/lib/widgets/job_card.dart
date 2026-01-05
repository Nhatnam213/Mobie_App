import 'package:flutter/material.dart';
import '../models/job_model.dart';

class JobCard extends StatelessWidget {
  final Job job;

  final bool isOwner;
  final bool isFavorite;

  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const JobCard({
    super.key,
    required this.job,
    required this.isOwner,
    required this.isFavorite,
    this.onTap,
    this.onFavoriteToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool canEdit = job.status == 'pending';

    // an toàn nếu quantity null/space
    final String qty = (job.quantity).trim();

    String statusText = '';
    Color statusColor = Colors.grey;

    if (isOwner) {
      if (job.status == 'pending') {
        statusText = '⏳ Chờ duyệt';
        statusColor = Colors.orange;
      } else if (job.status == 'approved') {
        statusText = '✅ Đã duyệt';
        statusColor = Colors.green;
      } else if (job.status == 'rejected') {
        statusText = '❌ Đã từ chối';
        statusColor = Colors.red;
      } else {
        statusText = '⏳ Chờ duyệt';
        statusColor = Colors.orange;
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== TITLE + FAVORITE =====
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onFavoriteToggle != null)
                  IconButton(
                    splashRadius: 22,
                    onPressed: onFavoriteToggle,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(isFavorite),
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),
            Text('💰 Lương: ${job.salary}'),
            Text('📍 Địa điểm: ${job.location}'),
            if (qty.isNotEmpty) Text('👥 Tuyển: $qty'),

            const SizedBox(height: 8),

            /// ===== STATUS =====
            if (isOwner)
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),

            /// ===== ACTIONS =====
            if (onEdit != null || onDelete != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null && canEdit)
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Sửa'),
                      onPressed: onEdit,
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Xóa'),
                      onPressed: onDelete,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
