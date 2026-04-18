import 'package:flutter/material.dart';

import '../data/feed_repository.dart';
import '../models/feed.dart';
import '../theme/app_theme.dart';
import 'viewer_screen.dart';

/// Equivalent of MainActivity. Shows the feed grid + status strip.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Future<List<Feed>> _feedsFuture;

  @override
  void initState() {
    super.initState();
    _feedsFuture = FeedRepository.instance.listAll();
  }

  Future<void> _refresh() async {
    FeedRepository.instance.invalidateCache();
    setState(() {
      _feedsFuture = FeedRepository.instance.listAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'PANTAUJALAN',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.accentGreen,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '// INDONESIA PUBLIC CCTV MONITOR',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: AppColors.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Feed>>(
        future: _feedsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'ERR: ${snap.error}',
                style: const TextStyle(color: AppColors.accentRed),
              ),
            );
          }
          final feeds = snap.data ?? const [];
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.accentGreen,
            backgroundColor: AppColors.bgPanel,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _StatusStrip(count: feeds.length)),
                SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: feeds.length,
                    itemBuilder: (ctx, i) => _FeedTile(feed: feeds[i]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPanelAlt,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentRed,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'STATUS · READY',
            style: TextStyle(
              color: AppColors.accentGreen,
              fontFamily: 'monospace',
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Text(
            '$count FEEDS',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.feed});
  final Feed feed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgPanel,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ViewerScreen(feed: feed)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.bgDeep,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.videocam_outlined,
                          color: AppColors.textTertiary,
                          size: 40,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accentPurple.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.accentPurple),
                          ),
                          child: Text(
                            feed.type.chipLabel,
                            style: const TextStyle(
                              color: AppColors.accentPurple,
                              fontFamily: 'monospace',
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feed.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
              if (feed.city != null && feed.city!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    feed.city!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontFamily: 'monospace',
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
