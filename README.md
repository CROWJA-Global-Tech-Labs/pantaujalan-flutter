# pantaujalan_flutter

Flutter port of [PantauJalan](https://github.com/CROWJA-Global-Tech-Labs/PantauJalan) — the Android-native CCTV viewer — targeting both Android and iOS from a single Dart codebase.

## Status

**Scaffold.** Core plumbing (encrypted remote config, feed model, main grid, viewer) lands first. UI polish and feature parity with the native Android client (collection view, extraction engine, persistent ad timer, overflow menu, etc.) are follow-ups.

### What works now

- `RemoteFeedsLoader` — fetches `default_feeds.enc` from the same GitHub URL the Android app reads, decrypts AES-256-GCM, gunzips, caches in app-support dir with 6-hour TTL + ETag.
- `FeedRepository` — reads the decrypted JSON (falls back to bundled `assets/default_feeds.json`), merges with user-added feeds in SharedPreferences, lets the user hide defaults.
- `MainScreen` — 2-column grid of feeds with pull-to-refresh.
- `ViewerScreen` — HLS playback via `video_player` (AVPlayer on iOS, ExoPlayer on Android); MJPEG wrapped in a WebView `<img>`; generic WEB falls to WebView too.

### Not yet ported

- Collection view (nested camera lists per province) and the full extraction engine (`ConfigProvider`)
- Thumbnail generator + OFFLINE probing
- 3-dot overflow menu + Navigate-to-GMaps intent
- Persistent interstitial ad timer
- AdMob banner
- Add-your-own-feed flow
- Manage feeds screen
- About screen + privacy link-outs

## Run

```bash
cd pantaujalan_flutter
flutter pub get
flutter run -d <device-id>
```

Android build (AAB for Play Console):
```bash
flutter build appbundle --release
```

iOS build (requires Mac with Xcode):
```bash
flutter build ipa --release
```

## Remote config

Same encrypted blob as the Android client — single source of truth for feed URLs + extraction rules across both platforms. Update cycle:

```bash
# In the PantauJalan (Android) repo:
python tools/encrypt_feeds.py
cp tools/default_feeds.enc /tmp/pantaujalan-docs/
cd /tmp/pantaujalan-docs && git commit -am "update feeds" && git push
```

Every installed client (Android native + Flutter Android + Flutter iOS) picks up the new JSON on next launch.

## iOS-specific notes

- `video_player` → AVPlayer supports HLS natively. Referer header injected via `httpHeaders` in `VideoPlayerController.networkUrl`.
- MJPEG doesn't have a native iOS player — falls back to the WebView `<img>` trick.
- Portals that only serve HTTP (no HTTPS) need an ATS exception in `ios/Runner/Info.plist` before they'll load.
- AdMob IDs on iOS are separate from Android — needs a new app registration at `admob.google.com`.

## Keystore / signing

Not yet configured. Android AAB uploads to Play Console and iOS builds both need signing config before release builds.
