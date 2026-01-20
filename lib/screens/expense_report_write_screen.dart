/// 지출 보고서 작성 화면
/// 사용자가 새로운 지출 보고서 게시물을 작성할 수 있도록 합니다.
library;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'expense_report_screen.dart';
import 'transaction_provider.dart';

class ExpenseReportWriteScreen extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? postData;

  const ExpenseReportWriteScreen({
    super.key,
    this.isEditing = false,
    this.postData,
  });

  @override
  State<ExpenseReportWriteScreen> createState() => _ExpenseReportWriteScreenState();
}

class _ExpenseReportWriteScreenState extends State<ExpenseReportWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  
  bool _isUploading = false;

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _userName = '부린이님';
  Map<String, dynamic>? _reportData; // 소비 리포트 데이터 저장용 변수
  
  // 실제 거래 내역이 있는 월 목록
  final List<DateTime> _monthsWithTransactions = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    
    // 텍스트 필드 리스너 추가
    _titleController.addListener(_updateFormState);
    _contentController.addListener(_updateFormState);
    
    // 수정 모드인 경우 기존 데이터로 초기화
    if (widget.isEditing && widget.postData != null) {
      _titleController.text = widget.postData!['Heading'] ?? '';
      _contentController.text = widget.postData!['Content'] ?? '';
    }
    
    // UI 갱신 후 데이터가 있는 월 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMonthsWithTransactions();
    });
  }
  
  // 트랜잭션이 존재하는 월만 필터링
  void _checkMonthsWithTransactions() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final transactions = transactionProvider.transactions;
    
    // 거래 내역이 있는 월을 저장할 Set (중복 방지)
    Set<String> monthsWithData = {};
    
    // 각 거래 내역을 순회하며 지출이 있는 월 확인
    for (var transaction in transactions) {
      if (transaction.type == '지출') {
        String monthKey = '${transaction.date.year}-${transaction.date.month}';
        monthsWithData.add(monthKey);
      }
    }
    
    // _monthsWithTransactions 초기화
    _monthsWithTransactions.clear();
    
    // Set에 저장된 월 정보를 DateTime 객체로 변환하여 _monthsWithTransactions에 추가
    for (String monthKey in monthsWithData) {
      List<String> parts = monthKey.split('-');
      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      _monthsWithTransactions.add(DateTime(year, month, 1));
    }
    
    // 날짜 기준 내림차순 정렬 (최신 달이 위로)
    _monthsWithTransactions.sort((a, b) => b.compareTo(a));
    
    setState(() {});
    
    if (_monthsWithTransactions.isEmpty) {
      // 데이터가 없는 경우 안내 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('거래 내역이 있는 월이 없습니다. 가계부에 지출 내역을 먼저 추가해주세요.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _titleController.removeListener(_updateFormState);
    _contentController.removeListener(_updateFormState);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      if (_currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(_currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['Name'] != null) {
            setState(() {
              _userName = userData['Name'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('사용자 정보 로드 중 오류 발생: $e');
    }
  }
  
  // "불러오기" 버튼 클릭 시 ExpenseReportScreen의 로직을 실행하고 결과 받기
  Future<void> _fetchAndAttachReportData() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // 데이터가 있는 월이 없는 경우
    if (_monthsWithTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('거래 내역이 있는 월이 없습니다. 가계부에 지출 내역을 먼저 추가해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 월 선택 다이얼로그 표시
    final selectedMonth = await _showMonthPickerDialog();
    if (selectedMonth == null) return; // 사용자가 취소한 경우
    
    setState(() {
      _isUploading = true; // 로딩 시작
    });

    try {
      // 선택한 월로 소비 리포트 생성
      final result = await ExpenseReportScreen.generateAndSaveReportDataForCommunityPost(
        _currentUser,
        _userName,
        selectedMonth.month, // 선택한 월 전달
        selectedMonth.year,  // 선택한 년도 전달
      );

      if (result != null) {
        setState(() {
          _reportData = result; // 반환된 데이터 저장
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['month_text']} 소비 리포트가 첨부되었습니다.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1500),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('소비 리포트 생성 중 오류가 발생했습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('소비 리포트 처리 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('소비 리포트 처리 중 오류가 발생했습니다: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false; // 로딩 종료
      });
    }
  }
  
  // 월 선택 다이얼로그 (그래프 포함)
  Future<DateTime?> _showMonthPickerDialog() async {
    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '소비 리포트 월 선택',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _monthsWithTransactions.length,
                    itemBuilder: (context, index) {
                      final month = _monthsWithTransactions[index];
                      return _MonthItemWithGraph(
                        month: month,
                        currentUser: _currentUser!,
                        onTap: () {
                          Navigator.pop(context, month);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '취소',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 폼 상태 업데이트
  void _updateFormState() {
    setState(() {
    });
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final String currentMonthString = DateFormat('M').format(DateTime.now());

      final Map<String, dynamic> postData = {
        'Heading': _titleController.text.trim(),
        'Content': _contentController.text.trim(),
        'userId': currentUser.uid,
        'author_name': _userName, // _userName 사용 (initState에서 로드됨)
        'Month': _reportData?['month_text']?.replaceAll('월', '') ?? currentMonthString, // 리포트 데이터의 월 또는 현재 월
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(), 
      };

      if (_reportData != null) {
        // _reportData는 이미 {'categories': ..., 'total_expense': ..., 'month_text': ...} 형태
        postData['report_data'] = _reportData; 
        if (_reportData!['report_id'] != null) {
          postData['report_id'] = _reportData!['report_id']; // report_id 추가
        }
      }

      if (widget.isEditing) {
        // 게시글 수정
        // 수정 시에는 updated_at만 변경하는 것이 일반적
        postData['updated_at'] = Timestamp.now(); 
        // created_at은 기존 값 유지 또는 제거 후 서버에서 처리하도록 할 수 있음
        // 여기서는 기존 로직대로 updated_at만 갱신
        final Map<String, dynamic> updateData = Map.from(postData);
        updateData.remove('created_at'); // 수정 시 created_at은 변경하지 않음

        await FirebaseFirestore.instance
            .collection('community')
            .doc(widget.postData!['id'])
            .update(updateData);
      } else {
        // 새 게시글 작성
        await FirebaseFirestore.instance
            .collection('community')
            .add(postData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? '게시글이 수정되었습니다.' : '게시글이 작성되었습니다.'),
          ),
        );
        Navigator.pop(context, true); // 수정/작성 완료 표시
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // "불러오기" 버튼 UI
  Widget _buildImportButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.upload_outlined,
            size: 32,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 4),
          Text(
            '불러오기',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isEditing ? '게시글 수정' : '게시글 작성'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.isEditing ? '수정' : '작성',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 메인 콘텐츠
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 레이블
                    const Text(
                      '제목',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // 제목 입력 필드
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: '제목을 입력해주세요',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLength: 50, // 제목 최대 길이
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '제목을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 내용 레이블
                    const Text(
                      '내용',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // 내용 입력 필드
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: '내용을 입력해주세요',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLines: 10, // 여러 줄 입력 가능
                      maxLength: 500, // 내용 최대 길이
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '내용을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // 소비 리포트 불러오기 버튼
                    Center(
                      child: Column(
                        children: [
                          // 소비 리포트 상태 표시
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _reportData != null ? Colors.green.withAlpha(26) : Colors.grey.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _reportData != null ? Icons.check_circle : Icons.info_outline,
                                  size: 16,
                                  color: _reportData != null ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _reportData != null 
                                      ? '${_reportData!['month_text']} 소비 리포트가 첨부되었습니다' 
                                      : '소비 리포트를 첨부해주세요',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _reportData != null ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // 소비 리포트 불러오기 버튼
                          InkWell(
                            onTap: _isUploading ? null : _fetchAndAttachReportData,
                            child: _buildImportButton(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80), // 하단 버튼을 위한 여백
                  ],
                ),
              ),
            ),
          ),
          
          // 업로드 중 로딩 표시
          if (_isUploading)
            Container(
              color: Colors.black.withAlpha(77),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      // 하단 버튼 영역
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(51),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 취소 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 16),
            
            // 수정/작성 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BC34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(widget.isEditing ? '수정하기' : '작성하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 월 선택 아이템 (그래프 포함)
class _MonthItemWithGraph extends StatefulWidget {
  final DateTime month;
  final User currentUser;
  final VoidCallback onTap;

  const _MonthItemWithGraph({
    required this.month,
    required this.currentUser,
    required this.onTap,
  });

  @override
  State<_MonthItemWithGraph> createState() => _MonthItemWithGraphState();
}

class _MonthItemWithGraphState extends State<_MonthItemWithGraph> {
  Map<String, double>? _categoryExpenses;
  double? _totalExpense;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthData();
  }

  Future<void> _loadMonthData() async {
    try {
      final startDate = DateTime(widget.month.year, widget.month.month, 1);
      final endDate = DateTime(widget.month.year, widget.month.month + 1, 0);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('ledger')
          .where('userId', isEqualTo: widget.currentUser.uid)
          .where('type', isEqualTo: '지출')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double total = 0;
      Map<String, double> categories = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('amount') && data.containsKey('category')) {
          final amount = (data['amount'] as num).toDouble();
          final category = data['category'] as String;
          total += amount;
          categories.update(category, (value) => value + amount, ifAbsent: () => amount);
        }
      }

      if (mounted) {
        setState(() {
          _totalExpense = total;
          _categoryExpenses = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('월 데이터 로드 중 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatNumber(double number) {
    return NumberFormat('#,###').format(number.round());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 월 정보
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.month.year}년 ${widget.month.month}월',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_totalExpense != null)
                    Text(
                      '${_formatNumber(_totalExpense!)}원',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // 그래프 영역
              if (_isLoading)
                const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_categoryExpenses == null || _categoryExpenses!.isEmpty)
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '소비 내역이 없습니다',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      // 파이 차트
                      Expanded(
                        flex: 2,
                        child: _buildPieChart(),
                      ),
                      const SizedBox(width: 16),
                      // 카테고리 범례
                      Expanded(
                        flex: 3,
                        child: _buildCategoryLegend(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (_categoryExpenses == null || _totalExpense == null || _totalExpense == 0) {
      return const SizedBox.shrink();
    }

    final sortedCategories = _categoryExpenses!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Colors.red[300]!,
      Colors.pink[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.blue[300]!,
      Colors.amber[300]!,
      Colors.teal[300]!,
      Colors.indigo[300]!,
      Colors.lime[300]!,
      Colors.green[300]!,
      Colors.cyan[300]!,
      Colors.brown[300]!,
    ];

    return PieChart(
      PieChartData(
        sections: sortedCategories.take(5).map((entry) {
          final index = sortedCategories.indexOf(entry);
          final percent = (entry.value / _totalExpense!) * 100;
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value,
            title: percent > 5 ? '${percent.toStringAsFixed(0)}%' : '',
            radius: 35,
            titleStyle: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 20,
      ),
    );
  }

  Widget _buildCategoryLegend() {
    if (_categoryExpenses == null || _totalExpense == null || _totalExpense == 0) {
      return const SizedBox.shrink();
    }

    final sortedCategories = _categoryExpenses!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Colors.red[300]!,
      Colors.pink[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.blue[300]!,
      Colors.amber[300]!,
      Colors.teal[300]!,
      Colors.indigo[300]!,
      Colors.lime[300]!,
      Colors.green[300]!,
      Colors.cyan[300]!,
      Colors.brown[300]!,
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedCategories.take(4).map((entry) {
        final index = sortedCategories.indexOf(entry);
        final color = colors[index % colors.length];
        final percent = (entry.value / _totalExpense!) * 100;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}