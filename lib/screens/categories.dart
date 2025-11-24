/// 가계부 카테고리 상수 정의 (공통 사용)
/// 이제 동적 카테고리 시스템을 사용합니다.

import 'category_manager.dart';

// 수입 카테고리 (기본값, 동적 로드 시 대체됨)
const List<String> defaultIncomeCategories = [
  '급여',
  '사업수입',
  '용돈',
  '판매',
];

// 지출 카테고리 (기본값, 동적 로드 시 대체됨)
const List<String> defaultExpenseCategories = [
  '식비',
  '카페',
  '간식',
  '생활',
  '쇼핑',
  '뷰티',
  '교통',
  '통신',
  '문화',
  '교육',
  '만남',
  '목표 저축',
  '저축',
];

// 전체(수입+지출) 카테고리 (기본값, 동적 로드 시 대체됨)
const List<String> defaultAllCategories = [
  ...defaultIncomeCategories,
  ...defaultExpenseCategories,
];

// 동적 카테고리 로드 함수들
Future<List<String>> getIncomeCategories() async {
  try {
    return await CategoryManager.getIncomeCategories();
  } catch (e) {
    print('수입 카테고리 로드 실패, 기본값 사용: $e');
    return defaultIncomeCategories;
  }
}

Future<List<String>> getExpenseCategories() async {
  try {
    return await CategoryManager.getExpenseCategories();
  } catch (e) {
    print('지출 카테고리 로드 실패, 기본값 사용: $e');
    return defaultExpenseCategories;
  }
}

Future<List<String>> getAllCategories() async {
  try {
    return await CategoryManager.getAllCategories();
  } catch (e) {
    print('전체 카테고리 로드 실패, 기본값 사용: $e');
    return defaultAllCategories;
  }
}

// 하위 호환성을 위한 상수 (deprecated)
@deprecated
const List<String> incomeCategories = defaultIncomeCategories;

@deprecated
const List<String> expenseCategories = defaultExpenseCategories;

@deprecated
const List<String> allCategories = defaultAllCategories;
