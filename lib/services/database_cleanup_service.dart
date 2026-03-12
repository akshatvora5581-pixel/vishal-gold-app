import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum CleanupStage { idle, fetching, grouping, deleting, completed, error }

class CleanupProgress {
  final CleanupStage stage;
  final int totalFetched;
  final int deletedCount;
  final String? error;

  CleanupProgress({
    this.stage = CleanupStage.idle,
    this.totalFetched = 0,
    this.deletedCount = 0,
    this.error,
  });

  CleanupProgress copyWith({
    CleanupStage? stage,
    int? totalFetched,
    int? deletedCount,
    String? error,
  }) {
    return CleanupProgress(
      stage: stage ?? this.stage,
      totalFetched: totalFetched ?? this.totalFetched,
      deletedCount: deletedCount ?? this.deletedCount,
      error: error ?? this.error,
    );
  }
}

class DatabaseCleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ValueNotifier<CleanupProgress> progress = ValueNotifier(
    CleanupProgress(),
  );

  static const int fetchBatchSize = 5000;
  static const int firestoreBatchLimit = 490;
  static const int keepPerSubCategory = 9;

  Future<void> runCleanup() async {
    try {
      progress.value = CleanupProgress(stage: CleanupStage.fetching);

      int totalFetched = 0;
      int totalDeleted = 0;
      bool hasMore = true;

      while (hasMore) {
        progress.value = progress.value.copyWith(stage: CleanupStage.fetching);

        // Fetch products in batches
        final snapshot = await _firestore
            .collection('products')
            .limit(fetchBatchSize)
            .get();

        if (snapshot.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final currentFetchDocs = snapshot.docs;
        totalFetched += currentFetchDocs.length;

        progress.value = progress.value.copyWith(
          totalFetched: totalFetched,
          stage: CleanupStage.deleting,
        );

        // Delete THIS batch's products using firestore batches
        for (int i = 0; i < currentFetchDocs.length; i += firestoreBatchLimit) {
          final batch = _firestore.batch();
          final end = (i + firestoreBatchLimit < currentFetchDocs.length)
              ? i + firestoreBatchLimit
              : currentFetchDocs.length;

          final currentChunk = currentFetchDocs.sublist(i, end);
          for (final doc in currentChunk) {
            batch.delete(doc.reference);
          }

          await batch.commit();
          totalDeleted += currentChunk.length;

          progress.value = progress.value.copyWith(
            deletedCount: totalDeleted,
          );

          // Brief safety delay between commits
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Delay to prevent overwhelming the device/connection
        await Future.delayed(const Duration(milliseconds: 200));

        // If we fetched less than the limit, it means there are no more docs
        if (currentFetchDocs.length < fetchBatchSize) {
          hasMore = false;
        }
      }

      progress.value = progress.value.copyWith(stage: CleanupStage.completed);
    } catch (e) {
      progress.value = progress.value.copyWith(
        stage: CleanupStage.error,
        error: e.toString(),
      );
    }
  }

  Future<void> runSubcategoryCleanup() async {
    try {
      progress.value = CleanupProgress(stage: CleanupStage.fetching);

      int totalFetched = 0;
      int totalDeleted = 0;
      bool hasMore = true;

      while (hasMore) {
        progress.value = progress.value.copyWith(stage: CleanupStage.fetching);

        // Fetch subcategories in batches
        final snapshot = await _firestore
            .collection('subcategories')
            .limit(fetchBatchSize)
            .get();

        if (snapshot.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final currentFetchDocs = snapshot.docs;
        totalFetched += currentFetchDocs.length;

        progress.value = progress.value.copyWith(
          totalFetched: totalFetched,
          stage: CleanupStage.deleting,
        );

        // Delete THIS batch's subcategories using firestore batches
        for (int i = 0; i < currentFetchDocs.length; i += firestoreBatchLimit) {
          final batch = _firestore.batch();
          final end = (i + firestoreBatchLimit < currentFetchDocs.length)
              ? i + firestoreBatchLimit
              : currentFetchDocs.length;

          final currentChunk = currentFetchDocs.sublist(i, end);
          for (final doc in currentChunk) {
            batch.delete(doc.reference);
          }

          await batch.commit();
          totalDeleted += currentChunk.length;

          progress.value = progress.value.copyWith(
            deletedCount: totalDeleted,
          );

          // Brief safety delay between commits
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Delay to prevent overwhelming the device/connection
        await Future.delayed(const Duration(milliseconds: 200));

        // If we fetched less than the limit, it means there are no more docs
        if (currentFetchDocs.length < fetchBatchSize) {
          hasMore = false;
        }
      }

      progress.value = progress.value.copyWith(stage: CleanupStage.completed);
    } catch (e) {
      progress.value = progress.value.copyWith(
        stage: CleanupStage.error,
        error: e.toString(),
      );
    }
  }
}
