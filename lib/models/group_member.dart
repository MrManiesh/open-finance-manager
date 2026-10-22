class GroupMember {
  final String id;
  final String name;
  final String email;
  final bool isOwner;
  final DateTime createdAt;

  GroupMember({
    required this.id,
    required this.name,
    required this.email,
    this.isOwner = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isOwner': isOwner ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'] as String,
      name: map['name'] as String,
      email: (map['email'] ?? '') as String,
      isOwner: (map['isOwner'] == 1 || map['isOwner'] == true),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'isOwner': isOwner,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      GroupMember.fromMap(json);

  GroupMember copyWith({
    String? id,
    String? name,
    String? email,
    bool? isOwner,
    DateTime? createdAt,
  }) {
    return GroupMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isOwner: isOwner ?? this.isOwner,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMember && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
