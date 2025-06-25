/// 지출 보고서 작성 화면
/// 사용자가 새로운 지출 보고서 게시물을 작성할 수 있도록 합니다.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'expense_report_screen.dart';
import 'expense_report_detail_screen.dart';
import 'transaction_provider.dart';
import 'transaction.dart';

class ExpenseReportWriteScreen extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? postData;

  const ExpenseReportWriteScreen({
    Key? key,
    this.isEditing = false,
    this.postData,
  }) : super(key: key);

  @override
  State<ExpenseReportWriteScreen> createState() => _ExpenseReportWriteScreenState();
}

class _ExpenseReportWriteScreenState extends State<ExpenseReportWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  
  bool _isUploading = false;
  bool _formChanged = false; // 폼 변경 여부
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _userName = '부린이님';
  Map<String, dynamic>? _reportData; // 소비 리포트 데이터 저장용 변수
  
  // 실제 거래 내역이 있는 월 목록
  List<DateTime> _monthsWithTransactions = [];
  
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
            .doc(_currentUser!.uid)
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
      print('사용자 정보 로드 중 오류 발생: $e');
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
        _currentUser!, 
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
      print('소비 리포트 처리 중 오류: $e');
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
  
  // 월 선택 다이얼로그
  Future<DateTime?> _showMonthPickerDialog() async {
    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '소비 리포트 월 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _monthsWithTransactions.map((month) {
                    return ListTile(
                      title: Text(
                        '${month.year}년 ${month.month}월',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.pop(context, month);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('취소'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 리포트 글 업로드
  Future<void> _uploadReport() async {
    // 제목이나 내용이 비어있는지 확인
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목과 내용을 모두 입력해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // 소비 리포트가 첨부되지 않았다면 사용자에게 확인
    if (_reportData == null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('소비 리포트 미첨부'),
          content: const Text('소비 리포트가 첨부되지 않았습니다. 계속 진행하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('계속 진행'),
            ),
          ],
        ),
      );
      
      if (confirm != true) {
        return;
      }
    }
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      if (_currentUser != null) {
        // 현재 월 정보 가져오기
        String currentMonth = DateFormat('M').format(DateTime.now());
        
        // 문서 ID를 위한 랜덤 숫자 생성
        final random = DateTime.now().millisecondsSinceEpoch;
        
        // 게시글 데이터 준비
        final postData = {
          'Heading': _titleController.text.trim(),
          'Content': _contentController.text.trim(),
          'userId': _currentUser!.uid,
          'author_name': _userName,
          'Month': _reportData?['month_text']?.replaceAll('월', '') ?? DateFormat('M').format(DateTime.now()), // 리포트 데이터의 월 또는 현재 월
          'writeNumber': random.toString(),
          'report_data': _reportData, // 불러온 리포트 데이터 첨부
          'created_at': Timestamp.now(),
        };
        
        // Firestore의 community 컬렉션에 데이터 저장
        final docRef = await FirebaseFirestore.instance.collection('community').add(postData);
        
        // 저장된 문서 ID 가져오기
        final savedDoc = await docRef.get();
        final savedData = savedDoc.data() ?? {};
        savedData['id'] = docRef.id;
        
        // 업로드 후 상세 화면으로 이동
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseReportDetailScreen(
                postData: savedData,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('리포트 업로드 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리포트 업로드 중 오류가 발생했습니다'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // 폼 상태 업데이트
  void _updateFormState() {
    setState(() {
      _formChanged = true;
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
    String currentMonthDisplay = DateFormat('M월').format(DateTime.now()); // UI 표시용
    
    // 제목과 내용이 비어있는지 확인하는 변수
    bool isFormValid = _titleController.text.trim().isNotEmpty && 
                       _contentController.text.trim().isNotEmpty;
                       
    // 작성하기 버튼 활성화 조건 - 제목과 내용은 필수, 소비 리포트는 필수 아님
    bool canSubmit = isFormValid;
    
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