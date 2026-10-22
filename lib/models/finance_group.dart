import 'dart:convert';
import 'group_member.dart';

class FinanceGroup {
  final String id;
  final String name;
  final String description;
  final int iconCode;
  final int colorValue;
  final List<GroupMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;

  FinanceGroup({
    required this.id,
    required this.name,
    this.description = '',
    required this.iconCode,
    required this.colorValue,
    List<GroupMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : members = members ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'membersJson': jsonEncode(members.map((m) => m.toJson()).toList()),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FinanceGroup.fromMap(Map<String, dynamic> map) {
    List<GroupMember> parsedMembers = [];
    if (map['membersJson'] != null && (map['membersJson'] as String).isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(map['membersJson'] as String);
        parsedMembers = list.map((item) => GroupMember.fromJson(item as Map<String, dynamic>)).toList();
      } catch (_) {}
    } else if (map['members'] != null && map['members'] is List) {
      parsedMembers = (map['members'] as List)
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return FinanceGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      description: (map['description'] ?? '') as String,
      iconCode: map['iconCode'] as int,
      colorValue: map['colorValue'] as int,
      members: parsedMembers,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FinanceGroup.fromJson(Map<String, dynamic> json) =>
      FinanceGroup.fromMap(json);

  FinanceGroup copyWith({
    String? id,
    String? name,
    String? description,
    int? iconCode,
    int? colorValue,
    List<GroupMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinanceGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
