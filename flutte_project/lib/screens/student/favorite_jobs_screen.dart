import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/job_model.dart';
import '../../widgets/job_card.dart';
import '../../services/favorite_job_store.dart';
import 'job_detail_screen.dart';

class FavoriteJobsScreen extends StatelessWidget {
  const FavoriteJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FavoriteJobStore.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Việc đã yêu thích')),
      body: StreamBuilder<List<String>>(
        stream: FavoriteJobStore.watchFavoriteJobIds(uid),
        builder: (context, snapIds) {
          if (!snapIds.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobIds = snapIds.data!;
          if (jobIds.isEmpty) {
            return const Center(child: Text('Chưa có việc yêu thích'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where(FieldPath.documentId, whereIn: jobIds)
                .snapshots(),
            builder: (context, snapJobs) {
              if (!snapJobs.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final jobs = snapJobs.data!.docs
                  .map(
                    (doc) =>
                        Job.fromMap(doc.id, doc.data() as Map<String, dynamic>),
                  )
                  .toList();

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final job = jobs[i];
                  return JobCard(
                    job: job,
                    isOwner: false,
                    isFavorite: true,

                    // 👉 NÚT XÓA YÊU THÍCH
                    onFavoriteToggle: () async {
                      try {
                        await FavoriteJobStore.toggle(job.id);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: ${e.toString()}')),
                          );
                        }
                      }
                    },

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(job: job),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
