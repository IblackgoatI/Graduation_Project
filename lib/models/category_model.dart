// Firestore Timestamp import
import 'package:cloud_firestore/cloud_firestore.dart';

/// 카테고리 데이터 모델
class CategoryModel {
  final String id;
  final String name;
  final String icon; // 이모지나 아이콘 코드
  final String type; // '수입' 또는 '지출'
  final int order; // 정렬 순서
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId; // 사용자별 카테고리 관리

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  // Firestore에서 데이터를 가져올 때 사용
  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      icon: map['icon'] ?? '📁',
      type: map['type'] ?? '지출',
      order: map['order'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: map['userId'] ?? '',
    );
  }

  // Firestore에 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'type': type,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }

  // 카테고리 복사본 생성 (수정 시 사용)
  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? type,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
}
