/// Dart port of RemoteFeedsLoader.java.
///
/// Pipeline on each side (mirror in tools/encrypt_feeds.py):
///   1. Fetch base64-encoded blob = IV[12] || AES_GCM(gzip(JSON)) || tag[16].
///   2. Base64 decode -> AES-256-GCM decrypt (key = SHA-256 of PASSPHRASE).
///   3. Gunzip the plaintext -> UTF-8 JSON string.
///   4. Cache JSON in the app's files dir + last-fetch timestamp.
///
/// The passphrase is embedded in the app bundle. This is deliberate
/// light-touch obfuscation — feeds are public portal URLs anyway; goal is to
/// prevent casual scraping of the remote config.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteFeedsLoader {
  RemoteFeedsLoader._();

  /// Keep in sync with tools/encrypt_feeds.py#PASSPHRASE and
  /// RemoteFeedsLoader.java#PASSPHRASE.
  static const String _passphrase =
      'pantaujalan-feeds-v1-crowja-global-tech-labs';

  // Public GitHub Gist. The /raw/default_feeds.enc endpoint (no SHA)
  // always resolves to the latest revision, so the Flutter client reads
  // the same live config as the Android client.
  static const String _remoteUrl =
      'https://gist.githubusercontent.com/ardika/c91fde4c1c37a1ee8487edd39069c4f2/raw/default_feeds.enc';

  static const String _cacheFile = 'remote_feeds.json';
  static const String _prefKeyLastFetch = 'remote_feeds_last_fetch_ms';
  static const String _prefKeyEtag = 'remote_feeds_etag';

  /// Skip fetch if cache is younger than this.
  static const Duration _freshTtl = Duration(hours: 6);

  static const Duration _connectTimeout = Duration(seconds: 12);

  // --- Public API --------------------------------------------------------

  /// Fire-and-forget background refresh. Safe to call at any point during
  /// app startup. Errors are swallowed so network failures never crash the
  /// host app.
  static Future<void> refreshAsync() async {
    try {
      await _fetchAndStore();
    } catch (e, st) {
      // ignore: avoid_print
      print('RemoteFeedsLoader: refresh failed: $e\n$st');
    }
  }

  /// Decrypted JSON from the on-disk cache, or null if no cache exists.
  static Future<String?> readCachedJson() async {
    final file = await _cacheFilePath();
    if (!await file.exists()) return null;
    final len = await file.length();
    if (len == 0) return null;
    try {
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  static Future<int> lastFetchMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKeyLastFetch) ?? 0;
  }

  // --- Internals ---------------------------------------------------------

  static Future<File> _cacheFilePath() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_cacheFile');
  }

  static Future<void> _fetchAndStore() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_prefKeyLastFetch) ?? 0;
    final file = await _cacheFilePath();
    final age = DateTime.now().millisecondsSinceEpoch - lastMs;
    if (await file.exists() &&
        await file.length() > 0 &&
        age >= 0 &&
        age < _freshTtl.inMilliseconds) {
      return; // cache fresh enough
    }

    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(_remoteUrl));
      req.headers['User-Agent'] = 'PantauJalan/flutter';
      req.headers['Accept'] = 'text/plain, */*';
      final etag = prefs.getString(_prefKeyEtag);
      if (etag != null && await file.exists() && await file.length() > 0) {
        req.headers['If-None-Match'] = etag;
      }

      final resp = await client.send(req).timeout(_connectTimeout);
      if (resp.statusCode == HttpStatus.notModified) {
        await prefs.setInt(
            _prefKeyLastFetch, DateTime.now().millisecondsSinceEpoch);
        return;
      }
      if (resp.statusCode != HttpStatus.ok) {
        return;
      }

      final body = await resp.stream.bytesToString();
      final blob = base64.decode(body.trim());
      final compressed = await _decryptGcm(blob);
      if (compressed.isEmpty) return;
      final plaintextBytes = gzip.decode(compressed);
      final plaintext = utf8.decode(plaintextBytes);
      if (plaintext.isEmpty) return;

      // Atomic write: tmp -> rename.
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(plaintext, flush: true);
      if (await file.exists()) await file.delete();
      await tmp.rename(file.path);

      final newEtag = resp.headers['etag'];
      await prefs.setInt(
          _prefKeyLastFetch, DateTime.now().millisecondsSinceEpoch);
      if (newEtag != null) await prefs.setString(_prefKeyEtag, newEtag);
    } finally {
      client.close();
    }
  }

  /// AES-256-GCM. blob = IV[12] || ciphertext || tag[16].
  /// Returns the raw gzipped bytes (caller gunzips).
  static Future<List<int>> _decryptGcm(Uint8List blob) async {
    if (blob.length < 12 + 16) return const [];
    final iv = blob.sublist(0, 12);
    // `cryptography` splits cipher + MAC: last 16 bytes are the GCM tag.
    final ct = blob.sublist(12, blob.length - 16);
    final tag = blob.sublist(blob.length - 16);

    // SHA-256 of PASSPHRASE -> 32-byte AES key.
    final keyBytes = await Sha256().hash(utf8.encode(_passphrase));
    final secretKey = SecretKey(keyBytes.bytes);

    final algo = AesGcm.with256bits();
    final secretBox = SecretBox(ct, nonce: iv, mac: Mac(tag));
    final clear = await algo.decrypt(secretBox, secretKey: secretKey);
    return clear;
  }
}
