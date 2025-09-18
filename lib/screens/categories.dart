/// 가계부 카테고리 상수 정의 (공통 사용)

// 수입 카테고리
const List<String> incomeCategories = [
  '급여',
  '사업수입',
  '용돈',
  '판매',
];

// 지출 카테고리
const List<String> expenseCategories = [
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
];

// 전체(수입+지출) 카테고리
const List<String> allCategories = [
  ...incomeCategories,
  ...expenseCategories,
];


