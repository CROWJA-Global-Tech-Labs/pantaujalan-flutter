/// Dart port of FeedRepository.java.
///
/// Loads feeds from the remote-cached JSON (populated by RemoteFeedsLoader)
/// with a fall-through to the bundled assets/default_feeds.json that ships
/// inside the app binary, then merges with user-added feeds persisted in
/// SharedPreferences.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/feed.dart';
import 'remote_feeds_loader.dart';

class FeedRepository {
  FeedRepository._();
  static final FeedRepository instance = FeedRepository._();

  static const String _keyUserFeeds = 'user_feeds';
  static const String _keyHiddenDefaults = 'hidden_defaults';

  List<Feed>? _cachedDefaults;

  /// Returns `bundled defaults (remote cache preferred) \ hidden` ∪ `user-added`.
  Future<List<Feed>> listAll() async {
    final defaults = await _bundled();
    final hidden = await _hiddenDefaults();
    final visible = defaults.where((f) => !hidden.contains(f.id)).toList();
    final users = await _userFeeds();
    return [...visible, ...users];
  }

  Future<Feed?> findById(String? id) async {
    if (id == null || id.isEmpty) return null;
    final all = await listAll();
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Force the next `listAll` to re-read the underlying JSON (e.g. after
  /// the background RemoteFeedsLoader finishes a fetch).
  void invalidateCache() => _cachedDefaults = null;

  // --- Mutations -------------------------------------------------------

  Future<void> addUserFeed(Feed f) async {
    final cur = await _userFeeds();
    cur.add(f);
    await _writeUserFeeds(cur);
  }

  Future<void> removeFeed(String id) async {
    // User feed? Drop it. Default feed? Hide it.
    final cur = await _userFeeds();
    final before = cur.length;
    cur.removeWhere((f) => f.id == id);
    if (cur.length != before) {
      await _writeUserFeeds(cur);
      return;
    }
    final hidden = await _hiddenDefaults();
    if (!hidden.contains(id)) {
      hidden.add(id);
      await _writeHiddenDefaults(hidden);
    }
  }

  Future<void> restoreAllDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHiddenDefaults);
  }

  String newId() =>
      'u_${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';

  // --- Persistence -----------------------------------------------------

  Future<List<Feed>> _userFeeds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUserFeeds);
    if (raw == null || raw.isEmpty) return [];
    try {
      final arr = json.decode(raw);
      if (arr is! List) return [];
      return arr
          .whereType<Map<String, dynamic>>()
          .map((o) => Feed.fromJson(o, userAdded: true))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeUserFeeds(List<Feed> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyUserFeeds, json.encode(list.map((f) => f.toJson()).toList()));
  }

  Future<List<String>> _hiddenDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyHiddenDefaults);
    if (raw == null || raw.isEmpty) return [];
    try {
      final arr = json.decode(raw);
      if (arr is List) return arr.map((e) => e.toString()).toList();
    } catch (_) {}
    return [];
  }

  Future<void> _writeHiddenDefaults(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHiddenDefaults, json.encode(ids));
  }

  // --- Bundled defaults ------------------------------------------------

  Future<List<Feed>> _bundled() async {
    if (_cachedDefaults != null) return _cachedDefaults!;
    // 1. Remote-decrypted cache (populated by RemoteFeedsLoader).
    String? raw = await RemoteFeedsLoader.readCachedJson();
    // 2. Bundled asset fallback.
    raw ??= await _readAssetString('assets/default_feeds.json');
    if (raw == null || raw.trim().isEmpty) return _cachedDefaults = const [];
    try {
      final parsed = json.decode(raw);
      List<dynamic> arr;
      if (parsed is List) {
        arr = parsed;
      } else if (parsed is Map<String, dynamic> && parsed['feeds'] is List) {
        arr = parsed['feeds'] as List;
      } else {
        return _cachedDefaults = const [];
      }
      return _cachedDefaults = arr
          .whereType<Map<String, dynamic>>()
          .map((o) => Feed.fromJson(o))
          .toList();
    } catch (_) {
      return _cachedDefaults = const [];
    }
  }

  Future<String?> _readAssetString(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      return null;
    }
  }
}
