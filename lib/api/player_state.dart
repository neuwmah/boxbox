/// Persisted player state (local cache + API payload).
class PlayerState {
  const PlayerState({
    required this.playerId,
    required this.currentLevel,
    required this.coins,
    required this.hearts,
    required this.noAds,
    required this.updatedAt,
  });

  final String playerId;
  final int currentLevel;
  final int coins;
  final int hearts;
  final bool noAds;

  /// Unix UTC seconds of the last local change (last-write-wins).
  final int updatedAt;

  PlayerState copyWith({
    String? playerId,
    int? currentLevel,
    int? coins,
    int? hearts,
    bool? noAds,
    int? updatedAt,
  }) {
    return PlayerState(
      playerId: playerId ?? this.playerId,
      currentLevel: currentLevel ?? this.currentLevel,
      coins: coins ?? this.coins,
      hearts: hearts ?? this.hearts,
      noAds: noAds ?? this.noAds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'current_level': currentLevel,
        'coins': coins,
        'hearts': hearts,
        'no_ads': noAds,
        'updated_at': updatedAt,
      };

  static PlayerState? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['player_id']?.toString();
    if (id == null || id.isEmpty) return null;
    return PlayerState(
      playerId: id,
      currentLevel: _asInt(json['current_level'], 1),
      coins: _asInt(json['coins'], 0),
      hearts: _asInt(json['hearts'], 5),
      noAds: json['no_ads'] == true || json['no_ads'] == 1,
      updatedAt: _asInt(json['updated_at'] ?? json['updatedAt'], 0),
    );
  }

  static int _asInt(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
