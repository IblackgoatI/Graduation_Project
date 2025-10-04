/// 카테고리 관리자 - 기존 하드코딩된 카테고리를 동적 시스템으로 마이그레이션
import '../services/category_service.dart';
import '../models/category_model.dart';

class CategoryManager {
  static final CategoryService _categoryService = CategoryService();
  static List<CategoryModel> _cachedCategories = [];
  static bool _isInitialized = false;

  // 카테고리 초기화 (앱 시작 시 호출)
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 기본 카테고리 초기화
      await _categoryService.initializeDefaultCategories();
      _isInitialized = true;
    } catch (e) {
      print('카테고리 초기화 오류: $e');
    }
  }

  // 수입 카테고리 목록 가져오기
  static Future<List<String>> getIncomeCategories() async {
    try {
      await _loadCategoriesIfNeeded();
      return _cachedCategories
          .where((category) => category.type == '수입')
          .map((category) => category.name)
          .toList();
    } catch (e) {
      print('수입 카테고리 로드 실패: $e');
      return ['급여', '사업수입', '용돈', '판매']; // 기본값 반환
    }
  }

  // 지출 카테고리 목록 가져오기
  static Future<List<String>> getExpenseCategories() async {
    try {
      await _loadCategoriesIfNeeded();
      return _cachedCategories
          .where((category) => category.type == '지출')
          .map((category) => category.name)
          .toList();
    } catch (e) {
      print('지출 카테고리 로드 실패: $e');
      return ['식비', '카페', '간식', '생활', '쇼핑', '뷰티', '교통', '통신', '문화', '교육', '만남']; // 기본값 반환
    }
  }

  // 전체 카테고리 목록 가져오기
  static Future<List<String>> getAllCategories() async {
    try {
      await _loadCategoriesIfNeeded();
      return _cachedCategories.map((category) => category.name).toList();
    } catch (e) {
      print('전체 카테고리 로드 실패: $e');
      return ['급여', '사업수입', '용돈', '판매', '식비', '카페', '간식', '생활', '쇼핑', '뷰티', '교통', '통신', '문화', '교육', '만남']; // 기본값 반환
    }
  }

  // 카테고리 새로고침
  static Future<void> refreshCategories() async {
    try {
      _cachedCategories = await _categoryService.getUserCategories();
    } catch (e) {
      print('카테고리 새로고침 오류: $e');
    }
  }

  // 카테고리 캐시 초기화
  static void clearCache() {
    _cachedCategories.clear();
    _isInitialized = false;
  }

  // 캐시 상태 확인
  static int get cachedCategoriesCount => _cachedCategories.length;
  static bool get isInitialized => _isInitialized;

  // 카테고리 목록이 필요할 때만 로드
  static Future<void> _loadCategoriesIfNeeded() async {
    if (_cachedCategories.isEmpty) {
      await refreshCategories();
    }
  }

  // 카테고리 아이콘 가져오기
  static Future<String> getCategoryIcon(String categoryName) async {
    await _loadCategoriesIfNeeded();
    final category = _cachedCategories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => CategoryModel(
        id: '',
        name: categoryName,
        icon: '📁',
        type: '지출',
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: '',
      ),
    );
    return category.icon;
  }

  // 카테고리 타입 가져오기
  static Future<String> getCategoryType(String categoryName) async {
    await _loadCategoriesIfNeeded();
    final category = _cachedCategories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => CategoryModel(
        id: '',
        name: categoryName,
        icon: '📁',
        type: '지출',
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: '',
      ),
    );
    return category.type;
  }
}
