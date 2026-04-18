import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/feed.dart';
import '../theme/app_theme.dart';

/// Equivalent of ViewerActivity. HLS streams go through `video_player`
/// (AVPlayer on iOS, ExoPlayer on Android); everything else falls back to
/// an in-app WebView.
///
/// The persistent interstitial-ad timer is not ported yet — that'll land
/// once the AdMob unit IDs are plugged in for both platforms.
class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key, required this.feed});
  final Feed feed;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  VideoPlayerController? _video;
  WebViewController? _web;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final f = widget.feed;
    if (f.type == FeedType.hls) {
      try {
        final c = VideoPlayerController.networkUrl(
          Uri.parse(f.url),
          httpHeaders: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) Chrome/120 Safari/537.36',
            'Referer': _originOf(f.url) ?? '',
          },
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await c.initialize();
        c.setLooping(false);
        c.play();
        if (!mounted) return;
        setState(() => _video = c);
      } catch (e) {
        setState(() => _error = '$e');
      }
      return;
    }

    // MJPEG wrapped in an <img>, or raw WEB portal.
    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bgDeep);
    if (f.type == FeedType.mjpeg) {
      final html = '''
        <!doctype html><html><head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>html,body{margin:0;padding:0;background:#000;height:100%}
        img{display:block;width:100%;height:100%;object-fit:contain}</style>
        </head><body><img src="${Uri.encodeFull(f.url)}"/></body></html>
      ''';
      await ctrl.loadHtmlString(html, baseUrl: f.url);
    } else {
      await ctrl.loadRequest(Uri.parse(f.url));
    }
    if (!mounted) return;
    setState(() => _web = ctrl);
  }

  String? _originOf(String url) {
    try {
      final u = Uri.parse(url);
      final port = u.hasPort ? ':${u.port}' : '';
      return '${u.scheme}://${u.host}$port/';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.feed;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_video != null && _video!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _video!.value.aspectRatio,
                child: VideoPlayer(_video!),
              ),
            )
          else if (_web != null)
            WebViewWidget(controller: _web!)
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'CONNECTION LOST\n\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.accentRed,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen),
            ),

          // Top HUD.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${(f.city ?? '').toUpperCase()} · ${f.type.chipLabel}',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontFamily: 'monospace',
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
