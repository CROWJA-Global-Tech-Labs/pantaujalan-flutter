/// Dart port of Feed.java.
///
/// One logical CCTV feed. Either a single stream (HLS / MJPEG / WEB) or a
/// COLLECTION whose child cameras are resolved at tap-time via declarative
/// extraction rules in [extraction].
library;

enum FeedType {
  auto,
  hls,
  web,
  mjpeg,
  collection;

  static FeedType fromString(String? s) {
    if (s == null) return FeedType.web;
    switch (s.trim().toUpperCase()) {
      case 'HLS':
        return FeedType.hls;
      case 'MJPEG':
        return FeedType.mjpeg;
      case 'COLLECTION':
        return FeedType.collection;
      case 'AUTO':
        return FeedType.auto;
      default:
        return FeedType.web;
    }
  }

  /// Short label shown on the tile chip. Mirrors Feed.java#chipLabel().
  String get chipLabel {
    switch (this) {
      case FeedType.collection:
        return 'SET';
      case FeedType.hls:
        return 'HLS';
      case FeedType.mjpeg:
        return 'MJPEG';
      case FeedType.web:
        return 'WEB';
      case FeedType.auto:
        return 'AUTO';
    }
  }
}

class Feed {
  final String id;
  final String name;
  final String? city;
  final FeedType type;
  final String url;
  final String? sourceUrl;
  final bool userAdded;
  final String? group;
  final String? lat;
  final String? lng;
  final String? providerId;

  /// Declarative extraction rules for COLLECTION feeds (passed through to
  /// ConfigProvider at resolve time). We keep the raw JSON map so the
  /// engine can port 1:1 from the Java side.
  final Map<String, dynamic>? extraction;

  const Feed({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    this.city,
    this.sourceUrl,
    this.userAdded = false,
    this.group,
    this.lat,
    this.lng,
    this.providerId,
    this.extraction,
  });

  bool get hasCoords =>
      (lat ?? '').isNotEmpty && (lng ?? '').isNotEmpty;

  factory Feed.fromJson(Map<String, dynamic> o, {bool userAdded = false}) {
    return Feed(
      id: o['id']?.toString() ?? '',
      name: o['name']?.toString() ?? '',
      city: o['city']?.toString(),
      type: FeedType.fromString(o['type']?.toString()),
      url: o['url']?.toString() ?? '',
      sourceUrl: o['sourceUrl']?.toString(),
      userAdded: userAdded,
      group: o['group']?.toString(),
      lat: o['lat']?.toString(),
      lng: o['lng']?.toString(),
      providerId: o['providerId']?.toString(),
      extraction: o['extraction'] is Map<String, dynamic>
          ? o['extraction'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (city != null) 'city': city,
        'type': type.name.toUpperCase(),
        'url': url,
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
        if (group != null) 'group': group,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (providerId != null) 'providerId': providerId,
        if (extraction != null) 'extraction': extraction,
      };
}
