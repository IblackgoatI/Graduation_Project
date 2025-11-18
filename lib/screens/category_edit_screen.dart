/// 카테고리 편집 화면
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import 'category_manager.dart';

class CategoryEditScreen extends StatefulWidget {
  final String type; // '수입' 또는 '지출'

  const CategoryEditScreen({
    super.key,
    required this.type,
  });

  @override
  State<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _categoryService.getCategoriesByType(widget.type);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('카테고리 로드 실패, 기본 카테고리 사용: $e');
      // 인덱스 문제로 실패한 경우 기본 카테고리 사용
      _loadDefaultCategories();
    }
  }

  void _loadDefaultCategories() {
    List<CategoryModel> defaultCategories = [];
    
    if (widget.type == '수입') {
      defaultCategories = [
        CategoryModel(
          id: 'default_1',
          name: '급여',
          icon: '💰',
          type: '수입',
          order: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_2',
          name: '사업수입',
          icon: '💼',
          type: '수입',
          order: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_3',
          name: '용돈',
          icon: '🎁',
          type: '수입',
          order: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_4',
          name: '판매',
          icon: '🛒',
          type: '수입',
          order: 4,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
      ];
    } else {
      defaultCategories = [
        CategoryModel(
          id: 'default_5',
          name: '식비',
          icon: '🍽️',
          type: '지출',
          order: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_6',
          name: '카페',
          icon: '☕',
          type: '지출',
          order: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_7',
          name: '간식',
          icon: '🍿',
          type: '지출',
          order: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_8',
          name: '생활',
          icon: '🏠',
          type: '지출',
          order: 4,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_9',
          name: '쇼핑',
          icon: '🛍️',
          type: '지출',
          order: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_10',
          name: '뷰티',
          icon: '💄',
          type: '지출',
          order: 6,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_11',
          name: '교통',
          icon: '🚗',
          type: '지출',
          order: 7,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_12',
          name: '통신',
          icon: '📱',
          type: '지출',
          order: 8,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_13',
          name: '문화',
          icon: '🎬',
          type: '지출',
          order: 9,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_14',
          name: '교육',
          icon: '📚',
          type: '지출',
          order: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_15',
          name: '만남',
          icon: '👥',
          type: '지출',
          order: 11,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
        CategoryModel(
          id: 'default_16',
          name: '저축',
          icon: '💰',
          type: '지출',
          order: 12,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'default',
        ),
      ];
    }

    setState(() {
      _categories = defaultCategories;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // 뒤로가기 시 카테고리 선택 화면으로 돌아가기
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.type} 카테고리 편집'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddCategoryDialog,
              tooltip: '새 카테고리 추가',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showDebugInfo();
          },
          child: const Icon(Icons.info),
          mini: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
                ? _buildEmptyState()
                : _buildCategoryList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 카테고리가 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 새 카테고리를 추가해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryItem(category, index);
      },
    );
  }

  Widget _buildCategoryItem(CategoryModel category, int index) {
    return Card(
      key: ValueKey(category.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          category.icon,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditCategoryDialog(category),
              tooltip: '수정',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _showDeleteConfirmDialog(category),
              tooltip: '삭제',
            ),
            Icon(
              Icons.drag_handle,
              color: Colors.grey[400],
            ),
          ],
        ),
        onTap: () => _showEditCategoryDialog(category),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });

    // 순서 변경을 서버에 저장
    _categoryService.reorderCategories(_categories).then((success) {
      if (success) {
        // 캐시 초기화
        CategoryManager.clearCache();
      }
    });
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog();
  }

  void _showEditCategoryDialog(CategoryModel category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({CategoryModel? category}) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedIcon = category?.icon ?? '📁';
    String selectedType = category?.type ?? widget.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(isEdit ? '카테고리 수정' : '새 카테고리 추가'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // 아이콘 선택
                Text(
                  '아이콘 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 1,
                    ),
                    itemCount: _getAvailableIcons().length,
                    itemBuilder: (context, index) {
                      final icon = _getAvailableIcons()[index];
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedIcon = icon;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: selectedIcon == icon
                                ? Colors.blue[100]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedIcon == icon
                                  ? Colors.blue
                                  : Colors.grey[300] ?? Colors.grey,
                              width: selectedIcon == icon ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // 카테고리 타입 선택 (새 카테고리일 때만)
                if (!isEdit) ...[
                  Text(
                    '카테고리 타입',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () { setDialogState(() { selectedType = '수입'; }); },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(
                                value: '수입',
                                groupValue: selectedType,
                                onChanged: (value) { setDialogState(() { selectedType = value!; }); },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 4),
                              const Text('수입', maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () { setDialogState(() { selectedType = '지출'; }); },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(
                                value: '지출',
                                groupValue: selectedType,
                                onChanged: (value) { setDialogState(() { selectedType = value!; }); },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 4),
                              const Text('지출', maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // 카테고리 이름 입력
                Text(
                  '카테고리 이름',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: '카테고리 이름을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 20,
                ),
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  _showErrorSnackBar('카테고리 이름을 입력해주세요.');
                  return;
                }

                Navigator.pop(context);

                if (isEdit) {
                  await _updateCategory(
                    category.copyWith(
                      name: nameController.text.trim(),
                      icon: selectedIcon,
                    ),
                  );
                } else {
                  await _addCategory(
                    nameController.text.trim(),
                    selectedIcon,
                    selectedType,
                  );
                }
              },
              child: Text(isEdit ? '수정' : '추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text(
          "'${category.name}' 카테고리를 삭제하시겠습니까?\n\n"
          "이 카테고리를 사용하는 모든 거래 내역은 '미분류'로 변경됩니다.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCategory(category);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory(String name, String icon, String type) async {
    try {
      print('카테고리 추가 시도: $name, $icon, $type');
      
      final newCategory = CategoryModel(
        id: '', // 서비스에서 생성됨
        name: name,
        icon: icon,
        type: type,
        order: 0, // 서비스에서 설정됨
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: '', // 서비스에서 설정됨
      );

      print('새 카테고리 모델 생성 완료');
      
      final categoryId = await _categoryService.addCategory(newCategory);
      print('카테고리 추가 결과: $categoryId');
      
      if (categoryId != null) {
        print('카테고리 추가 성공, 목록 새로고침 시작');
        // 캐시 초기화
        CategoryManager.clearCache();
        await _loadCategories();
        _showSuccessSnackBar('카테고리가 추가되었습니다.');
        print('카테고리 추가 완료');
      } else {
        print('카테고리 추가 실패: categoryId가 null');
        _showErrorSnackBar('카테고리 추가에 실패했습니다.');
      }
    } catch (e) {
      print('카테고리 추가 중 오류: $e');
      _showErrorSnackBar('카테고리 추가 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _updateCategory(CategoryModel category) async {
    try {
      final success = await _categoryService.updateCategory(category);
      if (success) {
        // 캐시 초기화
        CategoryManager.clearCache();
        _loadCategories();
        _showSuccessSnackBar('카테고리가 수정되었습니다.');
      } else {
        _showErrorSnackBar('카테고리 수정에 실패했습니다.');
      }
    } catch (e) {
      _showErrorSnackBar('카테고리 수정 중 오류가 발생했습니다.');
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    try {
      final success = await _categoryService.deleteCategory(category.id);
      if (success) {
        // 캐시 초기화
        CategoryManager.clearCache();
        _loadCategories();
        _showSuccessSnackBar('카테고리가 삭제되었습니다.');
      } else {
        _showErrorSnackBar('카테고리 삭제에 실패했습니다.');
      }
    } catch (e) {
      _showErrorSnackBar('카테고리 삭제 중 오류가 발생했습니다.');
    }
  }

  List<String> _getAvailableIcons() {
    return [
      '📁', '💰', '💼', '🎁', '🛒', '🍽️', '☕', '🍿', '🏠', '🛍️',
      '💄', '🚗', '📱', '🎬', '📚', '👥', '🏥', '💊', '🎮', '🏃',
      '✈️', '🏨', '🍕', '🍔', '🍜', '🍰', '🍺', '☕', '🥤', '🍎',
      '👕', '👖', '👟', '💍', '⌚', '📷', '💻', '📺', '🔌', '🔋',
      '🎵', '🎨', '📝', '✏️', '📖', '🎯', '🎪', '🎭', '🎨', '🎪'
    ];
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디버그 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('카테고리 타입: ${widget.type}'),
            Text('로드된 카테고리 수: ${_categories.length}'),
            Text('카테고리 목록: ${_categories.map((c) => c.name).join(', ')}'),
            const SizedBox(height: 8),
            const Text('캐시 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('캐시된 카테고리 수: ${CategoryManager.cachedCategoriesCount}'),
            Text('초기화 상태: ${CategoryManager.isInitialized}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              CategoryManager.clearCache();
              _loadCategories();
            },
            child: const Text('캐시 초기화 & 새로고침'),
          ),
        ],
      ),
    );
  }
}
