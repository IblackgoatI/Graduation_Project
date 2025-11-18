/// 카테고리 관리 서비스
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 사용자의 카테고리 목록 가져오기
  Future<List<CategoryModel>> getUserCategories() async {
    try {
      final user = _auth.currentUser;
      String userId = user?.uid ?? 'anonymous';

      // 인덱스 문제를 피하기 위해 단순 쿼리 사용
      QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .get();

      // 클라이언트에서 정렬
      List<CategoryModel> categories = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      categories.sort((a, b) => a.order.compareTo(b.order));

      return categories;
    } catch (e) {
      print('카테고리 로드 오류: $e');
      return [];
    }
  }

  // 특정 타입의 카테고리만 가져오기
  Future<List<CategoryModel>> getCategoriesByType(String type) async {
    try {
      final user = _auth.currentUser;
      String userId = user?.uid ?? 'anonymous';

      // 인덱스 문제를 피하기 위해 단순 쿼리 사용
      QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .get();

      // 클라이언트에서 타입 필터링
      List<CategoryModel> allCategories = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // 타입별로 필터링하고 정렬
      List<CategoryModel> filteredCategories = allCategories
          .where((category) => category.type == type)
          .toList();
      
      filteredCategories.sort((a, b) => a.order.compareTo(b.order));

      return filteredCategories;
    } catch (e) {
      print('카테고리 로드 오류: $e');
      return [];
    }
  }

  // 새 카테고리 추가
  Future<String?> addCategory(CategoryModel category) async {
    try {
      print('CategoryService.addCategory 시작');
      
      final user = _auth.currentUser;
      print('현재 사용자: ${user?.uid}');
      
      // 사용자가 로그인하지 않은 경우 익명 사용자로 처리
      String userId = user?.uid ?? 'anonymous';
      print('사용자 ID: $userId');

      // 현재 사용자의 카테고리 개수 확인하여 order 설정
      print('기존 카테고리 조회 중...');
      QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .get();

      // 클라이언트에서 타입별 필터링
      List<Map<String, dynamic>> typeCategories = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((data) => data['type'] == category.type)
          .toList();

      print('기존 카테고리 개수: ${typeCategories.length}');

      int maxOrder = 0;
      for (var data in typeCategories) {
        int order = data['order'] ?? 0;
        if (order > maxOrder) maxOrder = order;
      }

      print('새 카테고리 order: ${maxOrder + 1}');

      CategoryModel newCategory = category.copyWith(
        userId: userId,
        order: maxOrder + 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('Firestore에 카테고리 저장 중...');
      DocumentReference docRef = await _firestore
          .collection('categories')
          .add(newCategory.toMap());

      print('카테고리 저장 완료, ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('카테고리 추가 오류: $e');
      return null;
    }
  }

  // 카테고리 수정
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(category.copyWith(updatedAt: DateTime.now()).toMap());

      return true;
    } catch (e) {
      print('카테고리 수정 오류: $e');
      return false;
    }
  }

  // 카테고리 삭제
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _firestore
          .collection('categories')
          .doc(categoryId)
          .delete();

      return true;
    } catch (e) {
      print('카테고리 삭제 오류: $e');
      return false;
    }
  }

  // 카테고리 순서 변경
  Future<bool> reorderCategories(List<CategoryModel> categories) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (int i = 0; i < categories.length; i++) {
        batch.update(
          _firestore.collection('categories').doc(categories[i].id),
          {
            'order': i + 1,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          },
        );
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('카테고리 순서 변경 오류: $e');
      return false;
    }
  }

  // 기본 카테고리 초기화 (첫 사용자용)
  Future<bool> initializeDefaultCategories() async {
    try {
      final user = _auth.currentUser;
      String userId = user?.uid ?? 'anonymous';

      // 기존 카테고리가 있는지 확인
      QuerySnapshot existing = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .get();

      if (existing.docs.isNotEmpty) return true; // 이미 초기화됨

      // 기본 카테고리 데이터
      List<Map<String, dynamic>> defaultCategories = [
        // 수입 카테고리
        {'name': '급여', 'icon': '💰', 'type': '수입', 'order': 1},
        {'name': '사업수입', 'icon': '💼', 'type': '수입', 'order': 2},
        {'name': '용돈', 'icon': '🎁', 'type': '수입', 'order': 3},
        {'name': '판매', 'icon': '🛒', 'type': '수입', 'order': 4},
        
        // 지출 카테고리
        {'name': '식비', 'icon': '🍽️', 'type': '지출', 'order': 1},
        {'name': '카페', 'icon': '☕', 'type': '지출', 'order': 2},
        {'name': '간식', 'icon': '🍿', 'type': '지출', 'order': 3},
        {'name': '생활', 'icon': '🏠', 'type': '지출', 'order': 4},
        {'name': '쇼핑', 'icon': '🛍️', 'type': '지출', 'order': 5},
        {'name': '뷰티', 'icon': '💄', 'type': '지출', 'order': 6},
        {'name': '교통', 'icon': '🚗', 'type': '지출', 'order': 7},
        {'name': '통신', 'icon': '📱', 'type': '지출', 'order': 8},
        {'name': '문화', 'icon': '🎬', 'type': '지출', 'order': 9},
        {'name': '교육', 'icon': '📚', 'type': '지출', 'order': 10},
        {'name': '만남', 'icon': '👥', 'type': '지출', 'order': 11},
        {'name': '목표', 'icon': '🎯', 'type': '지출', 'order': 12},
        {'name': '저축', 'icon': '💰', 'type': '지출', 'order': 13},
      ];

      WriteBatch batch = _firestore.batch();
      DateTime now = DateTime.now();

      for (var categoryData in defaultCategories) {
        DocumentReference docRef = _firestore.collection('categories').doc();
        batch.set(docRef, {
          ...categoryData,
          'userId': userId,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('기본 카테고리 초기화 오류: $e');
      return false;
    }
  }
}
