import '../models/recipe.dart';

enum ThemePreference {
  system,
  light,
  dark;

  String get label => switch (this) {
    ThemePreference.system => 'System',
    ThemePreference.light => 'Light',
    ThemePreference.dark => 'Dark',
  };
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.provider,
    required this.diets,
    required this.allergies,
    required this.goal,
    required this.familySize,
    required this.notifications,
    this.uid = '',
    this.photoUrl,
    this.createdAt,
    this.lastLoginAt,
  });

  /// Firebase UID — the owner key for every piece of per-user data.
  /// Empty for guests and offline demo sessions.
  final String uid;
  final String name;
  final String email;
  final String provider;
  final List<DietTag> diets;
  final List<String> allergies;
  final String goal;
  final int familySize;
  final bool notifications;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  bool get isGuest => uid.isEmpty && provider == 'guest';

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? provider,
    List<DietTag>? diets,
    List<String>? allergies,
    String? goal,
    int? familySize,
    bool? notifications,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      provider: provider ?? this.provider,
      diets: diets ?? this.diets,
      allergies: allergies ?? this.allergies,
      goal: goal ?? this.goal,
      familySize: familySize ?? this.familySize,
      notifications: notifications ?? this.notifications,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Map<String, Object?> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'provider': provider,
    'diets': diets.map((d) => d.name).toList(growable: false),
    'allergies': allergies,
    'goal': goal,
    'familySize': familySize,
    'notifications': notifications,
    'photoUrl': photoUrl,
    'createdAt': createdAt?.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, Object?> json) {
    final dietNames = json['diets'] as List<Object?>? ?? const [];
    final diets = DietTag.values
        .where((d) => dietNames.contains(d.name))
        .toList(growable: false);
    return UserProfile(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? 'Guest chef',
      email: json['email'] as String? ?? '',
      provider: json['provider'] as String? ?? 'email',
      diets: diets,
      allergies: [
        for (final a in json['allergies'] as List<Object?>? ?? const [])
          a.toString(),
      ],
      goal: json['goal'] as String? ?? 'Balanced plates',
      familySize: (json['familySize'] as num?)?.toInt() ?? 2,
      notifications: json['notifications'] as bool? ?? true,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      lastLoginAt: DateTime.tryParse(json['lastLoginAt'] as String? ?? ''),
    );
  }

  static const UserProfile guest = UserProfile(
    name: 'Guest chef',
    email: '',
    provider: 'guest',
    diets: [],
    allergies: [],
    goal: 'Balanced plates',
    familySize: 2,
    notifications: true,
  );
}

class RecipeCollection {
  const RecipeCollection({
    required this.id,
    required this.name,
    required this.recipeIds,
  });

  final String id;
  final String name;
  final List<String> recipeIds;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'recipeIds': recipeIds,
  };

  factory RecipeCollection.fromJson(Map<String, Object?> json) =>
      RecipeCollection(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        recipeIds: [
          for (final id in json['recipeIds'] as List<Object?>? ?? const [])
            id.toString(),
        ],
      );
}

class PantryItem {
  const PantryItem({
    required this.name,
    required this.addedAt,
    this.timesSeen = 1,
  });

  final String name;
  final DateTime addedAt;
  final int timesSeen;

  Map<String, Object?> toJson() => {
    'name': name,
    'addedAt': addedAt.toIso8601String(),
    'timesSeen': timesSeen,
  };

  factory PantryItem.fromJson(Map<String, Object?> json) => PantryItem(
    name: json['name'] as String? ?? '',
    addedAt:
        DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
    timesSeen: (json['timesSeen'] as num?)?.toInt() ?? 1,
  );
}

class ScanRecord {
  const ScanRecord({
    required this.id,
    required this.at,
    required this.ingredients,
    this.imageCount = 0,
  });

  final String id;
  final DateTime at;
  final List<String> ingredients;
  final int imageCount;

  Map<String, Object?> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'ingredients': ingredients,
    'imageCount': imageCount,
  };

  factory ScanRecord.fromJson(Map<String, Object?> json) => ScanRecord(
    id: json['id'] as String? ?? '',
    at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    ingredients: [
      for (final i in json['ingredients'] as List<Object?>? ?? const [])
        i.toString(),
    ],
    imageCount: (json['imageCount'] as num?)?.toInt() ?? 0,
  );
}
