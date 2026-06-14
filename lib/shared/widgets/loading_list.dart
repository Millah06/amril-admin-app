import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Loading list - shimmer rows for list screens
// ─────────────────────────────────────────────────────────────────────────────

class LoadingList extends StatelessWidget {
  const LoadingList({super.key, this.itemCount = 8});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.divider,
      highlightColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: itemCount,
        itemBuilder: (_, __) => const _ShimmerListTile(),
      ),
    );
  }
}

class _ShimmerListTile extends StatelessWidget {
  const _ShimmerListTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            const _ShimmerBox(width: 44, height: 44, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: double.infinity, height: 12, radius: 4),
                  const SizedBox(height: 8),
                  const _ShimmerBox(width: 160, height: 10, radius: 4),
                  const SizedBox(height: 8),
                  const _ShimmerBox(width: 90, height: 10, radius: 4),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ShimmerBox(width: 70, height: 12, radius: 4),
                SizedBox(height: 8),
                _ShimmerBox(width: 50, height: 10, radius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading grid - shimmer cards for dashboard
// ─────────────────────────────────────────────────────────────────────────────

class LoadingGrid extends StatelessWidget {
  const LoadingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.divider,
      highlightColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: List.generate(4, (_) => const _ShimmerCard()),
          ),
          const SizedBox(height: 16),
          const _ShimmerCard(height: 120),
          const SizedBox(height: 16),
          const _ShimmerCard(height: 80),
          const SizedBox(height: 8),
          const _ShimmerCard(height: 80),
          const SizedBox(height: 8),
          const _ShimmerCard(height: 80),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({this.height});
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable box
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.width, required this.height, required this.radius});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}